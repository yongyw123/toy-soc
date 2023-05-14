`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 17:45:02
// Design Name: 
// Module Name: pixel_Y2RGB565_pass_tb
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


module pixel_Y2RGB565_pass_tb
    (
        // general;
        input logic clk_sys,
        
        // simulate the upstream src (fifo);
        output logic up_wr,
        input logic up_full,
        output logic [15:0] up_wr_data,
        
        // simulate the downstream sink (fifo);
        output logic down_rd,
        input logic down_empty
        
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
        up_wr_data <= {8'(i + 1), 8'(i)};
    end
    // disable write;
    @(posedge clk_sys);
    up_wr <= 1'b0;

    #(200);
    
    $display("test ends");
    $stop;
    end
endmodule
