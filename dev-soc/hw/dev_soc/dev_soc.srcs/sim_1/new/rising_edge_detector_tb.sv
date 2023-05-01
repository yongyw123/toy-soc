`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 00:30:43
// Design Name: 
// Module Name: rising_edge_detector_tb
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


program rising_edge_detector_tb
    (
        input logic clk,
        output logic level,
        input logic detected
    );
    
    initial begin
        level = 1'b1;
        #(100);
        
        //normal stimulus?
        @(negedge clk);
        level = 1'b0;
        
        @(negedge clk);
        level = 1'b1;
        
        // expect that the detector may or may not
        // be able to detect the edge;
        level = 1'b0;
        #(1);
        level = 1'b1;
        
        // expect that here the detector will NOT detect the rising edge;
        // because the rising edge occurs within a clock cycle;
        // beyond the "sampling capability" of the system;    
        #(10);
        level = 1'b0;
        #(7);
        level = 1'b1;
    
        #(50);
        level = 1'b0;
        #(10);
        level = 1'b1;
        #(50);
        level = 1'b0;
        @(negedge clk);
        level = 1'b1;
        
        #(50);
        
        $stop;
    end
        
endprogram
