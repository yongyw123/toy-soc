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


module dcmi_emulator_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    // uut signals
    localparam DATA_BITS = 8;
    logic pclk;  // fixed at 25 MHz (cannot emulate 24MHz using 100MHz clock);
    logic vsync; 
    logic href;
    logic [DATA_BITS-1:0] dout;
    
    /* simulate clk */
     always
        begin 
           clk_sys = 1'b1;  
           #(T/2); 
           clk_sys = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset_sys = 1'b1;
            #(T/2);
            reset_sys = 1'b0;
            #(T/2);
        end
     
     // uut;
     dcmi_emulator uut(.*);
     
     initial begin
     
     
     #(1000);
     $stop;
     end
     
    
endmodule
