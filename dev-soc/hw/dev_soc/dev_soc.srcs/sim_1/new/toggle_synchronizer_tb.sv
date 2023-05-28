`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.05.2023 20:49:44
// Design Name: 
// Module Name: toggle_synchronizer_tb
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

module toggle_synchronizer_tb
    (
        // need to wait for the mmcm to lock before start the test stimulus;
        input logic locked,
        
        // src domain;
        input logic clk_src,
        // test stimulus;
        output logic in_async,
        
        // dest domain;
        input logic clk_dest
    );
    
    initial begin
        
    // initial condition;
    @(posedge clk_src);
    in_async <= 1'b0;
    
    // need to wait for the mmcm to lock before start the test stimulus;    
    wait(locked == 1'b1);

    // create a short pulse with respect to the fast clock (src);
    // such that it is between two rising edges of the slow clock (dest);
    // to check whether the toggle synchronizer detects it and synchronizes it;
    // otherwise the toggle synchronizer is not doing its job;
    
    /*
    @(posedge clk_src);
    in_async <= 1'b1;
    @(posedge clk_src);
    in_async <= 1'b0;
    */
      
    
    // create successive short pulse;
    // one of the pulses must be between two rising edges of the slow clock;
    for(int i = 0; i < 10; i++) begin
        @(posedge clk_src);
        in_async <= 1'b1;
        @(posedge clk_src);
        in_async <= 1'b0;
        for(int j = 0; j < 3; j++) begin
            @(posedge clk_dest);
        end    
    end
    
    
    #(100);
    $stop;
    
    end
endmodule
