`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 16:17:52
// Design Name: 
// Module Name: mcs_bus_bridge_tb
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
`ifndef _MCS_BUS_BRIDGE_TB_SV
`define _MCS_BUS_BRIDGE_TB_SV

`include "IO_map.svh"

module mcs_bus_bridge_tb();
    /*
        Purpose: test bench for mcs_bus_bridge() module
        Background: mcs_bus_bridge() bridges between Microblaze MCS IO bus and the User-defined bus;
        Construction: most signals are direct mapping, except for the address, and some control signals
        Note: this bridge is purely combinational;
        
        Testing (What must hold true): 
            1. bridge_en is set iff the input base address is a match;
            2. user-defined address is word aligned but microblaze is byte aligned;
            3. mmio_cs chip select is HIGH iff bridge_en is HIGH and bit-23-select bit is LOW:
            2. the rest are direct mappings; so easy check
    */
        
    localparam T = 10;  // clock period: 10ns;
    
    /* ------- module IO interface;*/
    logic clk;                    // 100 MHz;
    logic reset;                  // async;
    
    /* unit argument */
    
    logic [31:0] mcs_bridge_base_addr;  // input;
    
    //microblaze mcs io bus signals;
    logic io_addr_strobe;           // input; ignored;
    logic io_read_strobe;           // input; read enable;
    logic io_write_strobe;          // input; write enable;
    logic [3:0] io_byte_enable;     // input;
    logic [31:0] io_address;        // input;
    logic [31:0] io_write_data;     // intput;
    logic [31:0] io_read_data;      // output;
    logic io_ready;                 // output; expect this to be always HIGH
          
    /* on the other side of the bridge; user-own bus; */
    logic user_mmio_cs;     // output; chip select for MMIO system;
    logic user_wr;          // output;
    logic user_rd;          // output;
    logic [`BUS_USER_SIZE_G-1:0] user_addr;      // output; memory address for user system such as MMIO;
    logic [`REG_DATA_WIDTH_G-1:0] user_wr_data;  // output; 32-bit wide;
    logic [`REG_DATA_WIDTH_G-1:0] user_rd_data;  // input; 32-bit wide;

    
    /* ----- instantiation*/
    mcs_bus_bridge uut(.*);
    
    /* --- clk */
    /* note that the uut is purely combinational */
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    /* test */
    initial 
    begin
        $display("---- test start -----");
        for(int i = 0; i < 10; i++) begin
            /* test 00: direct mapping without any control signal */
            io_addr_strobe = 1'($random);          
            io_read_strobe = 1'($random);          
            io_write_strobe = 1'($random);         
            io_byte_enable = 4'($random);   
            io_address = 32'($random);      
            io_write_data = 32'($random);   
            user_rd_data = 32'($random);    
            io_address = 32'($random);
            mcs_bridge_base_addr = 32'($random);    // unlikely to be the matched;
            
            #(T);   // combinational delay;
            
            assert(user_wr_data == io_write_data);
            assert(io_read_data == user_rd_data);
            assert(io_ready == 1'b1);
            assert(user_wr == io_write_strobe);
            assert(user_rd == io_read_strobe);
            assert(user_addr == 21'(io_address[31:2])); // word-aligned and truncated;
            assert(user_mmio_cs == 1'b0); 
        end
        
        /* test 01; chip select signal */
        io_address = 32'($random);
        mcs_bridge_base_addr = 32'($random);    // unlikely to be the matched;
        #1 assert(user_mmio_cs == 1'b0);
        
        io_address = `BUS_MICROBLAZE_IO_BASE_ADDR_G;
        mcs_bridge_base_addr = `BUS_MICROBLAZE_IO_BASE_ADDR_G;
        #1 assert(user_mmio_cs == 1'b1);
        
        io_address = `BUS_MICROBLAZE_IO_BASE_ADDR_G;
        io_address[23] = 1'b1;      // chip deselect mmio system;
        mcs_bridge_base_addr = `BUS_MICROBLAZE_IO_BASE_ADDR_G;
        #1 assert(user_mmio_cs == 1'b0);
        
    $display("---- test end -----");    
    $stop;
    end
endmodule

`endif // _MCS_BUS_BRIDGE_TB_SV