`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 18:01:22
// Design Name: 
// Module Name: mimo_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: mmio controller
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef _MIMO_CTRL_SV
`define _MIMO_CTRL_SV

`include "IO_map.svh"

module mmio_ctrl
    /*
    // Purpose: MMIO controller; 
    //
    // Construction -  mmio register map:
    // 1. 2^{6} = 64 cores are allocated in mmio;
    // 2. each core has 2^{5} = 32 internal registers;
    // 
    // Mechanism - mmio controller:
    // 1. interface between the processor and the mmio cores via bus;
    // 2. this controller decodes the core address to find which core is requested;
    // 3. after (2), this controller decodes the register address of the corresponding core;
    */
    (
    /* 
        bus interface; 
     where the bus signals are "mapped/converted" from the microblaze mcs;
    */
    input logic clk,                    // 100 MHz;
    input logic reset,                  // async;
    // control signals;
    input logic mmio_cs,                // to select the mimo system (map);
    input logic mmio_wr,                // to write;
    input logic mmio_rd,                // to read;
    // address;
    input logic [`BUS_USER_SIZE_G-1:0] mmio_addr,       // addr to decode;
    // data;
    input logic [`REG_DATA_WIDTH_G-1:0] mmio_wr_data,  // 32 bit;
    output logic [`REG_DATA_WIDTH_G-1:0] mmio_rd_data, // 32-bit;
     
    /* core interface; */
    // individual control signals for each core;
    output logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_cs_array, // chip select;
    output logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_wr_array, // write enable; 
    output logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_rd_array, // read enable;
    
    // input, output, and register data for each core;
    output logic [`REG_ADDR_SIZE_G-1:0] core_addr_reg_array[`MIMO_CORE_TOTAL_G-1:0], // register of each core;
    input logic [`REG_DATA_WIDTH_G-1:0] core_data_rd_array[`MIMO_CORE_TOTAL_G-1:0], // read data from each core;
    output logic [`REG_DATA_WIDTH_G-1:0] core_data_wr_array[`MIMO_CORE_TOTAL_G-1:0] // write data from each core;
    );
    
    /* recall
    * 1. not all bus address is used; to grab those that are relevant;
    * 2. address to decode: c5_c4_c3_c2_c1_c0__r4_r3_r2_r1_r0;
            wheere c represents the core;
            where r represents the register;
    */
    localparam core_boundary = `MIMO_ADDR_SIZE_G;
    localparam reg_boundary = `REG_ADDR_SIZE_G; 
    logic[core_boundary-1:0] core_addr;
    logic [reg_boundary-1:0] reg_addr;
    assign core_addr = mmio_addr[(core_boundary + reg_boundary)-1 : reg_boundary];
    assign reg_addr = mmio_addr[reg_boundary-1 : 0];
    
    // decoding;
    always_comb
    begin
        core_ctrl_cs_array = 0; // by default; no core is requested;
        
        // by construction, only one core could be requested at a time;
        if(mmio_cs)
            core_ctrl_cs_array[core_addr] = 1;        
    end
    
    // broadcast to all cores;
    // this is by bus construction;
    // only the one that is decoded above will respond;
    generate
        genvar i;
        for(i = 0; i < `MIMO_CORE_TOTAL_G; i++) begin
            assign core_ctrl_rd_array[i] = mmio_rd;
            assign core_ctrl_wr_array[i] = mmio_wr;
            assign core_data_wr_array[i] = mmio_wr_data;
            assign core_addr_reg_array[i] = reg_addr;        
        end    
    endgenerate
    
    // multiplexing for reading;
    assign mmio_rd_data = core_data_rd_array[core_addr];
endmodule

`endif // _MIMO_CTRL_SV;

