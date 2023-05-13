`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 03:31:13
// Design Name: 
// Module Name: pixel_pass_converted_RGB565
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
purpose: choose the Y component of the YUV422 pixel;
Why?: by YUV422 format, Y is the second byte of a 16-bit pixel; but the camera only outputs
        8-bit at a time; this slightly complicates stuffs ...
Example: The pixels sequence: UY, VY, ... w where "U" and "V" are the other components;
*/

module pixel_pass_converted_RGB565
    (
        // general;
        input logic clk_sys,    // system clock;
        input logic reset,  // async
        
        // interface with the upstream
        input logic src_valid,
        output logic src_ready,
        
        // from the upstream combination block that performs
        // the relevant conversion; 
        input logic [15:0] pixel_converted_RGB565_in,
        
        // interface with the downstram;
        
        input logic sink_ready,
        output logic [7:0] y_component
    );
    
    // signal declaration;
    logic [1:0] cnt_reg, cnt_next;
    
    // ff;
    always_ff @(posedge clk_sys, posedge reset) begin
        if(reset) begin
            cnt_reg <= 0;
        end
        else begin
            if(src_valid) begin
                cnt_reg <= cnt_next;
            end
        end
    
    
    // next state;
    // wrap around;
    assign cnt_next = (cnt_reg == 2) ? 0 :  cnt_reg + 1;
    end
    
    
    
    
endmodule
