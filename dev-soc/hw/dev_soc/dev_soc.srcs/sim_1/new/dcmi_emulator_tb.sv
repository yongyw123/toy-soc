`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 16:03:20
// Design Name: 
// Module Name: dcmi_emulator_tb
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


program dcmi_emulator_tb
    (
        input logic pclk,
        output logic start,
        input logic frame_complete_tick,
        input logic frame_start_tick
       
    );
    
    
    initial begin
     /* first start */
     @(posedge pclk);
     start <= 1'b0;
     
     @(posedge pclk);
     start <= 1'b1;
     
     wait(frame_start_tick == 1'b1);     
     @(posedge pclk);
     start <= 1'b0;
     
     #(1000);
     
     wait(frame_complete_tick == 1'b1);
     
     /* second start */
     @(posedge pclk);
     start <= 1'b1;
     
     wait(frame_start_tick == 1'b1);     
     @(posedge pclk);
     start <= 1'b0;
     
     #(1000);
     
     wait(frame_complete_tick == 1'b1);
     
     
     
     $display("test ends");
     #(50);
     $stop;
     end
    
endprogram
