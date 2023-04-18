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
        inout logic sda,       
        // scl is either HiZ or Zero; so created anothe replicate of scl that is either high or low (well defined);
        input logic debug_scl_sim, 
        
        // status output from the uyt;
        input done_flag,
        input ready_flag,
        
        // test stimulus input for the uut;
        output logic [I2C_CLK_WIDTH-1:0] user_cnt_mod,    // counter modulus;
        output logic [I2C_TOTAL_CMD_NUM-1:0] user_cmd,    // what command: stop, start,?
        output logic wr_i2c,                   // initiate the i2c master;
        output logic [I2C_DATA_BIT-1:0] din,             // i2c write data;
        
        // sim var;
        output logic [31:0] test_index,
        output logic [I2C_DATA_BIT-1:0] slave_data_write
        
    );
    
    localparam sys_freq = 100_000_000;  // 100MHz;
    localparam scl_rate_candidate_01 = 25_000_000; // 25 MHz;
    //localparam scl_rate_candidate_02 = 2_500_000; // 2.5 MHz;
    //localparam scl_program_candidate_mod_01 =  sys_freq/(4*scl_rate_candidate_01) - 1;
    localparam scl_program_candidate_mod_01 =  sys_freq/(4*scl_rate_candidate_01);
    //localparam scl_program_candidate_mod_02 =  sys_freq/(4*scl_rate_candidate_01) - 1;
    
    // command constants;
    localparam CMD_START    = 3'b000;   // generate start condition;
    localparam CMD_WR       = 3'b001;   // master write to slave;
    localparam CMD_RD       = 3'b010;   // master reads from slave;
    localparam CMD_STOP     = 3'b011;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b100;   // generate repeated_start condition;
    
    logic [31:0] cnt_scl;
    logic set_slave_ack;
    logic set_slave_wr_data;
    
    /*assign sda = (set_slave_ack) ? 1'b0 : 
                 (set_slave_wr_data) ? $random  : 1'bz;
    */
    
    initial begin
    set_slave_ack = 1'b0;
    set_slave_wr_data = 1'b0;
    cnt_scl = 0;
    
    $display("test starts");
    $display("-----------");
    $display("test 01:");
    $display("1. check i2c scl rate");
    $display("2. master write");
    $display("3. master read slave ack");
    $display("-----------");
    $display("set rate: 25 MHz");
    @(posedge clk);
    test_index <= 0;
    user_cnt_mod <= scl_program_candidate_mod_01;
    user_cmd <= CMD_START;
    wr_i2c <= 1'b1;
    // master write something;
    din <= {7'($random), 1'b0};   // to isolate from the ack from the slave later;
    
    @(posedge clk);
    user_cmd <= CMD_WR;
    
    // simulate slave ack for the ninth bit;
    // use scl as the dictator;
    for(int i = 0; i < 8; i++) begin
        @(negedge scl);
        cnt_scl++;
    end
    @(negedge scl);
    set_slave_ack = 1'b1;
        
    wait(done_flag == 1'b1);    // wait for done then stop the communication;
    user_cmd <= CMD_STOP;
    set_slave_ack = 1'b0;
    
    wait(ready_flag == 1'b1);    
    wait(ready_flag == 1'b0);
    wait(ready_flag == 1'b1);        
    
    /* 
    1. first master write to the slave;
    2. followed by a read from the slave;
    3. the master send ack to the slave;
    4. followed by another read from the slave;
    5. master sends a nack to terminate the read;
    6. send a stop signal;
    */
    
    
    $display("-----------");
    $display("test 02:");
    $display("-----------");
    
    /* first part, master identofies the slave */
    @(posedge clk);
    test_index <= 1;
    user_cnt_mod <= scl_program_candidate_mod_01;
    user_cmd <= CMD_START;
    wr_i2c <= 1'b1;
    // master write something;
    din <= {7'($random), 1'b0};   // to isolate from the ack from the slave later;
    
    @(posedge clk);
    user_cmd <= CMD_WR;
    
    // simulate slave ack for the ninth bit;
    // use scl as the dictator;
    for(int i = 0; i < 8; i++) begin
        @(negedge scl);
        cnt_scl++;
    end
    @(negedge scl);
    set_slave_ack = 1'b1;
        
    wait(done_flag == 1'b1);    
    set_slave_ack = 1'b0;
    
    wait(ready_flag == 1'b1);    
    @(posedge clk);
    
    /* part 02: read from the slave */
    // simulate slave data for the master to read;
    // use scl as the dictator;
    @(posedge clk);
    $display("master to read from slave ---------------");
    user_cmd <= CMD_RD;
    din <= 0;   // lsb is the master ack bit for the slave;
    
    /*
    for(int i = 0; i < 8; i++) begin
        @(negedge scl);
        set_slave_wr_data = 1'b1;
    end
    */
    @(negedge scl);
    set_slave_wr_data = 1'b0;
    
    

    wait(done_flag == 1'b1);    // wait for done then stop the communication;
    user_cmd <= CMD_STOP;
    set_slave_ack = 1'b0;
    
    wait(ready_flag == 1'b1);    
    wait(ready_flag == 1'b0);
    wait(ready_flag == 1'b1);        
    
    
    #(10);
    $display("test ends");
    $stop;
    end
endprogram
