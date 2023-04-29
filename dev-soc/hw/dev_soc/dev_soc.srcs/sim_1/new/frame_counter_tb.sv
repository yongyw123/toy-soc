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
        output logic cmd_start,
        input logic frame_start,
        input logic frame_end
    );
    
    /* test stimulus */
    initial begin
    $display("test starts");
    @(posedge clk);
    cmd_start <= 1'b0;
    #(50);
    
    @(posedge clk);
    cmd_start <= 1'b1;
    
    wait(frame_end == 1'b1);
    
    // stop immediately after frame_start wraps around;
    wait(frame_start == 1'b1);
    $display("test ends");
    $stop;
    
    end
    

        
endmodule
