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
        /* test 01: write-only until fifo is full */
        // go beyond the address width to capture fifo status flags;
        // such as full/empty;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin        
            @(posedge clk)
            ctrl_wr <= 1'b1;
            wr_data = (DATA_WIDTH)'($random);
        end
        
        /* test 02: read-only until fifo is empty */
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin
            @(posedge clk)
            ctrl_rd <= 1'b1;
        end 
        
        /* test 03: read and write when fifo is already empty */
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        for(int i = 0; i < ADDR_WIDTH + 5; i++) begin
            @(posedge clk)
            ctrl_rd <= 1'b1;
            ctrl_wr <= 1'b1;
        end 
        
        /* test 03: read and write when fifo is not empty and not full */
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
    
 
