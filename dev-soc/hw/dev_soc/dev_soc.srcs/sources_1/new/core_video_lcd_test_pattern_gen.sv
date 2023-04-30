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

Register Definition:
1. register 0: write register;
        bit[0]  start bit;
        HIGH to start this video core;
        
        
Register IO access:
1. register 0: write only;
******************************************************************/


`ifndef CORE_VIDEO_TEST_PATTERN_GEN_SV
`define CORE_VIDEO_TEST_PATTERN_GEN_SV

`include "IO_map.svh"

module core_video_test_pattern_gen
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
        
        /* from video upstream */
        input logic [SINK_BITS_PER_PIXEL-1:0] stream_in_rgb, 
        
        /* for video downstream */       
        output logic [SINK_BITS_PER_PIXEL-1:0] stream_out_rgb, // 8-bit for the LCD;
        input logic sink_ready, // signal from the lcd fifo;
        output logic sink_valid // signal to the lcd fifo
        
    );
    
    
    /* note;
    // there is only one register and no read register;
    // so this simplifies;
    */
    // signals;
    logic wr_en;   
    logic enable_generator;
    
    /* interface for the test pattern generator */
    logic [SRC_BITS_PER_PIXEL-1:0] pattern_colour_bar_src;
    logic [COUNTER_WIDTH:0] pattern_xcoor;
    logic [COUNTER_WIDTH:0] pattern_ycoor;
    
    /* interface for the downstream */
    logic [SINK_BITS_PER_PIXEL-1:0] pattern_colour_bar_sink;
    
    // ff;
   always_ff @(posedge clk, posedge reset)
        if(reset) begin
            enable_generator <= 1'b0;   // default; disabled;
        end
        
        else begin
            if(wr_en)
                enable_generator <= wr_data[0];
        end
   
   // decode cpu instruction;
   // there is ony one write registerl and nothing else;
    assign wr_en = write & cs;
    
    // instantiation;
    frame_counter
    #(
        .LCD_WIDTH(LCD_WIDTH),
        .LCD_HEIGHT(LCD_HEIGHT),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .SRC_BITS_PER_PIXEL(SRC_BITS_PER_PIXEL),
        .SINK_BITS_PER_PIXEL(SINK_BITS_PER_PIXEL)
    )
    (
        .clk(clk),
        .reset(reset),
        .sync_clr(0),   // not used;
        
        .cmd_start(enable_generator),
        
        .frame_start(), // not used;
        .frame_end(),   // not used;
        
        /* interface with the test pattern generator */
        .pixel_src(pattern_colour_bar_src),
        .xcoor(pattern_xcoor),
        .ycoor(pattern_ycoor),
        
        /* interface with the downstream cores */
        .sink_valid(sink_valid),
        .sink_ready(sink_ready),
        .pixel_sink(pattern_colour_bar_sink)        
    );
    
    
    
    
endmodule

`endif // CORE_VIDEO_TEST_PATTERN_GEN_SV