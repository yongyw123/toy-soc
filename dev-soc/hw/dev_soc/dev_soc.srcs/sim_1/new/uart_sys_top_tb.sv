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

test method:
1. loopback shall be used: uart tx output shall be uart rx input (within the same system);
2. this is for simplicity;
3. in this setting, asynchronicity of uart rx input could not be tested;
4. that said, asynchronicity test has been covered in the individual test bench for uart_rx module;
5. so, there should not be any loss in the test coverage;

Simulation Setting:
1. note that due to the test stimulus and the limited baud rate, the simulation time will take longer;
2. set it to maybe 30 millisecond in the vivado simulation setting;

alternative method;
1. if the above is not sufficient, one could have two uart_sys() module, say system A and system B;
2. each driven by different clock;
3. one uart tx of system A shall be fed into uart rx of system B and vice versa;
4. this is a more complete coverage that includes asynchronicity rx input stimules; 
*/

module uart_sys_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // constant parameters for uart system;
    localparam UART_DATA_BIT = 8;                   // number of data bits; 
    localparam UART_STOP_BIT_SAMPLING_NUM = 16;     // this corresponds to one stop bit; (16 oversampling);
    localparam FIFO_ADDR_WIDTH = 2; // FIFO addr size; its data     
    localparam FIFO_DATA_WIDTH = 8; // fifo data size;
    
    /* common baud rate, b for uart systems */
    // higher baud rate to shorten the simulation time;
    // but respect this constraint: b < 16*system_clk;
    //localparam baud_rate = 500000; // bits per second;
    localparam baud_rate = 5000000; // bits per second;
    localparam system_freq = 100000000;
    // programmable parameter;
    localparam baud_rate_programmable_mod = system_freq/(16*baud_rate); 
    
    // argument for uart system;
    logic ctrl_wr;    // input;
    logic [UART_DATA_BIT-1:0] wr_data;    // input;
    logic tx; // output;
    logic tx_full; // output;
    logic ctrl_rd;    // input;
    logic [UART_DATA_BIT-1:0] rd_data; // output;
    logic rx;     // input;
    logic rx_empty;   // output;
            
    
    /* instantiation */
    
    uart_sys
     #(.UART_DATA_BIT(UART_DATA_BIT),
     .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
     .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
     .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH))
    system
    (
        .clk(clk),
        .reset(reset),
        .ctrl_wr(ctrl_wr),
        .wr_data(wr_data),
        .tx(tx),
        .tx_full(tx_full),
        .ctrl_rd(ctrl_rd),
        .rd_data(rd_data),
        .rx(tx),  
        .rx_empty(rx_empty),
        .baud_rate_programmable_mod(baud_rate_programmable_mod)
    );
        
    // test stimulus;
    uart_sys_tb
    #(.UART_DATA_BIT(UART_DATA_BIT),
     .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
     .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
     .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH))
     
     tb(.*);
    
    
    /* simulate common system clk;*/
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
    
    // monitoring for uart system ;
    initial 
    begin
        $monitor("time: %0t, wr: %-0b, wr_data: %-0B, tx: %-0b, rd: %-0b, rd_data: %-0B, rx: %-0b, tx_full: %-0b, rx_empty: %-0b",
        $time,
        ctrl_wr,
        wr_data,
        tx,
        ctrl_rd,
        rd_data,
        rx,
        tx_full,
        rx_empty);     
    end
endmodule
