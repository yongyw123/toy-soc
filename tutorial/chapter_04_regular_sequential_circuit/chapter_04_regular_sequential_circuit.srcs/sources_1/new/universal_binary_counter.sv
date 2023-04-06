`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 15:19:33
// Design Name:  
// Module Name: universal_binary_counter
// Project Name: 
// Target Devices: nexys a7 50T 
// Tool Versions: 
// Description: universal binary counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// Acknowledgement
// 1. this is an example from the Pong P. Chu' Book
// 2. chapter 4.0
//////////////////////////////////////////////////////////////////////////////////


module universal_binary_counter
    #(parameter N = 8)
    (
        input logic clk,            // assummed 100MHz
        input logic reset,          // asyn reset;
        input logic syn_clr,        // clear the counter;
        input logic load,           // load the counter with a value;
        input logic en,             // enable the counter;
        input logic up,             // count up if HIGH, otherwise count down;
        input logic [N-1:0] d,    // data to load
        output logic max_flag,      // flag if the counter overflows;
        output logic min_flag,      // flag if the counter underflows;
        output logic [N-1:0] q     // counter output;
    );
    
    // declaration;
    logic [N-1:0] reg_current, reg_next;
    
    // register;
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            reg_current <= 0;
        else
            reg_current <= reg_next;  
    end
    
    // next state logic;
    always_comb 
    begin
        if(syn_clr)
            reg_next  = 0;
        else if(load)
            reg_next = d;
        // only start counting if enabled;
        else if(en & up)
            reg_next  = reg_current + 1;
        // count down
        else if(en & ~up)
            reg_next  = reg_current - 1;
        else
            reg_next = reg_current;
    end
    
    // output logic
    assign q = reg_current;
    assign max_flag  = (reg_current == 2**N-1) ? 1'b1 : 1'b0;   // overflow;
    assign min_flag  = (reg_current == 0) ? 1'b1 : 1'b0;    // underflow;
    
endmodule
