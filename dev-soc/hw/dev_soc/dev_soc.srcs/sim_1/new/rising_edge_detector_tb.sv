`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 00:30:43
// Design Name: 
// Module Name: rising_edge_detector_tb
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


module rising_edge_detector_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // uut signals;
    logic level;    // input to the uut to detect the edge;
    logic detected; // detected?
    
    /* simulate clk */
     always
        begin 
           clk = 1'b1;  
           #(T/2); 
           clk = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end
    
    
    /* instantiation */
    rising_edge_detector uut(.*);
    
    // test stimulus;
    
    initial begin
        level = 1'b1;
        #(100);
        
        // expect that the detector may or may not
        // be able to detect the edge;
        level = 1'b0;
        #(1);
        level = 1'b1;
        
        // expect that here the detector will NOT detect the rising edge;
        // because the rising edge occurs within a clock cycle;
        // beyond the "sampling capability" of the system;    
        #(10);
        level = 1'b0;
        #(7);
        level = 1'b1;
    
        #(50);
        level = 1'b0;
        #(10);
        level = 1'b1;
        #(100);
        $stop;
    end    
endmodule
