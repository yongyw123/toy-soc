`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.04.2023 15:37:33
// Design Name: 
// Module Name: core_video_test_pattern_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/**************************************************************
* V1_DISP_TEST_PATTERN
-----------------------
this core wraps the following modules: 
1. pixel_gen_colour_bar()
2. frame_counter();

Register Map
1. register 0 (offset 0): write register;
2. register 1 (offset 1): status register; 

Register Definition:
1. register 0: write register;
        bit[0]  start bit;
        HIGH to start this video core;

2. register 1: status register;
        bit[0] frame start? active high assertion;
        bit[1] frame end?   active high assertion;
        
Register IO access:
1. register 0: write and read;
2. register 1: read only;
******************************************************************/


`ifndef CORE_VIDEO_TEST_PATTERN_GEN_SV
`define CORE_VIDEO_TEST_PATTERN_GEN_SV

`include "IO_map.svh"

module core_video_lcd_test_pattern_gen
    #(parameter 
    LCD_WIDTH = 240,   
    LCD_HEIGHT = 320, 
        
    // pixel width;
    SRC_BITS_PER_PIXEL = 16,    // from the test pattern generator;
    SINK_BITS_PER_PIXEL = 8,     // LCD only accepts 8-bit in parallel at a time;
    
    // counter width from the frame counter
    COUNTER_WIDTH = 10  
    )
    (
        // general;
        input logic clk,
        input logic reset,  // async reset;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        /* for video downstream */       
        output logic [SINK_BITS_PER_PIXEL-1:0] stream_out_rgb, // 8-bit for the LCD;
        input logic sink_ready, // signal from the lcd fifo;
        output logic sink_valid // signal to the lcd fifo       
    );
    
    
    // constants;
    localparam REG_WR_OFFSET        = 1'b0;
    localparam REG_STATUS_OFFSET    = 1'b1;
    
    // signals;
    logic wr_en;   
    logic rd_en;
    
    logic rd_status_en;     // read for the frame counter status;
    logic rd_ctrl_en;       // read whether the pattern generator has been enabled;
    
    // registers;
    logic enable_gen_reg, enable_gen_next; // switch to turn on/off the pattern generator;
    
    /* interface for the test pattern generator */
    logic [SRC_BITS_PER_PIXEL-1:0] pattern_colour_bar_src;
    logic [COUNTER_WIDTH:0] pattern_xcoor;
    logic [COUNTER_WIDTH:0] pattern_ycoor;
    logic frame_start_;
    logic frame_end;
    
    /* interface for the downstream */
    logic [SINK_BITS_PER_PIXEL-1:0] pattern_colour_bar_sink;
    
    // ff;
   always_ff @(posedge clk, posedge reset)
        if(reset) begin
            enable_gen_reg <= 1'b0;   // default; disabled;
        end
        
        else begin
            if(wr_en)
                enable_gen_reg <= enable_gen_next;
        end
   
   // decode cpu instruction;
   // there is ony one write registerl and nothing else;
   // note that address decoding is not necessary;
    assign wr_en = (write && cs && (addr[0] == REG_WR_OFFSET));
    assign enable_gen_next = wr_data[0];
    
    // read multiplexing;
    assign rd_en = (read && cs);    
    always_comb begin
        // default;
        rd_data = 32'b0;
        case({rd_en, addr[0]})         
            {1'b1, REG_WR_OFFSET} :  
                rd_data = {31'b0, enable_gen_reg}; 
            {1'b1, REG_STATUS_OFFSET} :
                rd_data = {30'b0, frame_end, frame_start};
            default: ; // nop
        endcase
    end
    
    /*  instantiation; */
    
    // interface between the pattern generator and the downstream (lcd);
    frame_counter
    #(
        .LCD_WIDTH(LCD_WIDTH),
        .LCD_HEIGHT(LCD_HEIGHT),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .SRC_BITS_PER_PIXEL(SRC_BITS_PER_PIXEL),
        .SINK_BITS_PER_PIXEL(SINK_BITS_PER_PIXEL)
    )
    frame_counter_unit
    (
        .clk(clk),
        .reset(reset),
        .sync_clr(0),   // not used;
        
        // user command;
        .cmd_start(enable_gen_reg),
        
        // status
        .frame_start(frame_start),
        .frame_end(frame_end),  
        
        /* interface with the test pattern generator */
        .pixel_src(pattern_colour_bar_src),
        .xcoor(pattern_xcoor),
        .ycoor(pattern_ycoor),
        
        /* interface with the downstream cores */
        .sink_valid(sink_valid),
        .sink_ready(sink_ready),
        .pixel_sink(pattern_colour_bar_sink)        
    );
    
    // output;
    assign stream_out_rgb = pattern_colour_bar_sink;
    
    // test generator;
    pixel_gen_colour_bar
    #(
        .BITS_PER_PIXEL(SRC_BITS_PER_PIXEL),   
        .COUNTER_WIDTH(COUNTER_WIDTH)
    )
    pixel_gen_colour_bar_unit
    (
        .clk(clk),
        .reset(reset),
        
        .xcoor(pattern_xcoor),
        .ycoor(pattern_ycoor),
        
        .rgb565_out(pattern_colour_bar_src)
    );
    
    
endmodule

`endif // CORE_VIDEO_TEST_PATTERN_GEN_SV