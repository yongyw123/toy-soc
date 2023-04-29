`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.04.2023 23:33:09
// Design Name: 
// Module Name: frame_counter_tb
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


module frame_counter_tb
    (
        input logic clk,
        
        // for the uut: frame_counter;
        output logic cmd_start,
        input logic frame_start,
        input logic frame_end,
        
        // for fifo to act as a sink;
        output logic fifo_sink_ready,
        input logic fifo_sink_valid
    );
    
    /* test stimulus */
    initial begin
    $display("test starts");
    
    /* test 01: generate the pixel source and pass it to the sink 
    without the sink being drawn out */
    @(posedge clk);
    cmd_start <= 1'b0;
    #(50);
    
    @(posedge clk);
    cmd_start <= 1'b1;
    
    // pause;
    #(20);
    @(posedge clk);
    cmd_start <= 1'b0;

    // resume;
    #(30);
    @(posedge clk);
    cmd_start <= 1'b1;

   
    wait(frame_end == 1'b1);
    // stop the counter;
    @(posedge clk);
    cmd_start <= 1'b0;
    
    /* test 02: check the fifo 
    to see whether the fifo content matches with 
    the expectation */
    @(posedge clk);
    fifo_sink_ready <= 1'b1;
    
    // draw until the fifo is empty;
    wait(fifo_sink_valid == 1'b0);
    
    
    #(20);
    $display("test ends");
    $stop;
    
    end
    

        
endmodule
