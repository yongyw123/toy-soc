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
        output logic [31:0] set_wr_mod,
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
    @(posedge clk);
    test_index <= 0;
    set_wr_mod <= 2;
    wr_data = 8'($random);
    user_start <= 0;
    
    // user command is unknown;
    // expect the state to be always in idle state;
    // until the command is specified;
    #(30);
    
    @(posedge clk);
    user_cmd <= CMD_WR;
    user_start <= 1;
    
    @(posedge clk);
    user_start <= 0;
    wait(ready_flag == 1'b1);
    
    @(posedge clk);
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
    set_wr_mod <= 2;
    wr_data = 8'($random);
    user_start <= 1;
    user_cmd <= CMD_RD;
    
    
    
    #(100);
    $display("test ends");
    $stop;
    end
    
    
    
endprogram
