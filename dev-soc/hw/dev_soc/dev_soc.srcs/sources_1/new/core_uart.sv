`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2023 18:27:28
// Design Name: 
// Module Name: core_uart
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

`ifndef CORE_UART_SV
`define CORE_UART_SV

`include "IO_map.svh"

/*
    * Purpose: UART Core for MicroBlaze MCS IO Module (Core);
    * Construction: UART Tx and Rx without error parity and without CTS/RTS flow control;
    * 
    * Addressing:
    *   0. each core is allocated 2^{5} internal registers;
    *   1. each register is 32-bit
    * 
    * Uart:
    *   1. uses five registers
    *
    UART core has five registers;
    
    Register Map
    1. register 01 (offset 0): status register      
    2. register 02 (offset 1): baud rate setting divisor;
    3. register 03 (offset 2): Tx (write) request register;
    4. register 04 (offset 3): Rx (read-and-pop) request (control) register;
    5. register 05 (offset 4): Rx Data;
            
    Register Definition:
    1. register 01: Status Register
        bit 0 - UART Rx FIFO buffer Empty Status
        bit 1 - UART Tx FIFO buffer Full Status
    2. register 02: baud rate;
        where bit[10:0] is allocated to store
        the value to program the baud rate;
    3. register 03: Tx write request;
        to put the wr_data on the bus for UART Tx;
    4. register 04: Rx read request;
        where UART Rx FIFO requires a read requeat
            to get the data pointed and update the pointer
            to the next data;
    5. register 05: Rx data;
        data popped by the read request from the register above;
    
    Register IO Access;
    1. Status Register              - Read Only
    2. Baud Rate Setting Divisior   - Write Only
    3. Tx Write Request Register    - Write Only
    4. Rx Request Register          - Write Only;
    5. Read Data Register           - Read Only;   
    */
    
module core_uart
    #(
        parameter 
        UART_DATA_BIT = 8,                  // number of UART data bits;
        UART_STOP_BIT_SAMPLING_NUM = 16,    // this corresponds to one stop bit; (16 oversampling);
        FIFO_ADDR_WIDTH = 8,                // FIFO addr size, N; it could up to 2**{N}
        FIFO_DATA_WIDTH = UART_DATA_BIT     // fifo data size; must be the same as uart data bit;
    )
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // uart specific - external pin
        // refer to the constraint map;
        output logic tx,    // connected to UART Rx
        input logic rx     // UART Rx; 
     );
     
     // deocded request;
     logic uart_rq_wr;      // write request;
     logic uart_rq_rd;      // read request;
     logic uart_rq_baud_rate_set;    // request to program the baud rate;

     // data;
     logic[UART_DATA_BIT-1:0] uart_rd_data;
       
     /* constanst; */
     // it has been established why 11 bits are required to hold the baud rate program value;
     // please refer to the baud_rate_gen() module;
     localparam BAUD_RATE_BIT_WIDTH = 10;   
     
     // status flags;
     logic tx_full;
     logic rx_empty;
     
     /* registers;
     as noted; we have five registers;
     but only baud rate requires explict register in this module;
     because all other registers have already been created in the sub modules
     */
     logic [10:0] baud_rate_reg;    // to hold baud rate programmaed value;
     
     /* instantiation */
     // main system
     uart_sys 
     #(
        .UART_DATA_BIT(UART_DATA_BIT),
        .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
        .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
    ) main_system
    (
        // general;
        .clk(clk),
        .reset(reset),
        // tx;
        .ctrl_wr(uart_rq_wr),
        .wr_data(wr_data[UART_DATA_BIT-1:0]),
        .tx(tx),
        .tx_full(tx_full),
        
        // rx;
        .ctrl_rd(uart_rq_rd),
        .rd_data(uart_rd_data),
        .rx(rx),
        .rx_empty(rx_empty),
        
        // baud rate;
        .baud_rate_programmable_mod(baud_rate_reg)
    );
     
     
     // register for baud rate;
     always_ff @(posedge clk, posedge reset)
        if(reset) 
            baud_rate_reg <= 0; // baud rate generator is disabled;
        else begin
            if(uart_rq_baud_rate_set)
                baud_rate_reg <= wr_data[BAUD_RATE_BIT_WIDTH:0];
        end
             
    // decoding the instruction address;
    assign uart_rq_baud_rate_set = (write && cs && (addr[2:0] == `S1_UART_REG_BAUD_OFFSET));
    assign uart_rq_wr = (write && cs && (addr[2:0] == `S1_UART_REG_TX_WRITE_REQUEST_OFFSET));
    assign uart_rq_rd = (write && cs && (addr[2:0] == `S1_UART_REG_RX_READ_REQUEST_OFFSET));
    
    // multiplexing for read interfacce;
    always_comb
        case(addr[2:0])
            // extend to 32-bit to conform to the native register width: 32-bit wide;
            `S1_UART_REG_STATUS_OFFSET: rd_data = {30'h0000_0000, tx_full, rx_empty};
            `S1_UART_REG_RX_READ_DATA_OFFSET: rd_data = {`REG_DATA_WIDTH_G'(uart_rd_data)};
            default: rd_data = {`REG_DATA_WIDTH_G'(uart_rd_data)};
        endcase
endmodule


`endif // CORE_UART_SV