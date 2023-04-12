`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2023 01:41:32
// Design Name: 
// Module Name: uart_sys_tb
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


/*
purpose: program fro uart_sys_top_tb.sv
*/

program uart_sys_tb
    #(
        parameter 
        UART_DATA_BIT = 8,                   // number of data bits;
        UART_STOP_BIT_SAMPLING_NUM = 16,     // this corresponds to one stop bit; (16 oversampling);
        FIFO_ADDR_WIDTH = 2,            // FIFO addr size; its data
        FIFO_DATA_WIDTH = 8             // fifo data size;
    )
   (
        input logic clk,
        // uart system;
        output logic ctrl_rd,
        output logic ctrl_wr,
        output logic [UART_DATA_BIT-1:0] wr_data,
        input logic rx_empty,
        input logic tx_full
    );
    
    /* reminder:
        1. there is no UART control flow using CTS and RTS;
        2. so there will be data loss if UART Rx FIFO is full but kept being driven;
        3. as such, this will not be tested
        */
        
    initial begin
        /* test 01: tx from system A and rx from system B*/
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        
        // UART Tx of system A;
        // write until fifo is full but not beyond;
        //for(int i = 0; i < 2**FIFO_ADDR_WIDTH; i++) begin
        for(int i = 0; i < 1; i++) begin
            @(posedge clk)
            ctrl_wr <= 1'b1;
            wr_data = (UART_DATA_BIT)'($random);
        end
        @(posedge clk);
        @(posedge ~tx_full);
        
   $display("DONE");
   #(20);
   //$finish;
   end 
endprogram
