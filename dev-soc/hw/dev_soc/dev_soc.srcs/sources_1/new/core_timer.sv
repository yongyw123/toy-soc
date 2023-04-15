`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 03:02:15
// Design Name: 
// Module Name: core_timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  IO core, system timer for MCS;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef CORE_TIMER_SV
`define CORE_TIMER_SV

`include "IO_map.svh"

module core_timer/*
    * Purpose: System Timer Core for MicroBlaze MCS IO Module (Core);
    * Construction: 64-bit counter with clear, go control signals;
    * 
    * Addressing:
    *   0. each core is allocated 2^{5} internal registers;
    *   1. each register is 32-bit
    * 
    * Timer:
    *   1. only uses three registers;
    *
    * Register Map: 
    *   1. register 0 (offset 0): lower word of the counter;
    *   2. register 1 (offset 1): upper word of the counter;
    *   3. register 2 (offset 2): control register;  
    *
    *   Control Signals
    *   1. clear: a Pulse will reset the counter to zero; (important: Pulse);
    *   2. go: pause or resume the counting;    
    *    
    *   Control Register:
    *   1. Bit 0: go;
    *   2. Bit 1: clear;
    */
     
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,                 // chip select; not needed?
        input logic write,              
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data           
    );
    
    // signal declaration;
    localparam TOTAL_COUNT = 64;            // counter bit length;
    logic [TOTAL_COUNT - 1:0] count_curr;   // for counter;
    
    //logic [`G_CORE_ADDR_SIZE:0] test;
    
    
    
    // register map as noted above;
    localparam REG_CNTLOW_OFFSET = 2'b00;
    localparam REG_CNTHIGH_OFFSET = 2'b01;
    localparam REG_CTRL_OFFSET = 2'b10;
    localparam REG_CTRL_GO_POS = 1'b0;
    localparam REG_CTRL_CLEAR_POS = 1'b1;
    
    /*
    * note on control signals;
    * clear: requires a pulse; so do NOT use register to maintain the clear signal
    * go: contrary to clear; require memory; this requires registers;
    */
    
    logic ctrl_curr;  // to register the input control signal from the interfacse;      
    logic wr_en;      // to combine write and cs from the interfacel
    logic clear;      
    logic go;
    
    /* counter; */
    always_ff @(posedge clk, posedge reset)
        if(reset)
            count_curr <= 0;
        else
            if(clear)
                count_curr <= 0;
            else if(go)
                count_curr <= count_curr + 1;
                
    /* -----------  interface wrapper  -----------*/
    // register for go signal; this is explained above;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            ctrl_curr <= 0;
        else
            // only when requested;
            if(wr_en)
                // bit 0 is for the go signal;
                ctrl_curr <= wr_data[REG_CTRL_GO_POS];
   
   /* -------- decoding -----------*/
   
   /*
    three conditions to enable write operation
    1. write HIGH
    2. cs HIGH
    3. control register address matched;
        by above this is the third register, hence offset at 0x2;
    */
   assign wr_en = write && cs && (addr[1:0] == REG_CTRL_OFFSET);
  
   /* 
    construction of clear signal;
    1. bit 1 of the wr_data is for clear signal;
    2. clear is only applied as pulse; so no register;
    3. only applied as HIGH when requested (wr_en) and immediately
        transits to LOW when wr_en turns LOW;
        this forms a pulse;
   */ 
   assign clear = wr_en && wr_data[REG_CTRL_CLEAR_POS];
   
   // go signal, this is already handled by the register above;
   assign go = ctrl_curr;
   
   // counter value is always available;
   // as long as the register address is matched;
   // "read" input is not necessary;
   // recall that 64-bit counter is split into two 32-bit register;
   always_comb
        case(addr[1:0])
            REG_CNTLOW_OFFSET:  rd_data = count_curr[31:0]; // lowerword count;
            REG_CNTHIGH_OFFSET:  rd_data = {32'h0000, count_curr[63:32]};  // upperword count;
            default: ;  // do nothing;    
        endcase
endmodule

`endif // _CORE_TIMER_SV;