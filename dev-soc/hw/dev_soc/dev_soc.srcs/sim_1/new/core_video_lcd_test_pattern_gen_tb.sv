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
        input logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        output logic sink_ready,
        input logic sink_valid
    );
    
    localparam REG_WR_ADDR = 0;
    localparam REG_STATUS_ADDR = 1;
    
    initial begin
    $display("test starts");
    @(posedge clk);
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b0;   // dont care;
    addr <= REG_WR_ADDR;  
    
    // expect no activity;
    // since it is disabled;
    wr_data <= 0;   // disable the test pattern;
    sink_ready <= 1'b1;
    
    
    #(50);
    @(posedge clk);
    // expect no activtiy stilll;
    // because sink_ready is not ready;
    wr_data <= 1;   // enable the test pattern;  
    sink_ready <= 1'b0;
    
    #(50);
    
    // allow pixel generation;
    @(posedge clk);
    wr_data <= 1;
    sink_ready <= 1'b1;
    
    @(posedge clk);
    addr <= REG_STATUS_ADDR;
    read <= 1'b1;
    write <= 1'b0;
    
    @(posedge clk);
    wait(rd_data[0] == 1'b0);   // frame start should be deasserted;
    wait(rd_data[1] == 1'b1);   // frame ends eventually;
    wait(rd_data[0] == 1'b1);   // expect it to restart by itself it is not disabled;
    
    // allow the generator to run for some time;
    @(posedge clk);
    
        
    // disable the gen;
    // expect that the pixel generates halfway;
    @(posedge clk);
    addr <= REG_WR_ADDR;
    write <= 1'b1;
    wr_data <= 1'b0;
    
    @(posedge clk);
     #(100);
    $display("test ends");
    $stop;
    end
endprogram 

`endif // CORE_VIDEO_LCD_TEST_PATTERN_GEN_TB_SV