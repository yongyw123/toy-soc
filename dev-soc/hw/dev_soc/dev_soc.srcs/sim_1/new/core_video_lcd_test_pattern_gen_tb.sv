`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2023 01:37:05
// Design Name: 
// Module Name: core_video_lcd_test_pattern_gen_tb
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

`ifndef CORE_VIDEO_LCD_TEST_PATTERN_GEN_TB_SV
`define CORE_VIDEO_LCD_TEST_PATTERN_GEN_TB_SV

`include "IO_map.svh"

program core_video_lcd_test_pattern_gen_tb
    
    (
        input logic clk,
        output logic cs,
        output logic write,
        output logic read,
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic sink_ready,
        input logic sink_valid
    );
    
    initial begin
    $display("test starts");
    @(posedge clk);
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care;
    addr <= 0;  
    
    // expect no activity;
    // since it is disabled;
    wr_data <= 0;   // disable the test pattern;
    sink_ready <= 1'b1;
    
    
    #(50);
    // expect no activtiy stilll;
    // because sink_ready is not ready;
    wr_data <= 1;   // enable the test pattern;  
    sink_ready <= 1'b0;
    
    #(50);
    
    $display("test ends");
    #(30);
    $stop;
    end
endprogram 

`endif // CORE_VIDEO_LCD_TEST_PATTERN_GEN_TB_SV