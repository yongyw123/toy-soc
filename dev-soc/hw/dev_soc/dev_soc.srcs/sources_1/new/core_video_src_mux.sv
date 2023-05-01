`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.04.2023 18:06:43
// Design Name: 
// Module Name: core_video_src_mux
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
* V2_DISP_SRC_MUX
-----------------------

purpose:
1. direct which pixel source to the LCD: test pattern generator(s) or from the camera?
2. allocate 6 pixel sources for future purposes;
3. in actuality; should be only between the test pattern generators and the camera;

important note:
1. all pixel sources (inc camera) are mutually exclusive;

Register Map
1. register 0 (offset 0): select register; 
        bit[2:0] for multiplexing;
        3'b001: test pattern generator;
        3'b010: camera ov7670;
        3'b100: none;
        
Register Definition:
1. register 0: control register;
        
Register IO access:
1. register 0: write and readl
******************************************************************/

`ifndef CORE_VIDEO_SRC_MUX_SV
`define CORE_VIDEO_SRC_MUX_SV

`include "IO_map.svh"

module core_video_src_mux
    #(parameter 
        LCD_WIDTH = 240,   
        LCD_HEIGHT = 320, 
            
        // pixel width;
        SRC_BITS_PER_PIXEL = 16,    // from the test pattern generator;
        SINK_BITS_PER_PIXEL = 8     // LCD only accepts 8-bit in parallel at a time;        
    )
    (
        // general; 
        input logic clk,    // system clock;
        input logic reset, // async;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        /* for downstream */
        /* for video downstream */       
        output logic [SINK_BITS_PER_PIXEL-1:0] stream_out_rgb, // 8-bit for the LCD;
        input logic sink_ready, // signal from the lcd fifo;
        output logic sink_valid, // signal to the lcd fifo
        
        /* from different upstream pixel sources */
        // from the test pattern;
        input logic [SINK_BITS_PER_PIXEL-1:0] pattern_rgb,  // pixel source;
        output logic pattern_ready, // from lcd fifo to the test pattern generator;
        input logic pattern_valid,  // from the test pattern gen to the lcd fifo;
        
        // from the camera;
        input logic [SINK_BITS_PER_PIXEL-1:0] camera_rgb,   // pixel source;
        output logic camera_ready, // from lcd fifo to the camera;
        input logic camera_valid   // from the camera to the lcd fifo;
        
        /* note */
        // for none; this is done here; so no explicit signals for this;
        
        
    );
    
    // constants;
    localparam SEL_TEST = `V2_DISP_SRC_MUX_REG_SEL_TEST;
    localparam SEL_CAM  = `V2_DISP_SRC_MUX_REG_SEL_CAM;
    localparam SEL_NONE = `V2_DISP_SRC_MUX_REG_SEL_NONE;
    
    /// signals;
    logic [2:0] select;
   
    // enabler;
    logic wr_en;
    
   // ff;
   always_ff @(posedge clk, posedge reset)
        if(reset) begin
            select <= 3'b100;   // default; blanked;
        end
        
        else begin
            if(wr_en)
                select <= wr_data[2:0];
        end
  
    
    // decoding the cpu instruction;
    // note that there is only one register;
    assign wr_en = cs && write;
    
    // reading;
    // again there is nothing to multiplex for cpu 
    // since there is only register to read;
    assign rd_data = {29'b0, select};   // pad the rest with zero;
    
    // multiplexer;
    always_comb begin        
        // default;
        stream_out_rgb  = {SINK_BITS_PER_PIXEL{1'b0}};  // black pixels;
        pattern_ready   = 1'b0;
        camera_ready    = 1'b0;
        sink_valid      = 1'b0;
        
        // main machinery;
        case(select)
            SEL_TEST: begin
                stream_out_rgb  = pattern_rgb;
                pattern_ready   = sink_ready;
                sink_valid      = pattern_valid;                
            end
            SEL_CAM: begin
                stream_out_rgb = camera_rgb;
                camera_ready   = sink_ready;
                sink_valid     = camera_valid;                    
            end
                
            SEL_NONE: begin
                stream_out_rgb = {SINK_BITS_PER_PIXEL{1'b0}};  // dont care; black pixel;
                sink_valid     = 1'b0;  // always not valid;
            end
            
            default : ; // nop;
        endcase    
    end
endmodule

`endif //CORE_VIDEO_SRC_MUX_SV