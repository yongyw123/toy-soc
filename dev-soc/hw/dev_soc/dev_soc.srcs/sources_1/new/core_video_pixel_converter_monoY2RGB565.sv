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
    
   /*
   assign src_ready = sink_ready;
   assign sink_data = src_data;
   assign sink_valid = src_valid;
   */
   
   
   /* -------------------------------------
   * signal declarations and mapping;
   --------------------------------------*/
   // constants;
   localparam BIT_16B = 16;
   localparam BIT_8B = 8;
   
   // converter;
   logic [BIT_16B-1:0] converted_rgb565;
   
   // **** UPSTREAM FIFO
   // write interface of the upstream fifo
   logic up_flag_full;
   logic [BIT_16B-1:0] up_src_data;
   logic up_wr;
   
   assign up_src_data = converted_rgb565;       // through the converter;
   assign up_wr = src_valid && !up_flag_full;   // when the upstream has valid data;
   assign src_ready = !up_flag_full;            // signal from this fifo to the upstream;
   
   // read interface of the upstream fifo;
   logic up_flag_empty;
   logic [BIT_16B-1:0] up_sink_data;
   logic up_rd;
   
   // interface betwene the upstream fifo and the filter;
   logic pass_src_valid;
   logic pass_src_ready;
   logic [BIT_16B-1:0] pass_in_data;
   
   assign pass_src_valid = !up_flag_empty;
   assign up_rd = pass_src_ready;
   assign pass_in_data = up_sink_data;

   //******* DOWNSTREAM FIFO;
   logic down_flag_full;
   logic down_wr;
   logic [BIT_8B-1:0] down_src_data;
   
   // write interface of the downstream fifo;
   logic pass_sink_valid;
   logic pass_sink_ready;
   logic [BIT_8B-1:0] pass_sink_data;
   
   assign pass_sink_ready = !down_flag_full;
   assign down_wr = pass_sink_valid;
   assign down_src_data = pass_sink_data;
   
   // read interface of the downstream fifo;
   logic down_flag_empty;
   logic down_rd;
   logic [BIT_8B-1:0] down_sink_data;
   
   // module interface;
   assign down_rd = sink_ready;
   assign sink_valid = !down_flag_empty;
   assign sink_data = down_sink_data; 

   FIFO
    #(
    .DATA_WIDTH(BIT_16B),
    .ADDR_WIDTH(8)
    )
    fifo_upstream_unit
    (
        .clk(clk),
        .reset(reset),
        .ctrl_rd(up_rd), // read request;
        .ctrl_wr(up_wr), // write request;
        .flag_empty(up_flag_empty),
        .flag_full(up_flag_full),
        
        .rd_data(up_sink_data),
        .wr_data(up_src_data)
	);
   
   // convert Y to RGB565;
   pixel_mono_YUV422_to_RGB565  
   converter_unit
    (
        .pixel_in(src_data),
        .rgb565_out(converted_rgb565)    
    );
    
    // not all bytes have the Y component;
    // need to filter them out;
    pixel_Y2RGB565_pass
    pixel_Y2RGB565_pass_unit
    (
        // general;
        .clk_sys(clk),    // 100Mhz;
        .reset(reset),      // async;
        
        // interface with the upper stream;
        .src_valid(pass_src_valid),
        .src_ready(pass_src_ready),
        
        // interface with the upper conversion block;
        .converted_rgb565_in(pass_in_data),
        
        // interface with the down stream;
        .sink_ready(pass_sink_ready),
        .sink_valid(pass_sink_valid),
        .rgb565_out(pass_sink_data)        
    );
    
    FIFO
    #(
    .DATA_WIDTH(BIT_8B),
    .ADDR_WIDTH(8)
    )
    fifo_downstream_unit
    (
        .clk(clk),
        .reset(reset),
        .ctrl_rd(down_rd), // read request;
        .ctrl_wr(down_wr), // write request;
        .flag_empty(down_flag_empty),
        .flag_full(down_flag_full),
        
        .rd_data(down_sink_data),
        .wr_data(down_src_data)
	);
   
   
   
   
   
   
   // cpu reading;
   assign rd_data = 0;
   
endmodule

`endif // CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_SV