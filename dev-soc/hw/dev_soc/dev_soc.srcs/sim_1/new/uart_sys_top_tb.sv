`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2023 01:00:11
// Design Name: 
// Module Name: uart_sys_top_tb
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
purpose: to test uart_sys() module;

background:
1. uart_sys() is a complete system consisting uart tx, rx and their fifos;
2. also, uart rx, by nature must be asynchronous;
3. so to test this system, we instantiate two same uart_sys();
4. tx output from system A is the rx input for system B and vice versae;
5. to simulate async rx; system A and system B is driven by different clocks; 
*/
module uart_sys_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // system clock;
    logic reset;        // async system clock;
    
    // constant parameters for uart system;
    localparam UART_DATA_BIT = 8;                   // number of data bits; 
    localparam UART_STOP_BIT_SAMPLING_NUM = 16;     // this corresponds to one stop bit; (16 oversampling);
    localparam FIFO_ADDR_WIDTH = 2; // FIFO addr size; its data     
    localparam FIFO_DATA_WIDTH = 8; // fifo data size;
    
    /* common baud rate, b for uart systems */
    // higher baud rate to shorten the simulation time;
    // but respect this constraint: b < 16*system_clk;
    localparam baud_rate = 500000; // bits per second;
    localparam system_freq = 100000000;
    // programmable parameter;
    localparam baud_rate_programmable_mod = $(ceil((system_freq/(16*baud_rate) - 1)); 
    
    // argument for uart system A;
    logic clk_A;
    logic reset_A;
    logic ctrl_wr_A;    // input;
    logic [UART_DATA_BIT-1:0] wr_data_A;    // input;
    logic tx_A; // output;
    logic tx_full_A; // output;
    logic ctrl_rd_A;    // input;
    logic [UART_DATA_BIT-1:0] rd_data_A;    // output;
    logic rx_empty_A;   // output;
            
    // argument for uart system B;
    logic clk_B;
    logic reset_B;
    logic ctrl_wr_B;    // input;
    logic [UART_DATA_BIT-1:0] wr_data_B;    // input;
    logic tx_B; // output;
    logic tx_full_B; // output;
    logic ctrl_rd_B;    // input;
    logic [UART_DATA_BIT-1:0] rd_data_B;    // output;
    logic rx_empty_B;   // output;
    
    /* instantiation */
    
    // system A;
    uart_sys
     #(.UART_DATA_BIT(UART_DATA_BIT),
     .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
     .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
     .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH))
    system_A
    (
        .clk(clk_A),
        .reset(reset_A),
        .ctrl_wr(ctrl_wr_A),
        .wr_data(wr_data_A),
        .tx(tx_A),
        .tx_full(tx_full_A),
        .ctrl_rd(ctrl_rd_A),
        .rd_data(rd_data_A),
        .rx(tx_B),  // from system A;
        .rx_empty(rx_empty_A),
        .baud_rate_programmable_mod(baud_rate_programmable_mod)
    );
        
    // system B;
    uart_sys
     #(.UART_DATA_BIT(UART_DATA_BIT),
     .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
     .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
     .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH))
    system_B
    (
        .clk(clk_B),
        .reset(reset_B),
        .ctrl_wr(ctrl_wr_B),
        .wr_data(wr_data_B),
        .tx(tx_B),
        .tx_full(tx_full_B),
        .ctrl_rd(ctrl_rd_B),
        .rd_data(rd_data_B),
        .rx(tx_A),  // from system B;
        .rx_empty(rx_empty_B),
        .baud_rate_programmable_mod(baud_rate_programmable_mod)
    );
    
    
    
    /* simulate system clk A;*/
    always
    begin 
       clk_A = 1'b1;  
       #(T/2); 
       clk_A = 1'b0;  
       #(T/2);
    end

    /* simulate system clk B;*/
    always
    begin 
       clk_B = 1'b0;  
       #(T/2); 
       clk_B = 1'b1;  
       #(T/2);
    end
    
    // apply reset;
    initial
    begin
        reset_A = 1'b1;
        reset_B = 1'b1;
        #(T/2);
        reset_A = 1'b0;
        reset_B = 1'b0;
        #(T/2);
    end
    
    // monitoring for system A;
    initial 
    begin
        $monitor("A - time: %0t, wr: %-0b, wr_data: %-0H, rd: %-0b, rd_data: %-0H, tx_full: %-0b, rx_empty: %-0b",
        $time,
        ctrl_wr_A,
        wr_data_A,
        ctrl_rd_A,
        rd_data_A,
        tx_full_A,
        rx_empty_A);     
    end

    // monitoring for system B;
    initial 
    begin
        $monitor("B - time: %0t, wr: %-0b, wr_data: %-0H, rd: %-0b, rd_data: %-0H, tx_full: %-0b, rx_empty: %-0b",
        $time,
        ctrl_wr_B,
        wr_data_B,
        ctrl_rd_B,
        rd_data_B,
        tx_full_B,
        rx_empty_B);     
    end
        
    
endmodule
