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
        output logic decoder_start,
        output logic decoder_data_ready, // from the sinking fifo to the decoder;
        input logic decoder_data_valid  // from the decoder to the fifo;
        
    );
    
    initial begin
    /* test 01:
    start the decoder 
    followed by the emulator
    */
    @(posedge clk_sys);
    decoder_data_ready <= 1'b1;
    
    @(posedge clk_sys);
    decoder_start <= 1'b1;
    
    #(100);
    @(posedge clk_sys);
    emulator_start <= 1'b1;
    
    // disable both emulator and the decoder; 
    // otherwise they will keep going forever;     
    wait(frame_start_tick == 1'b1);
    @(posedge clk_sys);
    emulator_start <= 1'b0;
    decoder_start <= 1'b0;
     
    
    #(1000);
    wait(frame_complete_tick == 1'b1);
    #(100);
    
    /* test 02:
    start the emulator;
    halfway start the decoder after vsync has been asserted;
    expect the decoder will not decode
    anything since it misses the assertion of a start frame (i.e. vsync);
    */
    @(posedge pclk);
    emulator_start <= 1'b1;
    
    wait(frame_start_tick == 1'b1);
    @(posedge pclk);
    decoder_start <= 1'b1;
    
    #(1000);
    wait(frame_complete_tick == 1'b1);
    #(100);
    
    /* test 02.1 
    expect that here the decoder 
    will NOT miss
    */
    wait(frame_start_tick == 1'b1);
    #(1000);
    wait(frame_complete_tick == 1'b1);
    
    
    
    /* test 03;
    test fifo (sink) data ready to the decoder;
    expect that if fifo is not ready;
    decoder will NOT start*/
    @(posedge pclk);
    decoder_data_ready <= 1'b0;
    
    wait(frame_start_tick == 1'b1);
    #(1000);
    wait(frame_complete_tick == 1'b1);
    #(100);
    $display("test ends");
    $stop;
    end
endprogram
