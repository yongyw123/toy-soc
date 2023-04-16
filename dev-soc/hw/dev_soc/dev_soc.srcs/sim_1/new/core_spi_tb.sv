`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 22:34:38
// Design Name: 
// Module Name: core_spi_tb
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

`ifndef CORE_SPI_TB_SV
`define CORE_SPI_TB_SV

`include "IO_map.svh"


program core_spi_tb
    #(
        parameter 
        SPI_SLAVE_NUM = 1, // number of spi slaves for the master?
        SPI_DATA_BIT = 8    // this is fixed usually;
    )
    
    (
        input logic clk,
        input logic reset,
        
        output logic cs,
        output logic write,
        output logic read,
        output logic [`REG_ADDR_SIZE_G-1:0] addr,    
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
   
        // debugging;
        output logic [5:0] test_index
        
    );
    
    // spi clock programming candidates; 
    localparam spi_clock_test_program_0 = 100_000_000/(2*10_000_000) - 1;   // 10Mhz;
    localparam spi_clock_test_program_1 = 100_000_000/(2*1_000_000) - 1;   // 1Mhz;
    
    // register offset;
   localparam SPI_REG_STATUS = `S5_SPI_REG_STATUS_OFFSET;
   localparam SPI_REG_SS = `S5_SPI_REG_SS_OFFSET;
   localparam SPI_REG_MOSI_WR = `S5_SPI_REG_MOSI_WR_OFFSET;
   localparam SPI_REG_MISO_RD = `S5_SPI_REG_MISO_RD_OFFSET;
   localparam SPI_REG_CTRL = `S5_SPI_REG_CTRL_OFFSET;
   localparam SPI_REG_SCLK = `S5_SPI_REG_SCLK_MOD_OFFSET;
   
    // sim var;
    logic [2:0] index;  // loop index;
    logic [10:0] test_index_count;  // loop index;
    
    initial begin
    
    $display("start");
    
    $display("test 00: read spi status flag");
    @(posedge clk);
    test_index <= 0;
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[2:0] = SPI_REG_STATUS;
    
    @(posedge clk);
    #(10);
    $display("done");
    $stop;
    end
endprogram

`endif //CORE_SPI_TB_SV