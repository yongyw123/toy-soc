`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 21:52:53
// Design Name: 
// Module Name: video_sys
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

`ifndef _VIDEO_SYS_SV
`define _VIDEO_SYS_SV

`include "IO_map.svh"

module video_sys
    #(
        parameter BITS_PER_PIXEL = 16   // bpp;
    )
    (
        // general;
        input logic clk_sys,    // 100 MHz;
        input logic reset,  // async;
        
        /*
        // user bus interface;
        // where user bus is bridged by the microblaze MCS IO bus;
 
        */
        input logic video_cs,        // chip select for mmio system;
        input logic video_wr,
        input logic video_rd,
        input logic [`BUS_USER_SIZE_G-1:0] video_addr,       // addr to decode for IO core address and its register address;
        input logic [`REG_DATA_WIDTH_G-1:0] video_wr_data,   // 32-bit;
        output logic [`REG_DATA_WIDTH_G-1:0] video_rd_data  // 32-bit;
        
        /* HW pin mapping (by the constraint file) */
    );
    // pre cal constants;  
    localparam VIDEO_CORE_NUM_TOTAL = `VIDEO_CORE_TOTAL_G; 
    localparam VIDEO_CORE_BIT_SIZE = $clog2(VIDEO_CORE_NUM_TOTAL);
    localparam VIDEO_REG_BIT_TOTAL = `VIDEO_REG_ADDR_BIT_SIZE_G;    // 19 bit;
    localparam REG_DATA_WIDTH = `REG_DATA_WIDTH_G;  // 32 bit;
  
    /* ----- broadcasting arrays; */
    // individual control signals for each core;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_cs_array; // chip select;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_wr_array; // write enable; 
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_rd_array; // read enable;
    
    // input, output, and register data for each core;
    logic [VIDEO_REG_BIT_TOTAL-1:0] core_addr_reg_array[VIDEO_CORE_NUM_TOTAL-1:0]; // register of each core;
    logic [REG_DATA_WIDTH-1:0] core_data_rd_array[VIDEO_CORE_NUM_TOTAL-1:0]; // read data from each core;
    logic [REG_DATA_WIDTH-1:0] core_data_wr_array[VIDEO_CORE_NUM_TOTAL-1:0]; // write data from each core;
    
    /* instantiation */
    // controller;
    video_ctrl ctrl_unit
    (
        .clk(clk),
        .reset(reset),
        
        // system control sigmals;
        .video_cs(video_cs),  
        .video_rd(video_rd),
        .video_wr(video_wr),
        
        // address to decode;
        .video_addr(video_addr),
        
        // data;
        .video_wr_data(video_wr_data),
        .video_rd_data(video_rd_data),
        
        // broadcaster to all io cores;
        .core_ctrl_cs_array(core_ctrl_cs_array),    // chip select for each core;    
        .core_ctrl_wr_array(core_ctrl_wr_array),    // write enable for each core;
        .core_ctrl_rd_array(core_ctrl_rd_array),    // read enable for each core;
        .core_data_wr_array(core_data_wr_array),    // write data;
        .core_data_rd_array(core_data_rd_array),    // data to multiplex
        .core_addr_reg_array(core_addr_reg_array)    // register address to decode;      
    );
    
    
    /* ground the the read data signals from the unconstructed video cores 
    for vivao synthesis optimization to opt out these unused signals */
    generate
        genvar i;
            for(i = 7; i < VIDEO_CORE_NUM_TOTAL; i++)
            begin
                // always HIGH ==> idle ==> not signals;
                assign core_data_rd_array[i] = 32'hFFFF_FFFF;
            end
        endgenerate

    
endmodule


`endif //_VIDEO_SYS_SV