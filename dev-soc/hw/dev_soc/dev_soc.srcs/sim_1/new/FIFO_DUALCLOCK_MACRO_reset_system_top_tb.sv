`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 22:07:44
// Design Name: 
// Module Name: FIFO_DUALCLOCK_MACRO_reset_system_top_tb
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


module FIFO_DUALCLOCK_MACRO_reset_system_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    logic slower_clk;         // as the second clk for the dual clock fifo;
    
    // uut specific;
    logic RST_FIFO;
    logic FIFO_rst_ready;
    logic debug_detected_rst_sys_falling;
    logic debug_detected_slow_clk_rising;
    
    /* simulate system clk */
     always
        begin 
           clk_sys = 1'b1;  
           #(T/2); 
           clk_sys = 1'b0;  
           #(T/2);
        end
      
          
     //reset pulse fo the user-systems;
    
     /* instantiation */
     FIFO_DUALCLOCK_MACRO_reset_system 
     uut
     (
        .clk_sys(clk_sys),
        .reset_sys(reset_sys),
        .slower_clk(slower_clk),
        .RST_FIFO(RST_FIFO),
        .FIFO_rst_ready(FIFO_rst_ready),
        .debug_detected_rst_sys_falling(debug_detected_rst_sys_falling),
        .debug_detected_slow_clk_rising(debug_detected_slow_clk_rising)
     );
     
     // reset signal test stimulus;
     FIFO_DUALCLOCK_MACRO_reset_system_reset_test_stimulus_tb reset_tb(.*);
     
     // slower clock test stimulus;
     FIFO_DUALCLOCK_MACRO_reset_system_pclk_test_stimulus_tb clk_tb(.*);
        
    /* monitoring system */
    initial begin
        $monitor("time: %t, reset_sys: %0b, RST_FIFO: %0b, FIFO_rst_ready: %0b, rst_edge: %0b, slowclk_edge: %0b, uut.statereg: %s, uut.uut.detected_slow_clk_rising: %0b, slower_clk: %0b",
        $time,
        reset_sys,
        RST_FIFO,
        FIFO_rst_ready,
        debug_detected_rst_sys_falling,
        debug_detected_slow_clk_rising,
        uut.state_reg.name,
        uut.detected_slow_clk_rising,
        slower_clk
        );
       
    
    
    end
    
    
endmodule
