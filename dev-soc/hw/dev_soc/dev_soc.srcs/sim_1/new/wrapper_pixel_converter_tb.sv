`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2023 16:12:00
// Design Name: 
// Module Name: wrapper_pixel_converter_tb
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


module wrapper_pixel_converter_tb
    (
        // generak;
        input logic clk_sys,
        input logic reset_sys,
        
        // write upstream fifo test stimulus;
        output logic up_wr,
        output logic [7:0] up_wr_data,
        input logic up_full,
        
        // read downstream fifo test stimulus;
        output logic down_rd,
        input logic down_empty,
        
        // debugging status;
        input logic debug_pass_src_valid        
    );
    
    initial begin
    $display("test starts");
    
    /*  test 01: write only; */
    @(posedge clk_sys);
    down_rd <= 1'b0;
    up_wr <= 1'b0;
    // create a burst of data;
    for(int i = 0; i < 8; i++) begin
        @(posedge clk_sys);
         up_wr <= 1'b1;
         up_wr_data <= 8'($random);
    end
    @(posedge clk_sys);    
    up_wr <= 1'b0;
    
    /*
    // eventually there is something to read downstream;
    // but there is lag between writing and reading;
    // so need to read multiple times;    
    for(int i = 0; i < 4; i++) begin
        wait(down_empty == 1'b0);        
        down_rd <= 1'b1;
        
        // read all;
        wait(down_empty == 1'b1);        
        down_rd <= 1'b0;
    end
    */
    
    wait(debug_pass_src_valid == 1'b0);
    @(posedge clk_sys);
    down_rd <= 1'b1;
    
    wait(down_empty == 1'b1);
    @(posedge clk_sys);
    down_rd <= 1'b0;
        
    #(50);
    $display("test ends");
    $stop;
    
    end
endmodule
