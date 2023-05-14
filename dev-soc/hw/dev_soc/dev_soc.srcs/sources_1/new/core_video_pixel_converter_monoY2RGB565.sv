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
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
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
    localparam ENABLE_CONVERTER = 1'b1;
    localparam DISABLE_CONVERTER = 1'b0;
    
    /*----------- declaration */   
    // interface between the pixel converter and the selector;
    logic [BITS_PER_PIXEL_16B-1:0] converted_rgb565;
    
    // interface betwene the upstream mux and the pixel selector;
    logic src_valid_pixel_selector;
    logic src_ready_pixel_selector;
    
    
    // interface between the pixel selector and downstream mux; 
    logic [BITS_PER_PIXEL_8B-1:0] converter_rgb565_downstream;
    logic sink_ready_pixel_converter;
    logic sink_valid_pixel_converter;
    
    // registers;
    logic ctrl_reg, ctrl_next;
    
    // ff;
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            ctrl_reg <= 1'b0;   // colour converter disabled by default;
        end
        else begin
            ctrl_reg <= wr_data[0];
        end    
    end
    
    /* ----------------------------
    * upstream multiplexer
    -----------------------------*/
    always_comb begin
        // bypass the converter; 
        if(ctrl_reg == DISABLE_CONVERTER) begin
            src_valid_pixel_selector = 1'b0;    
            src_ready = sink_ready;
        end
        // go through the converter;
        else begin
            src_valid_pixel_selector = src_valid;
            src_ready = src_ready_pixel_selector;
        end
    end
    
    /* ----------------------------
    * downstream multiplexer
    -----------------------------*/
    always_comb begin
        // bypass the converter;
        if(ctrl_reg == DISABLE_CONVERTER) begin
            sink_data = src_data;
            sink_valid = src_valid;   
            sink_ready_pixel_converter = 1'b0;     
        end
        // go through the converter;
        else begin
            sink_data = converter_rgb565_downstream;
            sink_valid = sink_valid_pixel_converter;
            sink_ready_pixel_converter = sink_ready;        
        end
    end
    
    /* ------------ instantiation */
    
    // converter
    pixel_mono_YUV422_to_RGB565
    converter_unit(
        .pixel_in(src_data),
        .rgb565_out(converted_rgb565)
    );
    
    
    // pixel selector;
    pixel_Y2RGB565_pass
    (
        // general;
        .clk_sys(clk),    // 100Mhz;
        .reset(reset),      // async;
        
        // interface with the upper stream;
        .src_valid(src_valid_pixel_selector),
        .src_ready(src_ready_pixel_selector),
        
        // interface with the upper conversion block;
        .converted_rgb565_in(converted_rgb565),
        
        // interface with the down stream;
        .sink_ready(sink_ready_pixel_converter),
        .sink_valid(sink_valid_pixel_converter),
        .rgb565_out(converter_rgb565_downstream)        
    );
       

    // read out;    
    assign rd_data = {31'b0, ctrl_reg};
    
endmodule
