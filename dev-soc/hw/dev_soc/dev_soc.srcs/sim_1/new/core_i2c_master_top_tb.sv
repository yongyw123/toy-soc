`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 16:01:01
// Design Name: 
// Module Name: core_i2c_master_top_tb
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

`ifndef CORE_I2C_MASTER_TOP_TB_SV
`define CORE_I2C_MASTER_TOP_TB_SV

`include "IO_map.svh"

module core_i2c_master_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    /* interface arguents;; */
    // input;
    logic cs;
    logic write;
    logic read;
    logic [`REG_ADDR_SIZE_G-1:0] addr;    
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
   
    // output;
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    // i2c specific;
    
    
endmodule

`endif //CORE_I2C_MASTER_TOP_TB_SV
