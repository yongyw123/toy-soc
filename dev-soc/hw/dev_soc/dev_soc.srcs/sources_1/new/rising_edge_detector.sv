`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 00:26:27
// Design Name: 
// Module Name: rising_edge_detector
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


module rising_edge_detector
    (
        // general;
        input logic clk,    
        input logic reset,  // async 
        
        // input;
        input logic level,
        
        // output;
        output logic detected
    );
    
    logic delayed_reg;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            delayed_reg <= 1'b0;
        else    
            delayed_reg <= level;
    
    // output;
    // rising edge detected;
    // if previous level is low and current level is high
    assign detected = !delayed_reg && level;
endmodule
