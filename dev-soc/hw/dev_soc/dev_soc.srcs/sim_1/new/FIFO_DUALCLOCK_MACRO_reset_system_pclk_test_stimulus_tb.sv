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
program FIFO_DUALCLOCK_MACRO_reset_system_pclk_test_stimulus_tb
    (        
        output logic slower_clk
    );

    initial begin
        slower_clk = 1'b0;
        forever 
            #40 slower_clk = !slower_clk;
    end
endprogram

    
