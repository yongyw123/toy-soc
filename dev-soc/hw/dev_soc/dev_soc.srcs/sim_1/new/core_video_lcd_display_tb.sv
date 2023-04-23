`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 01:22:21
// Design Name: 
// Module Name: core_video_lcd_display_tb
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

`ifndef CORE_VIDEO_LCD_DISPLAY_TB_SV
`define CORE_VIDEO_LCD_DISPLAY_TB_SV

`include "IO_map.svh"

program core_video_lcd_display_tb
    
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        // test stimulus;
        output logic cs,    
        output logic write,              
        output logic read,               
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,
        
        output logic [31:0] test_index 
    );
    
    
    initial begin
    $display("test starts");
    /* setting the clock mod */
    @(posedge clk);
    test_index <= 0;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    
    
    
    
    
    $display("test ends");
    #(20);
    $stop;
    end
endprogram 

`endif //CORE_VIDEO_LCD_DISPLAY_TB_SV