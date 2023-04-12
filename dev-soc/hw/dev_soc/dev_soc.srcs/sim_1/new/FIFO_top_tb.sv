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

module FIFO_top_tb();
    
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // system clock;
    logic reset;        // async system clock;
    
    /* fifo module argument; */
    // fifo parameter;
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    
    // input;
    logic ctrl_rd;     // read request;
    logic ctrl_wr;     // write request;
    
    // output;
    logic flag_empty; // fifo status;
    logic flag_full;  // fifo status;
    
    // data;
    logic [DATA_WIDTH-1:0] rd_data; // output; 
    logic [DATA_WIDTH-1:0] wr_data; // input;

    /* instantiation */
    // uut;
    FIFO #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) uut(.*);
    
    // test stimulus from the test program;
    FIFO_tb tb(.*);
    
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
    
    // monitoring;
    initial begin
        /*
        note;
            not necessary to use assertions
            as these have been used in previous verification of the sub-modules;
        */
        
        $monitor("time: %0t, wr: %-0b, flag_full: %-0b, wr_data: %-0H, rd: %-0b, flag_empty: %-0b, rd_data: %-0H",
            $time,
            ctrl_wr,
            flag_full,
            wr_data,
            ctrl_rd,
            flag_empty,
            rd_data); 
    end
    
    
    
endmodule
