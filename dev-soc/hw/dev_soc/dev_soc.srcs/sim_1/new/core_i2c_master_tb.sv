`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 16:00:43
// Design Name: 
// Module Name: core_i2c_master_tb
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


module core_i2c_master_tb
    (
        input logic clk,
        input logic reset,
        
        // test stimulus;
        output logic cs,
        output logic write,
        output logic read,
        output logic [`REG_ADDR_SIZE_G-1:0] addr,    
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data, 
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // i2c pins;
        input tri scl,
        inout tri sda   
    );
    
    
    
endmodule
