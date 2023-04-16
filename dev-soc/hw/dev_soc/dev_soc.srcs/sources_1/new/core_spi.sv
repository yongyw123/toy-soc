`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 18:10:30
// Design Name: 
// Module Name: core_spi
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

`ifndef CORE_SPI_SV
`define CORE_SPI_SV

`include "IO_map.svh"


module core_spi
    #(
        parameter 
        NUM_SPI_SLAVE = 1, // number of spi slaves for the master?
        SPI_DATA_BIT = 8    // this is fixed usually;
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
        
        /* spi specific;*/
        // spi standard signals;
        output logic spi_sclk,
        output logic spi_mosi,
        input logic spi_miso,
        
        // misc 
        output logic[NUM_SPI_SLAVE-1:0] spi_ss_n,    // low to assert a given slave;
        output logic spi_data_or_command            // is the current MOSI a data or command for the slave;  
     
    );
    
   // decode for write as there are multiple register for writing;
   logic wr_en;
   logic wr_ss;
   logic wr_spi_start;
   logic wr_ctrl;
   
   logic[`S5_SPI_REG_CTRL_CLK_WIDTH-1:0] spi_clk_count_mod;
   logic cpol;
   logic cpha;
   
   logic spi_ready_flag;

    // register;s
   logic [SPI_DATA_BIT-1:0] spi_miso_assembled_reg, spi_miso_assembled_reg; 
   logic [`S5_SPI_REG_CTRL_LEN-1:0] ctrl_reg, ctrl_next;
   logic[NUM_SPI_SLAVE-1:0] spi_ss_reg, spi_ss_reg;
   logic spi_data_or_command_reg, spi_data_or_command_reg;
   
   // spi controller instantiation;
   spi_sys spi_controller
   (
    .clk(clk),
    .reset(reset),
    .mosi_data_write(wr_data[SPI_DATA_BIT-1:0]),
    .count_mod(spi_clk_count_mod),
    .cpol(cpol),
    .cpha(cpha),
    .start(wr_spi_start),
    .miso_assembled_data(spi_miso_assembled_reg),
    .spi_complete_flag(),   // not needed;
    .spi_ready_flag(spi_ready_flag),
    .sclk(spi_sclk),
    .mosi(spi_mosi),
    .miso(spi_miso)
   );
   
   // register ;
   always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                ctrl_reg[`S5_SPI_REG_CTRL_CLK_LEN - 1:0] <= `S5_SPI_REG_CTRL_CLK_LEN'(32'h0000_0000); // this disables SPI clock;
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPHA - 1] <= 1'b0;
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPOL - 1] <= 1'b0;  
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_DC - 1] <= 1'b0;    // default: data (not command);
                spi_ss_reg <= NUM_SPI_SLAVE'(32hFFFF_FFFF); // all not enabled;
            end
        else
            begin
                
            
            end    
   
   // decoding;
   
   
   
   
    
endmodule

`endif // CORE_SPI_SV