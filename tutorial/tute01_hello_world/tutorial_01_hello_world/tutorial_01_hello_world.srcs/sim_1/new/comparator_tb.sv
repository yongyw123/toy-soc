`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2023 02:33:48
// Design Name: 
// Module Name: comparator_tb
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


module comparator_tb;
    // signal declaration;
    reg [1:0] in0, in1;
    wire out;
    
    // uut;
    comp_two_bit uut(.a(in0), .b(in1), .out(out));
    
    // test machinery;
    initial
    begin
        // set 01;
        in0 = 2'b00;
        in1 = 2'b00;
        #200;
        
        // set 02;
        in0 = 2'b01;
        in1 = 2'b00;
        #200;
        
        // set 03;
        in0 = 2'b00;
        in1 = 2'b01;
        #200;
        
        // set 04;
        in0 = 2'b01;
        in1 = 2'b01;
        #200;
        
        // set 05;
        in0 = 2'b11;
        in1 = 2'b00;
        #200;
        
        // set 06;
        in0 = 2'b11;
        in1 = 2'b10;
        #200;
        
        // set 07;
        in0 = 2'b11;
        in1 = 2'b11;
        #200;
        
        
        $stop;
        
        
        
    
    end
    
    
endmodule
