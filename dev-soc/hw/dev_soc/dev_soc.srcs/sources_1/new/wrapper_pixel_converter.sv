`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2023 16:07:55
// Design Name: 
// Module Name: wrapper_pixel_converter
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

/*
purpose: wrapper for the following modules;

modules:
1. (upstream) fifo;
2. pixel_mono_YUV422_to_RGB565
3. pixel_Y2RGB565_pass;
4. (downstream) fifo;
*/

module wrapper_pixel_converter
    #(parameter 
                
        // pixel width;
        BITS_PER_PIXEL_16B = 16,    
        BITS_PER_PIXEL_8B = 8   
    )
    (
        // general;
        input logic clk, // system clock;
        input logic reset,  // async reset;
        
        // interface with the upstream;
        input logic src_valid,
        output logic src_ready,
        input logic [BITS_PER_PIXEL_8B - 1:0] src_data,
        
        // interface with the downstream;
        input logic sink_ready,
        output logic sink_valid,
        output logic [BITS_PER_PIXEL_8B - 1:0] sink_data,
        
        
        // debugging;
        output logic debug_pass_src_valid,
        output logic debug_pass_src_ready,
        output logic [15:0] debug_pass_in_data,
        
        output logic debug_pass_sink_ready,
        output logic debug_down_wr,
        output logic [7:0] debug_down_src_data
        
    );
    
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
   
   // important;
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

    // debugging
   assign debug_pass_src_valid = pass_src_valid;
   assign debug_pass_src_ready = pass_src_ready;
   assign debug_pass_in_data = pass_in_data;


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
      
   assign debug_pass_sink_ready = pass_sink_ready;
   assign debug_down_wr = down_wr;
   assign debug_down_src_data = down_src_data;
   
   // read interface of the downstream fifo;
   logic down_flag_empty;
   logic down_rd;
   logic [BIT_8B-1:0] down_sink_data;
   
   // module interface;
   assign down_rd = sink_ready && !down_flag_empty; // important;
   assign sink_valid = !down_flag_empty;
   assign sink_data = down_sink_data; 

   // convert Y to RGB565;
   pixel_mono_YUV422_to_RGB565  
   converter_unit
    (
        .pixel_in(src_data),
        .rgb565_out(converted_rgb565)    
    );
   
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
   
   
endmodule
