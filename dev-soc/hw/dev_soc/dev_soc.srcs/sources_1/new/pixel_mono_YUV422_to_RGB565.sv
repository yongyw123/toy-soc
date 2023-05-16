`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 02:08:20
// Design Name: 
// Module Name: pixel_mono_YUV422_to_RGB565
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
purpose: to convert the Y of YUV422 to RGB565 format;
note    : the converted will be in grayscale when displayed on the LCD;

formula:
-----------
given:
1. Y is the 8-bit from YUV422 component;
2. R is the converted Y;

formula: R = swap16((Y & 0xF8) << 8)|((Y & 0xFC) << 3)|((Y & 0xF8)>>3)

Note:
---------
1. The formulae above is chosen for simplicity;
    - only fixed point;
    - involve shfting and masking operation;
Acknowledgment:
The formulae above is adapted from the following:
Author: projectitis
URL: https://github.com/projectitis/tilemap/blob/master/Bitmap.h

*/

module pixel_mono_YUV422_to_RGB565    
    (
        input logic [7:0] pixel_in,
        output logic [15:0] rgb565_out
    
    );
    
    // signal declaration;
    logic [15:0] placeholder;
    logic [15:0] r_component;
    logic [15:0] g_component;
    logic [15:0] b_component;
    
    // formulae;
    assign r_component = ((pixel_in & 8'hF8) << 8);
    assign g_component = ((pixel_in & 8'hFC) << 3);
    assign b_component = ((pixel_in & 8'hF8) >> 3);
    
    // combine;
    assign placeholder = r_component | g_component | b_component;
     
    // ??
    // swap upper 8 byte with the lower 8 byte for endianness;
    // lcd and camera output are big endian;
    // soc is little endian;
    assign rgb565_out = {placeholder[7:0], placeholder[15:8]};   
    //assign rgb565_out = placeholder; 
        
endmodule
