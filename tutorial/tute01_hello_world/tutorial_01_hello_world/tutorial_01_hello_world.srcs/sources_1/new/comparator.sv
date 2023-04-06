`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2023 01:23:32
// Design Name: 
// Module Name: comparator
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


module comparator_top(
    input logic [3:0] SW,
    input logic clk,
    output logic LED
    );
    
    logic p0;
    logic p1;
    always_ff @(posedge clk)
    begin
        p0 <= p1;
    end
    
    comp_two_bit uut(.a(SW[3:2]), .b(SW[1:0]), .out(LED));
    
endmodule

module comp_one_bit
(
    input logic i0, i1,
    output logic eq
);

    logic p0, p1;
    
    assign p0 = ~i0 & ~i1;
    assign p1 = i0 & i1;
    
    assign eq = p0|p1;
endmodule
 
module comp_two_bit
(
    input logic[1:0] a, b,
    output logic out
);
    logic e0, e1;
    comp_one_bit unit0(.i0(a[0]), .i1(b[0]), .eq(e0));
    comp_one_bit unit1(.i0(a[1]), .i1(b[1]), .eq(e1));
    
    assign out = e0 & e1;
    
endmodule 