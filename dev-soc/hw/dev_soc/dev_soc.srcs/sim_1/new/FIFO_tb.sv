`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2023 16:50:06
// Design Name: 
// Module Name: FIFO_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench program for FIFO module; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

program FIFO_tb
    #(parameter 
    DATA_WIDTH = 8,
    ADDR_WIDTH = 16
    )
    (
        input logic clk,
        output logic ctrl_rd,
        output logic ctrl_wr,
        output logic [DATA_WIDTH-1:0] wr_data
    );

    initial begin
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        /* test 01: write-only until fifo is full 
        expectation:
        1. full_flag will be triggered eventually;
        2. read_data will always point to the base (the first written data)
            because there is no read request;
        */
        
        // go beyond the address width to capture fifo status flags;
        // such as full/empty;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin        
            @(posedge clk)
            ctrl_wr <= 1'b1;
            wr_data = (DATA_WIDTH)'($random);
        end
        
        /* test 02: read-only until fifo is empty 
        expectation;
        1. the read data will be the write data in test 01 in a first-in-first out manner;
        2. empty_flag will be triggered eventually;
        */
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin
            @(posedge clk)
            ctrl_rd <= 1'b1;
        end 
        
        /* test 03: read and write when fifo is already empty 
        expectation:
        1. empty flag will always be triggered;
        2. read_data will be the same as the write_data
            because the write and read pointers are pointing
            at the same place;
        */
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin
            @(posedge clk)
            ctrl_rd <= 1'b1;
            ctrl_wr <= 1'b1;
            wr_data = (DATA_WIDTH)'($random);
        end 
        
        /* test 03: read and write when fifo is not empty and not full 
        expectation:
        1. full and empty flags will never occur;
        2. the read data will "lag" the write data by the amount of the write apriori;  
        */
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        // write some data;
        for(int i = 0; i < $ceil(ADDR_WIDTH/2); i++) begin
            @(posedge clk)
            ctrl_wr <= 1'b1;
            wr_data = (DATA_WIDTH)'($random);
        end 
        
        // now read and write at the same time;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin
            @(posedge clk)
            ctrl_rd <= 1'b1;
            ctrl_wr <= 1'b1;
            wr_data = (DATA_WIDTH)'($random);
            
        end 
    #(1);
    $finish;    
    end
endprogram: FIFO_tb
    
 
