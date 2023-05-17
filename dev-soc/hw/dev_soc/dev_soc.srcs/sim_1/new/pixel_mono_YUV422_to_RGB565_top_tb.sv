`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 02:32:15
// Design Name: 
// Module Name: pixel_mono_YUV422_to_RGB565_top_tb
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


module pixel_mono_YUV422_to_RGB565_top_tb();
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    /* uut argument */
    
    logic [7:0] pixel_in;
    logic [15:0] rgb565_out;
    
    /* ----- instantiation*/
    pixel_mono_YUV422_to_RGB565 uut (.*);
    pixel_mono_YUV422_to_RGB565_tb tb(.*);
    
    /* --- clk */
    /* note that the uut is purely combinational */
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end
    
    // monitoring;
    initial begin
        $display("r_mask: %8B, g_mask: %8B, b_mask: %8B",  8'hF8, 8'hFC, 8'hF8);
        $monitor("time: %t, pixel_in: %8B, uut.r_component:%16B, uut.g_component:%16B, uut.b_component: %16B, uut.placeholder: %16B, rgb565_out: %16B",
        $time,
        pixel_in,
        uut.r_component,
        uut.g_component,
        uut.b_component,
        uut.placeholder,
        rgb565_out 
    );
    end

    
endmodule
