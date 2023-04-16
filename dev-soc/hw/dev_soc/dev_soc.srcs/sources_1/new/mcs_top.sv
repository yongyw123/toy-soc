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
         // 100 MHz;
        input logic clk,       
        
        // async cpu (soft core) reset button; 
        // **important; it is active low; need to invert;
        input logic CPU_RESETN,     
        
        /* external mapping from boards; */
        input logic [15:0] SW,      // use all switches available on the board;
        output logic [15:0] LED,    // use all leds available on the board;
        inout tri[3:0] PMOD_JD,     // PMOD jumpers at JD1 to JD4; set to tristate since it is for GPIO;
        
        // uart;
        // beware of the mix of tx and rx;
        // note: uart flow ctrl is not implemented; so no cts/rts pins;
        input logic UART_TXD_IN,  // this connects to the system uart rx;
        output logic UART_RXD_OUT, // this connects to the system uart tx;
        
        // spi;
        // uses PMOD jumper @ JC;
        output logic SPI_SCLK_JC1,
        output logic SPI_MOSI_JC2,
        input logic SPI_MISO_JC3,
        output logic SPI_SS_JC4, // slave select; asset active low;
        output logic SPI_DC_JC7  // is the current MOSI a data or command for the slave?  
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
    /* ?? to do ??, need to debounce this reset button; */
    assign reset_sys = !CPU_RESETN;    // inverted since button is "active LOW";
    
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
    mcs_bus_bridge bridge_unit(.mcs_bridge_base_addr(`BUS_MICROBLAZE_IO_BASE_ADDR_G), .*);
    
    // mmio system;
    mmio_sys 
    
    #(.SW_NUM(16), 
    .LED_NUM(16),
    .PORT_NUM(4), 
    .UART_DATA_BIT(8),
    .UART_STOP_BIT_SAMPLING_NUM(16),
    .SPI_DATA_BIT(8),
    .SPI_SLAVE_NUM(1))
     
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
        .led(LED),
        .pmod(PMOD_JD),
        
        // uart signals; 
        .uart_tx(UART_RXD_OUT), 
        .uart_rx(UART_TXD_IN),
        
        // spi; empty for now;
        .spi_sclk(SPI_SCLK_JC1),
        .spi_mosi(SPI_MOSI_JC2),
        .spi_miso(SPI_MISO_JC3),
        .spi_ss_n(SPI_SS_JC4),
        .spi_data_or_command(SPI_DC_JC7)  
    );
    
endmodule

`endif // _MCS_TOP_SV;
