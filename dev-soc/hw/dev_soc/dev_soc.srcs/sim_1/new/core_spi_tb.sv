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
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,   
   
        // debugging;
        output logic [5:0] test_index
        
    );
    
    // spi clock programming candidates; 
    localparam spi_clock_test_program_0 = 100_000_000/(2*10_000_000) - 1;   // 10Mhz;
    localparam spi_clock_test_program_1 = 100_000_000/(2*1_000_000) - 1;   // 1Mhz;
    logic [15:0] spi_clock_mod_candidate_array[0:1] = {spi_clock_test_program_0, spi_clock_test_program_1};
    
    
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
    logic [10:0] test_index_track;  // loop index;
    logic spi_cpol;
    logic spi_cpha;
    
    initial begin
    
    $display("start");
    
    /*
    $display("test 00: set data or command-------");
    //$display("set dc to command");
    @(posedge clk);
    test_index <= 0;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    //addr[2:0] <= 3'b100;
    addr <= SPI_REG_CTRL;
    wr_data <= 32'b0;   // command;
    
    @(posedge clk);
    
    @(posedge clk);
    //$display("set dc to data");
    test_index <= 1;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr <= SPI_REG_CTRL; 
    wr_data <= 32'(3'b100);   // data;
    
    @(posedge clk);
    
    $display("test 01: check status -------");
    @(posedge clk);
    test_index <= 2;
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr <= SPI_REG_STATUS; 

    @(posedge clk);
    
    $display("test 02: check slave select setting -------");
    @(posedge clk);
    test_index <= 3;
    // try different ss combo;
    for(int i = 0; i < 4; i++) begin
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        addr <= SPI_REG_SS;
        wr_data <= 32'($random); 
    end

    @(posedge clk);
    
    
    $display("test 03: spi setting clock with two different parameter -----");
    test_index_count = 4;
    for(int i = 0; i < 2; i++) begin
        
        @(posedge clk);
        test_index <= test_index_count;
        test_index_count++;
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        addr <= SPI_REG_SCLK;
        //wr_data <=  spi_clock_test_program_0;
        wr_data <= spi_clock_mod_candidate_array[i];
        $display("clock mod: %0d ------------", spi_clock_mod_candidate_array[i]);
        
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        
        // check spi is free before starting;
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b1;
        write <= 1'b0;
        addr <= SPI_REG_STATUS; 
        
        // start spi;
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        addr <= SPI_REG_MOSI_WR;
        wr_data <=  32'($random);
        
        // check if spi flag is busy;
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b1;
        write <= 1'b0;
        addr <= SPI_REG_STATUS; 
        // expect that spi is busy at this stage;
        wait(rd_data == 32'b0);  // spi busy;
        
        // block until it is free
        wait(rd_data == 32'b1);  // spi free?
        
        // check the reassembled miso data;
        $display("check miso reassmbled data---------------");
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b1;
        write <= 1'b0;
        addr <= SPI_REG_MISO_RD; 
        
    end
    */
    
    $display("test: cpol and cpha setting -----");
    // set to the faster sclk;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr <= SPI_REG_SCLK;
    wr_data <= spi_clock_test_program_0;
    $display("clock mod: %0d-----------", spi_clock_test_program_0);
    
    test_index_track = 0;
    test_index_count = 0;
    for(test_index_track = 0; test_index_track < 4; test_index_track++) begin 
        
        // set the cpol, cpha; 
        @(posedge clk);
        test_index <= test_index_count;
        test_index_count++;
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        addr <= SPI_REG_CTRL;
        
        spi_cpol = test_index_track[0];
        spi_cpha = test_index_track[1];
        
        $display("cpol: %0b, cpha: %0b ------------", spi_cpol, spi_cpha);
        // the third bit is for the DC control;
        wr_data[1:0] <= {spi_cpha, spi_cpol};
            
        // start spi;
        $display("start spi-----------------");
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b0;
        write <= 1'b1;
        addr <= SPI_REG_MOSI_WR;
        wr_data <=  32'($random);
        
        
        // check if spi flag is busy;
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b1;
        write <= 1'b0;
        addr <= SPI_REG_STATUS; 
        // expect that spi is busy at this stage;
        wait(rd_data == 32'b0);  // spi busy;
        
        // block until it is free
        wait(rd_data == 32'b1);  // spi free?
        
        // check the reassembled miso data;
        $display("check miso reassmbled data---------------");
        @(posedge clk);
        cs <= 1'b1;
        read <= 1'b1;
        write <= 1'b0;
        addr <= SPI_REG_MISO_RD; 
        
    end
    
    
    #(20);
    
    $display("done");
    $stop;
    end
endprogram

`endif //CORE_SPI_TB_SV