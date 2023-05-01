`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 00:30:43
// Design Name: 
// Module Name: rising_edge_detector_top_tb
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


module rising_edge_detector_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // uut signals;
    logic level;    // input to the uut to detect the edge;
    logic detected; // detected?
    
    // counter signals;
    logic [10:0] cnt_reg, cnt_next;
    always_ff @(posedge clk)
        if(reset)
            cnt_reg <= 0;
        else
        if(detected)
            cnt_reg <= cnt_next;
    
    assign cnt_next = cnt_reg + 1;
    
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
    
    rising_edge_detector_tb tb(.*);
    
        
endmodule
