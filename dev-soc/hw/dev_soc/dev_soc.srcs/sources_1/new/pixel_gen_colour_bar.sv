`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.04.2023 14:13:58
// Design Name: 
// Module Name: pixel_gen_colour_bar
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
purpose      : pixel test pattern generator for LCD-TFT display;
what         : colour bar;
note         : purely a combinational circuit, driven by another module: frame_counter
construction :
1. frame counter module specifies the (x,y) coordinate which represents the pixel
    location within the LCD;
2. this module uses this coordinate to generate the colour bar;

assumptions :
1. pixel generated is 16-bit wide in RGB565 format;
2. the scanning direction of the pixel generated is fixed; ?? TBA ??
 

*/
module pixel_gen_colour_bar
    #(parameter 
    BITS_PER_PIXEL = 16,    
    COUNTER_WIDTH = 10  // counter width from the frame counter
    )
    (
        // general;
        input logic clk,
        input logic reset,  // async;
        
        // input; 
        input logic [COUNTER_WIDTH-1:0] xcoor,
        input logic [COUNTER_WIDTH-1:0] ycoor,
        
        // output;
        output logic [BITS_PER_PIXEL-1:0] rgb565_out
    );
    
    
    always_comb begin
        // dummy value for now;
        rgb565_out = 16'hD8D0;        
    end
endmodule
