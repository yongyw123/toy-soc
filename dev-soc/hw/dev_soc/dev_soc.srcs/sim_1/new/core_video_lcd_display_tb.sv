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
      
        // output from the uut;
        input logic [31:0] rd_data,
        
       // debugging;
        output logic [31:0] test_index 
    );
    
    // register offset constanst;
    localparam REG_WR_CLOCKMOD_OFFSET = 3'b001;
    localparam REG_RD_CLOCKMOD_OFFSET = 3'b010;
    localparam REG_WR_DATA_OFFSET = 3'b011; 
    
    // bit pos;
    localparam REG_RD_DATA_BIT_POS_READY = 8;
    localparam REG_RD_DATA_BIT_POS_DONE = 9;
    
    // available commands;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
    
    // sim var;
    logic [15:0] wrx_fhalf_mod = 2;
    logic [15:0] wrx_shalf_mod = 3;
    logic [15:0] rdx_fhalf_mod = 4;
    logic [15:0] rdx_shalf_mod = 5;
    
    logic csx_select = 1'b1;
    logic dcx_command = 1'b1;
    
    
    
    initial begin
    $display("test starts");
    /* setting the clock mod */
    // set for wrx;
    @(posedge clk);
    test_index <= 0;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_WR_CLOCKMOD_OFFSET;
    wr_data <= {2'b0, wrx_shalf_mod, wrx_fhalf_mod};
    
    // set for rdx;
    @(posedge clk);
    test_index <= 1;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_RD_CLOCKMOD_OFFSET;
    wr_data <= {2'b0, rdx_shalf_mod, rdx_fhalf_mod};
    
    // start a write that is a data;
    // enable chip select;
    @(posedge clk);
    test_index <= 2;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {20'b0, CMD_WR, csx_select, dcx_command, 8'($random)};
    
    // expect the ready flag to change to busy then back to ready;
    @(posedge clk); // though it takes one system clock cycle to update;
    //wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b0); 
    //wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b1);
    
    
    
    #(200); 
    $display("test ends");
    #(20);
    $stop;
    end
endprogram 

`endif //CORE_VIDEO_LCD_DISPLAY_TB_SV