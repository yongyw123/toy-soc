`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2023 16:50:06
// Design Name: 
// Module Name: FIFO_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for FIFO module; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FIFO_tb();
    
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // system clock;
    logic reset;        // async system clock;
    
    /* fifo module argument; */
    // fifo parameter;
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    
    // input;
    logic rd;     // read request;
    logic wr;     // write request;
    
    // output;
    logic empty; // fifo status;
    logic full;  // fifo status;
    
    // data;
    logic [DATA_WIDTH-1:0] rd_data; // output; 
    logic [DATA_WIDTH-1:0] wr_data; // input;

    /* instantiation */
    FIFO #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) uut(.*);
    
    /* simulate system clk;*/
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // apply reset;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
    end
    
    
    // test;
    initial
    begin
        for(int i = 0; i < 2**ADDR_WIDTH; i++) begin
            ?? (DATA_WIDTH)'(i + $random);
        
        end     
        
    
    
    end
    
    
    
endmodule
