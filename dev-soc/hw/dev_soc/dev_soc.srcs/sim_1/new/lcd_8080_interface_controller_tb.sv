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
        output logic user_cmd,
        output logic [PARALLEL_DATA_BITS-1:0] wr_data,
        
        // sim;
        output logic [31:0] test_index      
    );
    
    // command constanst;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
     
    initial begin
    $display("test starts");
    $display("-----------");
    $display("test 01:");
    $display("-----------");
    @(posedge clk);
    test_index <= 0;
    set_wr_mod <= 3;
    wr_data = 8'($random);
    user_start <= 0;
    
    @(posedge clk);
    
    
    
    #(20);
    $display("test ends");
    $stop;
    end
    
    
    
endprogram
