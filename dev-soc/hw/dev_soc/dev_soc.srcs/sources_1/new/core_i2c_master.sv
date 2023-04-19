`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 15:07:53
// Design Name: 
// Module Name: core_i2c_master
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
`ifndef CORE_I2C_MASTER_SV
`define CORE_I2C_MASTER_SV

`include "IO_map.svh"



module core_i2c_master
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        /* EXTERNAL PINS: I2C specific;*/
        // I2C standard signals;
        // i2c clock; only driven by the master;
        // declared state because in HiZ, the line is resistor-pulled-up;
        output tri scl, 
        // inout because shared between the master and the slave'
        // also, tri by the same reason as above; resistor pull up and multiple lines sharing;
        inout tri sda   
    );
      
endmodule


`endif // CORE_I2C_MASTER_SV
