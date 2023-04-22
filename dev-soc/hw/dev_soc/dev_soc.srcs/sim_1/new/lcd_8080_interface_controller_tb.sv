`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2023 03:21:16
// Design Name: 
// Module Name: lcd_8080_interface_controller_tb
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


program lcd_8080_interface_controller_tb
    #(parameter
    PARALLEL_DATA_BITS = 8
    )
    (
        input logic clk,
        
        // test stimulus;
        // set the write cycle time;
        output logic [15:0] set_wr_mod_fhalf,    // first half of the write clock;     
        output logic [15:0] set_wr_mod_shalf,    // second half of the write clockl
        
        // set the read cycle time;
        output logic [15:0] set_rd_mod_fhalf,    // first halfl;
        output logic [15:0] set_rd_mod_shalf,    // first halfl;

        output logic user_start,
        output logic [1:0] user_cmd,
        output logic [PARALLEL_DATA_BITS-1:0] wr_data,
        
        // inputs;
        input logic done_flag,
        input logic ready_flag,
        
        // sim;
        output logic [31:0] test_index      
    );
    
    // command constanst;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
     
    initial begin
    $display("test starts");
    // test 01; write only;
    // set the write period to be the same;
    // lower == upper;
    @(posedge clk);
    test_index <= 0;
    set_wr_mod_fhalf <= 2;
    set_wr_mod_shalf <= 3;
    wr_data = 8'($random);
    user_start <= 0;
    
    // user command is unknown;
    // expect the state to be always in idle state;
    // until the command is specified;
    #(30);
    
    // expect here to be the first start;
    @(posedge clk);
    user_cmd <= CMD_WR;
    user_start <= 1;
    
    @(posedge clk);
    user_start <= 0;
    // pause;
    @(posedge clk);
    #(100);
    
    
    // change the write clock setting;
    // longer second half of the write cycle;
    @(posedge clk);
    set_wr_mod_fhalf <= 2;
    set_wr_mod_shalf <= 3;
    user_start <= 1;
    wr_data = 8'($random);
    
    
    // need to disable the start;
    // otherwise;
    // it will automatically restart
    // the tx as soon as the ready_flag is up;
    // by which the data to output remains the 
    // previous one;
    // this conforms to the expectation;
    // that at the assertion of the start;
    // the data to output will be when the start assertion occurs;
    @(posedge clk);
    user_start <= 0;
        
    @(posedge clk);
    wait(ready_flag == 1'b1);
    
    // change the write clock setting;
    // longer first half of the write cycle;
    @(posedge clk);
    set_wr_mod_fhalf <= 3;
    set_wr_mod_shalf <= 2;
    user_start <= 1;
    wr_data = 8'($random);
    
    @(posedge clk);
    wait(ready_flag == 1'b1);
    
    @(posedge clk);
    user_start <= 0;
    wait(ready_flag == 1'b1);
    
    #(100);
    
    
    // test 02: set to read; expect dinout to be hiZ;
    @(posedge clk);
    test_index <= 1;
    
    // fhalf is always shorted than the second half during read;
    // it takes time for the lcd to prepare its output;
    // see the datasheet;
    set_rd_mod_fhalf <= 2;  
    set_rd_mod_shalf <= 5;
    
    wr_data = 8'($random);
    user_start <= 1;
    user_cmd <= CMD_RD;
    
    @(posedge clk);
    user_start <= 0;
    wait(ready_flag == 1'b1);
    
    
    #(100);
    $display("test ends");
    $stop;
    end
    
    
    
endprogram
