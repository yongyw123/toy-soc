`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 23:34:08
// Design Name: 
// Module Name: FIFO_DUALCLOCK_MACRO_reset_system_reset_test_stimulus_tb
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


program FIFO_DUALCLOCK_MACRO_reset_system_reset_test_stimulus_tb
        (
            input logic clk_sys,
            output logic reset_sys,            
            input logic FIFO_rst_ready
        );

    initial begin
        reset_sys = 1'b1;
        #(10);
        reset_sys = 1'b0;
        #(10);
        
        #(1000);
        $stop;
    end 
endprogram
    
    