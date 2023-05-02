`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 21:16:50
// Design Name: 
// Module Name: dcmi_decoder_tb
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


program dcmi_decoder_tb
    (
        input logic clk_sys,
    
        // emulator driving the sync signals to the decoder;
        input logic pclk,
        output logic emulator_start,
        input logic frame_start_tick,
        input logic frame_complete_tick,
        
        // decoder;
        output logic decoder_start
        
    );
    
    initial begin
    @(posedge clk_sys);
    decoder_start <= 1'b1;
    
    #(100);
    @(posedge clk_sys);
    emulator_start <= 1'b1;
    
    // deassert the emulator start otherwise it will 
    // keep going forever;
    wait(frame_start_tick == 1'b1);
    @(posedge clk_sys);
    emulator_start <= 1'b0; 
    
    #(1000);
    wait(frame_complete_tick == 1'b1);
    #(100);
    
    $display("test ends");
    $stop;
    end
endprogram
