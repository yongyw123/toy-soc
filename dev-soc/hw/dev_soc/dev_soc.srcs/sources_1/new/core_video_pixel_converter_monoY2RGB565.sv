`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 19:13:49
// Design Name: 
// Module Name: core_video_pixel_converter_monoY2RGB565
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

/******************************************************************
V4_PIXEL_COLOUR_CONVERTER
--------------------------
Purpose: if the camera output is in YUV422, then a conversion is needed
because LCD only accepts RGB565 format;

Construction:
1. for convenience, only the Y of the YUV422 is converted; 
2. hence, the LCD display will be grayscale;

Assumption:
1. the camera output YUV422 configuration is UYVY;
2. the Y appears as every second byte;
3. this could be configured on the camera OV7670 side;

------------
Register Map
1. register 0 (offset 0): control register;
        
Register Definition:
1. register 0: control register;
        bit[0] bypass the colour converter
        0: "disabled" to bypass the colour converter;
        1: "enabled" to go through the colour converter;
                    
Register IO access:
1. register 0: write and read;
******************************************************************/
`ifndef CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_SV
`define CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_SV

`include "IO_map.svh"


module core_video_pixel_converter_monoY2RGB565
    #(parameter 
                
        // pixel width;
        BITS_PER_PIXEL_16B = 16,    
        BITS_PER_PIXEL_8B = 8   
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
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,           
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // interface with the upstream;
        input logic src_valid,
        output logic src_ready,
        input logic [BITS_PER_PIXEL_8B - 1:0] src_data,
        
        // interface with the downstream;
        input logic sink_ready,
        output logic sink_valid,
        output logic [BITS_PER_PIXEL_8B - 1:0] sink_data
    );
    
    
   assign src_ready = sink_ready;
   assign sink_data = src_data;
   assign sink_valid = src_valid;
   assign rd_data = 0;
   
   
endmodule

`endif // CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_SV