`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.04.2023 15:27:56
// Design Name: 
// Module Name: baud_rate_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Baud Rate Generator for UART Rx and Tx;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module baud_rate_generator
    (
        input logic clk,    // 100 MHz;
        input logic reset,  // async reset;
        
        /* specific to uart;
        Arguments:
        1. [input] programmable mod;
        2. [output] sampling tick; 
        ----------------------------
        Background;
        uart employs oversampling x16 of the actual baud rate;
        max baud rate supported is 921600;
        min baud rate supported is 110;
         
        1. programmable mod, M is used to determine the counter
        value for which to program the oversampling threshold;
        2. sampling tick is when the programmable-mod counter has wrapped around;
        
        with system clock freq, f and baud rate, b
        ==> max count, M = (f/(16* min(b)));
        * note that depending on whether to ignore the index
        offset which start from zero or not, M is off by +/- one;
        
        Calculation to determine how large the programmable mod should be:
        f = 100MHz;
        min(b) = 110
        ==> max(M) = 56.8k;
        ==> bits of M = log_2(M) = 9.15 ~= 10.00 
          */
        input logic [10:0] programmable_mod,        
        output logic sampling_tick
    );
    
    localparam COUNTER_WIDTH = 10;
    logic [COUNTER_WIDTH:0] cnt_reg;
    logic [COUNTER_WIDTH:0] cnt_next;
    
    // counter;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            cnt_reg <= 0;
        else
            cnt_reg <= cnt_next;
     
     // next state (mod arithmetic);
     // expired? reset; otherwise, keep increment;
     assign cnt_next = (cnt_reg == programmable_mod)? 0 : (cnt_reg + 1); 
     
     // output 
     // expired?
     // note that the module has one extra since we are not using;
     // cnt_reg == programmable_mod - 1 ; as cnt_reg starts from zero;
     assign sampling_tick = (cnt_reg == 1);
     
endmodule
