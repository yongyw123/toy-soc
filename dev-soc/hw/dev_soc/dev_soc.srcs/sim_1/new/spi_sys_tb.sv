`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 13:42:59
// Design Name: 
// Module Name: spi_sys_tb
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


program spi_sys_tb
    #(parameter 
        DATA_BIT = 8,   
        MAX_SPI_CLOCK_WIDTH = 16   
    )
    (
        input clk,
        input reset,
        
        // stimulus;
        output logic[DATA_BIT-1:0] mosi_data_write,
        output logic[MAX_SPI_CLOCK_WIDTH-1:0] count_mod,
        output logic cpol,
        output logic cpha,
        output logic start,
        //output logic miso,  // not used;

        input logic spi_ready_flag,
        input logic spi_complete_flag,
        
        // debugging;
        output logic [5:0] test_index,
        
        // for miso generation;
        input logic sclk
    );
    
    
    // spi clock programming candidates; 
    localparam spi_clock_test_program_0 = 100_000_000/(2*10_000_000) - 1;   // 10Mhz;
    localparam spi_clock_test_program_1 = 100_000_000/(2*1_000_000) - 1;   // 1Mhz;
    
    // sim var;
    logic [2:0] index;  // loop index;
    logic [10:0] test_index_count;  // loop index;
    initial begin
    $display("start");
    
    $display("test 00: check spi clock progam, miso sampling and mosi shifting");
    
    count_mod = spi_clock_test_program_1;
    cpol = 1'b0;
    cpha = 1'b0;
    mosi_data_write = (DATA_BIT)'($random);
    //miso = 1'($random);
    
    @(posedge clk);
    test_index <= 0;
    
    wait(spi_ready_flag == 1'b1);
    start <= 1'b1;
    
    @(posedge clk);
    start <= 1'b0;
    
    wait(spi_complete_flag == 1'b1);
    wait(spi_ready_flag == 1'b1);
    
    $display("change clock -----");
    // change spi clock;
    count_mod = spi_clock_test_program_0;
    cpol = 1'b0;
    cpha = 1'b0;
    mosi_data_write = (DATA_BIT)'($random);
    //miso = ~miso;
    
    @(posedge clk);
    test_index <= 1;
    
    wait(spi_ready_flag == 1'b1);
    start <= 1'b1;
    
    @(posedge clk);
    start <= 1'b0;
    
    wait(spi_complete_flag == 1'b1);
    wait(spi_ready_flag == 1'b1);
    
    $display("test 01: cpol and cpha combo--------");
    count_mod = spi_clock_test_program_0;
    
    // four combinations;
    test_index_count = test_index;
    for(index = 0; index < 4; index++) begin
        mosi_data_write = (DATA_BIT)'($random);
        //miso = ~miso;
        
        cpol = index[0];
        cpha = index[1];
        $display("test: cpol: %0b, cpha: %0b", cpol, cpha);
        test_index_count++;
        @(posedge clk);
        test_index <= test_index_count;
 
        wait(spi_ready_flag == 1'b1);
        start <= 1'b1;
        
        @(posedge clk);
        start <= 1'b0;
        
        wait(spi_complete_flag == 1'b1);
        wait(spi_ready_flag == 1'b1);
                       
    end
    
    #(10);
    $display("done");
    $stop;
    
    end
endprogram