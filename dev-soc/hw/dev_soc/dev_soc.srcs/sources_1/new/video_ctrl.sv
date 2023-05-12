`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 21:12:04
// Design Name: 
// Module Name: video_ctrl
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
`ifndef _VIDEO_CTRL_SV
`define _VIDEO_CTRL_SV

`include "IO_map.svh"

module video_ctrl
    /*
    // Purpose: VIDEO controller;
    // Note: construction is similar to MMIO controller except that
    //          the address space is different; 
    //
    // Construction -  video register map:
    // 1. it has 8 video cores;
    // 2. each core has 19-bit space allocated to it;
    // 
    // Mechanism - video controller:
    // 1. interface between the processor and the video cores via bus;
    // 2. this controller decodes the core address to find which core is requested;
    // 3. after (2), this controller decodes the register address of the corresponding core;
    */
    
    (
    
     // bus interface here the bus signals are "mapped/converted" from the microblaze mcs;
    input logic clk,                    // 100 MHz;
    input logic reset,                  // async;
    // control signals;
    input logic video_cs,                // to select the video system?
    input logic video_wr,                // to write;
    input logic video_rd,                // to read;
    
    // address;
    input logic [`BUS_USER_SIZE_G-1:0] video_addr,       // addr to decode;
    // data;
    input logic [`REG_DATA_WIDTH_G-1:0] video_wr_data,  // 32 bit;
    output logic [`REG_DATA_WIDTH_G-1:0] video_rd_data, // 32-bit;
     
    /* core interface; */
    output logic [`VIDEO_CORE_TOTAL_G-1:0] core_ctrl_cs_array, // chip select;
    output logic [`VIDEO_CORE_TOTAL_G-1:0] core_ctrl_wr_array, // write enable; 
    output logic [`VIDEO_CORE_TOTAL_G-1:0] core_ctrl_rd_array, // read enable;
    
    // input, output, and register data for each core;
    output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] core_addr_reg_array[`VIDEO_CORE_TOTAL_G-1:0], // register of each core;
    input logic [`REG_DATA_WIDTH_G-1:0] core_data_rd_array[`VIDEO_CORE_TOTAL_G-1:0], // read data from each core;
    output logic [`REG_DATA_WIDTH_G-1:0] core_data_wr_array[`VIDEO_CORE_TOTAL_G-1:0] // write data from each core;
    

    );
    
    // pre cal constants;  
    localparam VIDEO_CORE_NUM_TOTAL = `VIDEO_CORE_TOTAL_G; 
    localparam VIDEO_CORE_BIT_SIZE = $clog2(VIDEO_CORE_NUM_TOTAL);
    localparam VIDEO_REG_BIT_TOTAL = `VIDEO_REG_ADDR_BIT_SIZE_G;
    
    localparam VIDEO_CORE_START_INDEX   = VIDEO_REG_BIT_TOTAL;
    localparam VIDEO_CORE_END_INDEX     = VIDEO_CORE_BIT_SIZE + VIDEO_CORE_START_INDEX;
    
    // signal;
    logic [VIDEO_CORE_BIT_SIZE-1:0] core_addr;  // to identify which video core?
    logic [VIDEO_REG_BIT_TOTAL-1:0] reg_addr;   // which register for a given core?
    
    // separate the video addr into its constituent component;
    assign core_addr = video_addr[VIDEO_CORE_END_INDEX : VIDEO_CORE_START_INDEX];
    assign reg_addr = video_addr[(VIDEO_REG_BIT_TOTAL-1):0];
     
    // decoding;
    always_comb
    begin
        core_ctrl_cs_array = 0; // by default; no core is requested;
        
        // by construction, only one core could be requested at a time;
        if(video_cs)
            core_ctrl_cs_array[core_addr] = 1;        
    end
    
    // broadcast to all cores;
    // this is by bus construction;
    // only the one that is decoded above will respond;
    generate
        genvar i;
        for(i = 0; i < VIDEO_CORE_NUM_TOTAL; i++) begin
            assign core_ctrl_rd_array[i]    = video_rd;
            assign core_ctrl_wr_array[i]    = video_wr;
            assign core_data_wr_array[i]    = video_wr_data;
            assign core_addr_reg_array[i]   = reg_addr;        
        end    
    endgenerate
    
    // multiplexing for reading;
    assign video_rd_data = core_data_rd_array[core_addr]; 
     
endmodule


`endif //_VIDEO_CTRL_SV