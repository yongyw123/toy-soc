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
        parameter NUM_SPI_SLAVE = 1 // number of spi slaves for the master?
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
   
   
endmodule

`endif // CORE_SPI_SV