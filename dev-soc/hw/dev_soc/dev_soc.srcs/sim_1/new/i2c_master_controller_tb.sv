`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.04.2023 21:26:13
// Design Name: 
// Module Name: i2c_master_controller_tb
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


program i2c_master_controller_tb
    #(parameter
        I2C_CLK_WIDTH = 32,       // for i2c clock counter;
        I2C_TOTAL_CMD_NUM = 3,   // number of i2c command: start, stop, repeat_start etc..?
        I2C_DATA_BIT = 8
     )
    
    (
        
        input clk,  // system clock;
        
        // i2c main lines;
        input logic scl,        // test stimulus based on i2c clock; not the system clock;
        output logic sda,       
        // scl is either HiZ or Zero; so created anothe replicate of scl that is either high or low (well defined);
        input logic debug_scl_sim, 
        
        // status output from the uyt;
        input done_flag,
        input ready_flag,
        
        // test stimulus input for the uut;
        output logic [I2C_CLK_WIDTH-1:0] user_cnt_mod,    // counter modulus;
        output logic [I2C_TOTAL_CMD_NUM-1:0] user_cmd,    // what command: stop, start,?
        output logic wr_i2c_start,                   // initiate the i2c master;
        output logic [I2C_DATA_BIT-1:0] din,             // i2c write data;
        
        // sim var;
        output logic [31:0] test_index,
        output logic [I2C_DATA_BIT-1:0] slave_data_write
    );
    
    localparam sys_freq = 100_000_000;  // 100MHz;
    localparam scl_rate_candidate_01 = 2_500_000; // 2.5MHz;
    //localparam scl_rate_candidate_02 = 250_000; // 1MHz;
    localparam scl_program_candidate_mod_01 =  sys_freq/(4*scl_rate_candidate_01) - 1;
    //localparam scl_program_candidate_mod_02 =  sys_freq/(4*scl_rate_candidate_01) - 1;
    
    // command constants;
    localparam CMD_START    = 3'b000;   // generate start condition;
    localparam CMD_WR       = 3'b001;   // master write to slave;
    localparam CMD_RD       = 3'b010;   // master reads from slave;
    localparam CMD_STOP     = 3'b011;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b100;   // generate repeated_start condition;
    
    
    initial begin
    
    $display("test starts");
    $display("test 01, check i2c scl rate program--------");
    $display("set rate: 10.0 MHz");
    @(posedge clk);
    user_cnt_mod <= scl_program_candidate_mod_01;
    user_cmd <= CMD_START;
    wr_i2c_start <= 1'b1;
    
    @(posedge clk);
    user_cmd <= CMD_WR;
    //wait(ready_flag == 1'b0);    // expect it to be working;
    //wait(ready_flag == 1'b1);    // expect it to be eventually free;
    #(5000);
    /*
    wait(done_flag == 1'b1);
    // set another rate;
    $display("set rate: 1.0 MHz");
    @(posedge clk);
    user_cnt_mod <= scl_program_candidate_mod_01;
    user_cmd <= CMD_START;
    wr_i2c_start <= 1'b1;
    */
    
    #(10);
    $display("test ends");
    $stop;
    end
endprogram
