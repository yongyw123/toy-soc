`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 18:03:40
// Design Name: 
// Module Name: disp_hex_mux_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test circuit for disp_mux_hex where 4 sseg displays are used;
//      1. add two input numbers (represented by 4 switches each)
//      2. show each input number on each sseg;
//      3. show the sum (inc carry) on two sseg; 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module disp_hex_mux_test(
    input logic CLK,            // 100MHz;
    input logic [7:0] SW,       // switches
    output logic [3:0] AN,      // sseg display enable;
    output logic [7:0] SSEG    // sseg
    );
    
    // declare;
    logic [3:0] sum_op0, sum_op1;    
    logic [7:0] sum_out;
    
    // uut;
    disp_hex_mux #(.N(18)) uut (.clk(CLK), .reset(1'b0), 
                            .hex0(sum_op0), .hex1(sum_op1),
                            .hex2(sum_out[3:0]), 
                            .hex3(sum_out[7:4]),
                            .dp_in(4'b1010),    // decimal point; not important; use dummy val;   
                            .an(AN),
                            .sseg(SSEG));
                         
   // adder;
   assign DP = 4'b1010; 
   assign sum_op0 = SW[3:0];
   assign sum_op1 = SW[7:4];
   // all unsigned, pad;
   assign sum_out = {4'b0000, sum_op0} + {4'b0000, sum_op1};  

endmodule
