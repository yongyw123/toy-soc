`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 22:08:17
// Design Name: 
// Module Name: FIFO_DUALCLOCK_MACRO_reset_system_tb
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


program FIFO_DUALCLOCK_MACRO_reset_system_tb
    (
        input clk_sys,
        input FIFO_rst_ready
    );
    
    initial begin
    #(1000);
    //wait(FIFO_rst_ready == 1'b1);
    
    
    $stop;
    end
endprogram
