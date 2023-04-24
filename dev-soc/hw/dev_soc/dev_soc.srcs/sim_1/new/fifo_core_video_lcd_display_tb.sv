`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 15:49:54
// Design Name: 
// Module Name: fifo_core_video_lcd_display_tb
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


program fifo_core_video_lcd_display_tb
    #(parameter DATA_WIDTH = 8)   
    (
        // general;
        input clk,  // system clock; 100MHz;
        input reset, // async;
        
        /* test stimulus; */
        // source: left side of the fifo;
        output logic [DATA_WIDTH-1:0] src_data,   // 8 bits;
        output logic src_valid,   // source data is ready; perform the write;
        input logic src_ready,  // fifo is ready to accept new data;
        
        // sink: right side of the fifo;
        //input logic [DATA_WIDTH-1:0] sink_data,
        input logic sink_valid, // fifo is non-empty;
        output logic sink_ready // the sink is ready to ready data from this fifo;
    );
    
    initial begin
    $display("test starts");
    // idle for some time to check the reset state of the fifo;
    #(30);
    
    // fill up the buffer;
    for(int i = 0; i < 10; i++) begin
        wait(src_ready == 1'b1);
        @(posedge clk);
        src_data <= 8'($random);
        src_valid <= 1'b1;
    end
    
    
    #(100);
    $display("test ends");
    $stop;
    end
endprogram
