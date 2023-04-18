`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.04.2023 15:48:35
// Design Name: 
// Module Name: i2c_controller
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
purpose: i2c master controller;
assumption;
1. only one master (so no arbitration);
2. no clock stretching;

construction;
1. please see this doc linked below
https://docs.google.com/document/d/1ry1kXqD7P2slyMiV86lYMIhMr_kSJ_o6/edit?usp=share_link&ouid=109361905057067991130&rtpof=true&sd=true

*/
module i2c_master_controller
    #(parameter
        I2C_CLK_WIDTH = 32,       // for i2c clock counter;
        I2C_TOTAL_CMD_NUM = 3,   // number of i2c command: start, stop, repeat_start etc..?
        I2C_DATA_BIT = 8
     )
    (
        /* general; */
        input logic clk,    // 100 Mhz;
        input logic reset,  // async;
        
        /* i2c specific */
        // user input;
        input logic [I2C_CLK_WIDTH-1:0] cnt_mod,    // counter modulus;
        input logic [I2C_TOTAL_CMD_NUM-1:0] cmd,    // what command: stop, start,?
        input logic wr_i2c_start,                   // initiate the i2c master;
        input logic [I2C_DATA_BIT-1:0] din,             // i2c write data;
        
        // user output;
        output logic ready_flag,    // idle;
        output logic done_flag,     // just finish i2c communications;
        output logic ack_flag,      // from slave for processing to determine if slave has ack;
        output logic [I2C_DATA_BIT-1:0] dout,   // slave data;
        
        // i2c actual hw pins;
        // must be tristate by i2c construction/specs;
        output tri scl, // clock is always initiated by the master;
        inout tri sda   // this line is shared between master and slaves;
    );
    
    
endmodule
