`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 15:34:08
// Design Name: 
// Module Name: mcs_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: main system (SoC) to be driven by the SW;
//      1. contain the mircoblaze cpu ip-generated;
//      2. bridge between ublaze mcs io bus and the user-space bus;
//      3. mmio controller; interface between ublaze processor and io cores;
//      4. already-constructed io cores;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef _MCS_TOP_SV
`define _MCS_TOP_SV

`include "IO_map.svh"

module mcs_top
    // this is given the datasheet of the microblaze;
    //#(parameter MCS_BRIDGE_BASE_ADDR = `BUS_MICROBLAZE_IO_BASE_ADDR_G)    
    (
        input logic clk,        // 100 MHz;
        input logic reset_n,     // async, active low;
        
        // external mapping from boards;
        input logic [15:0] SW,
        output logic [15:0] LED
    );
    
    // general;
    logic reset_sys;    // to invert the input reset;
    
    // mcs io bus signals; these are fixed;
    logic io_addr_strobe;   // output wire IO_addr_strobe
    logic [31:0] io_address;       // output wire [31 : 0] IO_address
    logic [3:0] io_byte_enable;   // output wire [3 : 0] IO_byte_enable
    logic [31:0] io_read_data;     // input wire [31 : 0] IO_read_data
    logic io_read_strobe;   // output wire IO_read_strobe
    logic io_ready;         // input wire IO_ready
    logic [31:0] io_write_data;    // output wire [31 : 0] IO_write_data
    logic io_write_strobe;  // output wire IO_write_strobe
    
    // user-bus signals after bridging;
    logic user_mmio_cs;
    logic user_wr;
    logic user_rd;
    logic [31:0] user_wr_data;
    logic [31:0] user_rd_data;
    logic [`BUS_USER_SIZE_G-1:0] user_addr;
    
    // conform the signals;
    assign reset_sys = !reset_n;    // inverted;
    
    /* -------------------
    instantiation;
    1. cpu;
    2. bridge between microblaze io bus and user bus;
    3. mmio system (where all the io cores reside);
    -----------------*/
    
    // cpu
    microblaze_mcs_cpu cpu_unit(
      .Clk(clk),                          // input wire Clk
      .Reset(reset_sys),                      // input wire Reset
      .IO_addr_strobe(io_addr_strobe),    // output wire IO_addr_strobe
      .IO_address(io_address),            // output wire [31 : 0] IO_address
      .IO_byte_enable(io_byte_enable),    // output wire [3 : 0] IO_byte_enable
      .IO_read_data(io_read_data),        // input wire [31 : 0] IO_read_data
      .IO_read_strobe(io_read_strobe),    // output wire IO_read_strobe
      .IO_ready(io_ready),                // input wire IO_ready
      .IO_write_data(io_write_data),      // output wire [31 : 0] IO_write_data
      .IO_write_strobe(io_write_strobe)  // output wire IO_write_strobe
    );

    // bridge;
    mcs_bus_bridge 
    bridge_unit(.mcs_bridge_base_addr(BUS_MICROBLAZE_IO_BASE_ADDR_G), .*);
    
    // mmio system;
    mmio_sys #(.SW_N(16), .LED_N(16)) 
    mmio_unit
    (
        .clk(clk),
        .reset(reset_sys),
        .mmio_addr(user_addr),
        .mmio_cs(user_mmio_cs),
        .mmio_wr(user_wr),
        .mmio_rd(user_rd),
        .mmio_wr_data(user_wr_data),
        .mmio_rd_data(user_rd_data),
        .sw(SW),
        .led(LED)    
    );
    
endmodule

`endif // _MCS_TOP_SV;