`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 20:34:23
// Design Name: 
// Module Name: core_video_mig_interface_tb
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


module core_video_mig_interface_tb(
        input logic clk_sys,
        input logic [15:0] LED,
        output logic reset_sys,
        input logic  locked // mmcm locked status;               
    );
    
    localparam LED_END_RANGE = 4;
        
    initial begin
        /* initial reset pulse */
        reset_sys = 1'b1;
        #(100);
        reset_sys = 1'b0;
        #(100);

        
        wait(locked == 1'b1);
        #(1000);
        
        // reset to start over;
        reset_sys = 1'b1;
        #(100);
        reset_sys = 1'b0;
        #(100);        
        
        #(500);
        
        // wait for the LED to increase;
        // and wraps around twice to conclude the simulation;    
        wait(LED[LED_END_RANGE:0] == 1);
        
        // first round is done;
        wait(LED[LED_END_RANGE:0] == 0);
        wait(LED[LED_END_RANGE:0] == 1);
        
        // second round is done;
        wait(LED[LED_END_RANGE:0] == 0);
                
        // reset yp start over;
        reset_sys = 1'b1;
        #(100);
        reset_sys = 1'b0;
        #(100);
        
        // wait for the LED to increase;
        // and wraps around twice to conclude the simulation;    
        wait(LED[LED_END_RANGE:0] == 1);
        
        // first round is done;
        wait(LED[LED_END_RANGE:0] == 0);
        wait(LED[LED_END_RANGE:0] == 1);
        
        // second round is done;
        wait(LED[LED_END_RANGE:0] == 0);
        
        @(posedge clk_sys);
                
        $stop; 
    end
endmodule

