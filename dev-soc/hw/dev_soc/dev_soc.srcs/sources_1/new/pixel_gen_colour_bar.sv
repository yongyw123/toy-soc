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
pattern      : eight colour bars accoding to EBU colour bar format
reference    : https://en.wikipedia.org/wiki/EBU_colour_bars
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
        BITS_PER_PIXEL  = 16,    
        COUNTER_WIDTH   = 10,  // counter width from the frame counter
        LCD_WIDTH       = 240,
        LCD_HEIGHT      = 320
    )
    (
        // general;
        input logic clk,
        input logic reset,  // async;
        
        // input; 
        input logic [COUNTER_WIDTH:0] xcoor,
        input logic [COUNTER_WIDTH:0] ycoor,
        
        // output;
        output logic [BITS_PER_PIXEL-1:0] rgb565_out
    );
    
    localparam NUM_COLOUR_BAR = 8;
    
    localparam WHITE    = 16'hFFFF;
    localparam YELLOW   = 16'hFFE0;
    localparam CYAN     = 16'h07FF;
    localparam GREEN    = 16'h07E0;
    localparam MAGNETA  = 16'hF81F;
    localparam RED      = 16'hF800;
    localparam BLUE     = 16'h001F;
    localparam BLACK    = 16'h0000;
    
    always_comb begin
        // dummy value for now;
        //rgb565_out = {(1'b1 + 7'(xcoor)), (8'(xcoor))};
        // first bar;
        if(ycoor < 40)
            rgb565_out = 16'(WHITE);
        else if(ycoor < 80)
            rgb565_out = 16'(YELLOW);
        else if(ycoor < 120)
            rgb565_out = 16'(CYAN);
        else if(ycoor < 160)
            rgb565_out = 16'(GREEN);
        else if(ycoor < 200)
            rgb565_out = 16'(MAGNETA);
        else if(ycoor < 240)
            rgb565_out = 16'(RED);
        else if(ycoor < 280)
            rgb565_out = 16'(BLUE);
        else
           rgb565_out = 16'(BLACK);
    end
endmodule
