`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2023 21:36:20
// Design Name: 
// Module Name: pixel_Y2RGB565_pass_v2_tb
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


module pixel_Y2RGB565_pass_v2_tb(
        // general;
        input logic clk_sys,
        
        // simulate the upstream src (fifo);
        output logic up_wr,
        input logic up_full,
        output logic [15:0] up_wr_data,
        input logic up_empty,
        
        // simulate the downstream sink (fifo);
        output logic down_rd,
        input logic down_empty,
        input logic down_full
        
    );
    
    initial begin
    $display("test starts");
    // set up the sink;
    // do not read first;
    @(posedge clk_sys)
    down_rd <= 1'b0;
    up_wr <= 1'b0;
    
    // start filling up the upstream fifo;
    for(int i = 0; i < 8; i++) begin
        @(posedge clk_sys);
        up_wr <= 1'b1;
        //up_wr_data <= {8'(i + 1), 8'(i)};
        up_wr_data <= {8'($random), 8'($random)};
    end
    // disable write;
    @(posedge clk_sys);
    up_wr <= 1'b0;
    
    // eventually the upstream fifo will be empty;
    // once this is reached; read the downstream fifo;
    // to see if the read data matches with the expectation;
    wait(up_empty == 1'b1);
    @(posedge clk_sys);
    down_rd <= 1'b1;
    
    // read until the downstream fifo is empty;
    wait(down_empty == 1'b1);
    @(posedge clk_sys);
    down_rd <= 1'b0;
    
    /*
    // downstream fifo is halved the size of the upstream fifo;
    // expect it to be full since rd is disabled;
    // once full; enable the full;
    wait(down_full == 1'b1);
    #(30);
    @(posedge clk_sys);
    down_rd <= 1'b1;
    
    
    wait(down_full == 1'b0);
    @(posedge clk_sys);
    down_rd <= 1'b0;
    */
    
    
    #(50);
    
    $display("test ends");
    $stop;
    end
endmodule