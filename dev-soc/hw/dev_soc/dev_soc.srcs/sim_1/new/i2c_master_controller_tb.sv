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
    (
        input logic clk,
        output logic [31:0] test
    );
    
    initial begin
    test = 0;   
    $display("test starts");
    for(int i = 0; i < 10; i++) begin
    
        @(posedge clk);
        test++;
    end
    
    #(10);
    $display("test ends");
    $stop;
    end
endprogram
