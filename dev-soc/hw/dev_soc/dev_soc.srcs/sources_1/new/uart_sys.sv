`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2023 00:06:52
// Design Name: 
// Module Name: uart_sys
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
Purpose: wrapper for uart Tx, Rx and its associated FIFO;

Intended Application:
1. serial debugging to the connected PC;

FIFO;
1. FIFO is necessary to serve as a buffer between the fpga and the PC:
2. One for uart tx, one for uart rx;
2. due to the mismatch in the speed of the two devices;

Synchronizer;
1. UART tx by nature is asynchronous
2. UART Tx itself has a FF double synchronizer in it to reduce metastability;
3. so not necessary to add here;

Tx Construction:
1. Data is buffered in the fifo before passed over to the UART Tx;
2. As long as FIFO is not empty, it will trigger UART Tx request;
3. UART Tx will read the data from the FIFO driven by its TX complete flag and (2);

Rx Construction:
1. UART Rx received data is buffered in the fifo;
2. UART Rx uses it rx_complete flag to write its data into the FIFO;
3. Note that FIFO full status is not passed into the UART RX;
4. so it may cause some data loss;

Disclaimer;
1. By above, there is a potential data loss in UART Tx, Rx;
2. This is by construction since there is no UART Control Flow;
3. To implement UART Control Flow, two extra pins are needed;
4. the pins are CTS , RTS pins;
5. Reference: https://www.silabs.com/documents/public/application-notes/an0059.0-uart-flow-control.pdf

Assumption:
1. data size is constant on both ends;
2. Tx and Rx;
 
*/

module uart_sys
    #(
        parameter 
        UART_DATA_BIT = 8,                   // number of data bits;
        UART_STOP_BIT_SAMPLING_NUM = 16,     // this corresponds to one stop bit; (16 oversampling);
        FIFO_ADDR_WIDTH = 2,            // FIFO addr size; its data
        FIFO_DATA_WIDTH = 8             // fifo data size;
    )
    (
        // general
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        // tx;
        input logic ctrl_wr,                // request write operation;
        input logic [UART_DATA_BIT-1:0] wr_data, // write to FIFO Tx;
        output logic tx,                          // output from UART tx;
        output logic tx_full,           // status; FIFO Tx is full;
        
        // rx;
        input logic ctrl_rd,                    // request rd operation;
        output logic [UART_DATA_BIT-1:0] rd_data,    // read from FIFO Rx;
        input logic rx,                 // input to UART Rx;
        output logic rx_empty,          // status; FIFO Rx is empty;
        
        /* baud rate generator; */
        // it has been established why 11-bit is allocated for the program value;
        // please see the baud_rate_generator module
        input logic [10:0] baud_rate_programmable_mod // programmable parameter;
        
    );
    
    /* signals; */
    // baud rate;
    logic baud_rate_common_sampling_tick;   // common baud rate tick to drive both uart tx, rx; 
    
    // tx;
    logic tx_fifo_empty;    
    logic tx_uart_start;
    logic tx_uart_complete_flag;
    logic [UART_DATA_BIT-1:0] tx_uart_din;
    
    // rx;
    logic rx_uart_complete_flag;
    logic [UART_DATA_BIT-1:0] rx_uart_dout;    

    /* baud rate generator; */
    baud_rate_generator baud_rate_unit
    (.clk(clk), 
    .reset(reset),
    .programmable_mod(baud_rate_programmable_mod),
    .sampling_tick(baud_rate_common_sampling_tick));

    /* Tx side; */
    // fifo for tx;
    FIFO #(.DATA_WIDTH(FIFO_DATA_WIDTH), .ADDR_WIDTH(FIFO_DATA_WIDTH))
    fifo_tx 
    (.clk(clk),
    .reset(reset),
    .ctrl_rd(tx_uart_complete_flag),  // prev UART tx complete means read next data to tx;
    .ctrl_wr(ctrl_wr),                // from interface;
    .flag_empty(tx_fifo_empty),     
    .flag_full(tx_full),            // for interface;
    .rd_data(tx_uart_din),          // in conjunction with tx_uart_complete_flag;
    .wr_data(wr_data));             // from interface;
    
    // uart tx;
    uart_tx #(.DATA_BIT(UART_DATA_BIT), .SAMPLING_STOP_BIT(UART_STOP_BIT_SAMPLING_NUM))
    uart_tx_unit
    (.clk(clk),
    .reset(reset),
    .tx_start(tx_uart_start), // when FIFO tx is not empty;
    .din(tx_uart_din),
    .baud_rate_tick(baud_rate_common_sampling_tick),
    .tx_complete_tick(tx_uart_complete_flag),
    .tx(tx));
    
    /* Rx side */
    // fifo for rx;
    FIFO #(.DATA_WIDTH(FIFO_DATA_WIDTH), .ADDR_WIDTH(FIFO_DATA_WIDTH))
    fifo_rx
    (.clk(clk),
    .reset(reset),
    .ctrl_rd(ctrl_rd),      // from interface;
    .ctrl_wr(rx_uart_complete_flag),    // driven by uart rx complete;
    .flag_empty(rx_empty),      // for interface;
    .flag_full(),               // not used as discussed in the disclaimer above;
    .rd_data(rd_data),          // for interface;
    .wr_data(rx_uart_dout));      // from uart rx;
        
    // uart rx;
    uart_rx #(.DATA_BIT(UART_DATA_BIT), .SAMPLING_STOP_BIT(UART_STOP_BIT_SAMPLING_NUM))
    uart_rx_unit
    (.clk(clk),
    .reset(reset),
    .rx(rx),        // from interface;
    .baud_rate_tick(baud_rate_common_sampling_tick),
    .rx_complete_tick(rx_uart_complete_flag),
    .dout(rx_uart_dout));

    
    /* some mapping */
    // fifo_tx non empty means there is something to UART tx;
    assign tx_uart_start = ~tx_fifo_empty;

endmodule
