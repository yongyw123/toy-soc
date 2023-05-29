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
    
    // constants;
    localparam DISABLE_CONVERTER = 1'b0;
    localparam ENABLE_CONVERTER = 1'b1;
    localparam REG_CTRL_OFFSET = 1'b0;
    localparam BIT_8B = 8;
    
    /* signal declarations */
    // arguments for the converter;
    // interface with the upstream;
    logic converter_src_valid;
    logic converter_src_ready;
    logic [BIT_8B-1:0] converter_src_data;
       
    // interface with the downstream;
    logic converter_sink_ready;
    logic converter_sink_valid;
    logic [BIT_8B-1:0] converter_sink_data; 
                
    // enabler signals;
    logic wr_en;
    logic rd_en;
    
    // registers;
    logic ctrl_reg, ctrl_next;
    
    // ff;
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            ctrl_reg <= DISABLE_CONVERTER;
        end
        else begin
            if(wr_en) begin 
                ctrl_reg <= ctrl_next;
            end
        end
    end    
    
    // cpu instruction decoding;
    // note that the address decoding is not necessary since there is only one register;
    assign wr_en = (addr[0] == REG_CTRL_OFFSET) && cs && write;
    assign rd_en = (addr[0] == REG_CTRL_OFFSET) && cs && read;
    
    // next state;
    assign ctrl_next = wr_data[0];
    
    // cpu reading;
    assign rd_data = {31'b0, ctrl_reg};
     
    // fsm for multiplezing;
    always_comb begin
        
        // default;
        converter_src_data = 1; // dummy;
        
        
        case(ctrl_reg) 
            // go through the converter;
            ENABLE_CONVERTER: begin
                // interface with the upstream;
                src_ready = converter_src_ready;
                converter_src_data = src_data;
                converter_src_valid = src_valid;
                
                // interface with the downstream;
                converter_sink_ready = sink_ready;
                sink_valid = converter_sink_valid;
                sink_data = converter_sink_data;
            end
        
            // bypass the converter
            default: begin
                src_ready = sink_ready;
                sink_data = src_data;
                sink_valid = src_valid;
                
                // disable the converter;
                converter_src_valid = 1'b0;
                converter_sink_ready = 1'b0;
            end
        endcase
    end
    
   // instantiation;
   wrapper_pixel_converter
   pixel_converter_unit
   (    
        // general;
        .clk(clk), // system clock;
        .reset(reset),  // async reset;

        // interface with the upstream;
        .src_valid(converter_src_valid),
        .src_ready(converter_src_ready),
        .src_data(converter_src_data),
        
        // interface with the downstream;
        .sink_ready(converter_sink_ready),
        .sink_valid(converter_sink_valid),
        .sink_data(converter_sink_data),

        // debugging;
        .debug_pass_src_valid(),
        .debug_pass_src_ready(),
        .debug_pass_in_data(),
        
        .debug_pass_sink_ready(),
        .debug_down_wr(),
        .debug_down_src_data()  
   );
   
endmodule

`endif // CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_SV