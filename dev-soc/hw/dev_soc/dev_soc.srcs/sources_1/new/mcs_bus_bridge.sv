`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 02:11:14
// Design Name: 
// Module Name: mcs_bus_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: to bridge between microblaze mcs io bus and user-space own bus; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef _MCS_BUS_BRIDGE_SV
`define _MCS_BUS_BRIDGE_SV

`include "IO_map.svh"

module mcs_bus_bridge
    // this is given the datasheet of the microblaze;
    //#(parameter MCS_BRIDGE_BASE_ADDR = `BUS_MICROBLAZE_IO_BASE_ADDR_G)   
    (
        /* bus base address
            this base address comes with the soft processor;
            could be found in the relevant data sheet;
            */
        input logic [31:0] mcs_bridge_base_addr,                
        /*
         microblaze mcs io bus signals;
            these are fixed; confer the datasheet;
        */
        input logic io_addr_strobe,         // ignored;
        input logic io_read_strobe,         // read enable;
        input logic io_write_strobe,        // write enable;
        input logic [3:0] io_byte_enable,   // not useful aa of now; ignored;
        input logic [31:0] io_address,      
        input logic [31:0] io_write_data,
        output logic [31:0] io_read_data,
        output logic io_ready,              // for handshaking;
              
        /* on the other side of the bridge; user-own address space; */
        output logic user_mmio_cs,  // chip select for MMIO system;
        output logic user_video_cs, // chip select for the video system;
        output logic user_wr,      
        output logic user_rd,
        output logic [`BUS_USER_SIZE_G-1:0] user_addr,      // memory address for user system such as MMIO;
        output logic [`REG_DATA_WIDTH_G-1:0] user_wr_data,  // 32-bit wide;
        input logic [`REG_DATA_WIDTH_G-1:0] user_rd_data    // 32-bit wide;
    );
    
    // signal
    logic bridge_en;    // only enable if the given bus base address is a match;
    logic [29:0] addr_word_align;  // to convert to word-alignment: 32->30;
    
    /* mapping between microblaze's and user's */
    //> address mapping 
    assign addr_word_align = io_address[31:2];  // word alignment;
    
    // the given base address should match,
    // only compare the MSB 8-bit of the address; 
    // this should be sufficient to ensure uniqueness?
    // since other bits are used for other identification purposes;
    assign bridge_en = (io_address[31:26] == mcs_bridge_base_addr[31:26]);
    assign user_mmio_cs = (bridge_en && (io_address[`BUS_SYSTEM_SELECT_BIT_INDEX_G] == 0));
    assign user_video_cs = (bridge_en && (io_address[`BUS_SYSTEM_SELECT_BIT_INDEX_G] == 1));
    
    assign user_addr = addr_word_align[`BUS_USER_SIZE_G-1:0];   
    
    //> signal mapping;
    assign user_wr = io_write_strobe;
    assign user_rd = io_read_strobe;
    
    // this assumes all transaction is done in one clock;
    // shall revise if this is violated;
    // possible if we have one slow system block ...
    assign io_ready = 1;   
    
    // data mapping;
    assign user_wr_data = io_write_data;
    assign io_read_data = user_rd_data;
    
endmodule

`endif // _MCS_BUS_BRIDGE_SV;