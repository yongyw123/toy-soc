`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 22:35:03
// Design Name: 
// Module Name: core_spi_top_tb
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

`ifndef CORE_SPI_TOP_TB_SV
`define CORE_SPI_TOP_TB_SV

`include "IO_map.svh"


module core_spi_top_tb();
    /* 
    * purpose: to test core_spi(); this module is a wrapper
            of spi_sys() to be plug into the MMIO system;
      
      What to test:
        1. by above, the main thing to test
        is the instruction decoding
        and whether the register is read/written correctly;
     
    */
    
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    localparam SPI_SLAVE_NUM = 8;   // how many slaves connected to the same SPI core pins?
    localparam SPI_DATA_BIT = 8;    // standard;
    
    /* interface arguents;; */
    // input;
    logic cs;
    logic write;
    logic read;
    logic [`REG_ADDR_SIZE_G-1:0] addr;    
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
   
    // output;
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    // spi specific pins;
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic[SPI_SLAVE_NUM-1:0] spi_ss_n;   // low to assert a given slave;
    logic spi_data_or_command;           // is the current MOSI a data or command for the slave?  
 
    
    // sim var;
    logic [5:0] test_index;
    
    // debugging;
    logic wr_sclk;
    logic wr_spi_start;
    
   
    /* instantiation */
    assign spi_miso = spi_mosi; // loop back;
    core_spi #(.SPI_SLAVE_NUM(SPI_SLAVE_NUM), .SPI_DATA_BIT(SPI_DATA_BIT))
    uut(.*, .spi_miso(spi_miso));
    
    /* test stimulus */
    core_spi_tb #(.SPI_SLAVE_NUM(SPI_SLAVE_NUM), .SPI_DATA_BIT(SPI_DATA_BIT))
    tb (.*);
    
    /* simulate clk */
     always
        begin 
           clk = 1'b1;  
           #(T/2); 
           clk = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end
    
    /* monitoring */
    initial
    begin
        $monitor("spi system -  state: %s, current_cnt: %0d, count_mod: %0d", uut.spi_controller.state_reg.name, uut.spi_controller.clk_cnt_reg, uut.spi_controller.count_mod);
        $monitor("time: %0t, test index: %0d, cs: %0b, wr: %0b, rd: %0b, addr: %0B, rdatad: %0D, wrdatab: %0B, rddata: %0B, sclk: %0b, mosi: %0b, miso: %0b, ss: %0B, dc: %0b, wr_sclk: %0b, wr_start: %0b",
            $time,
            test_index,
            cs,
            write,
            read,
            addr[2:0],
            wr_data,
            wr_data,
            rd_data,
            spi_sclk,
            spi_mosi,
            spi_miso,
            spi_ss_n,
            spi_data_or_command,
            wr_sclk,
            wr_spi_start
           );
    end
    
    
         
    
    
    
endmodule

`endif //CORE_SPI_TOP_TB_SV