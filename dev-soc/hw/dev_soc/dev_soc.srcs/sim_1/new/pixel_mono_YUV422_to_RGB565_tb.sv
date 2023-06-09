`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 02:22:17
// Design Name: 
// Module Name: pixel_mono_YUV422_to_RGB565_tb
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


module pixel_mono_YUV422_to_RGB565_tb(
    output logic [7:0] pixel_in
    );
    /* test */
    initial 
    begin
        $display("---- test start -----");
        for(int i = 0; i  < 10; i++) begin
            pixel_in = 8'($random);
        #(10);
        end   
        #(10);
        pixel_in = 8'h81;
        #(10);     
        pixel_in = 8'h63;
        #(10);     
        
        pixel_in = 8'h24;
        #(10);     
        
        pixel_in = 8'h81;
        #(10);     
        
        pixel_in = 8'h09;
        #(10);     
        
        pixel_in = 8'h63;
        #(10);     
        
        pixel_in = 8'h0d;
        #(10);     
        
        pixel_in = 8'h8d;
        #(10);     
        
        pixel_in = 8'h65;
        #(10);     
        
        pixel_in = 8'h12;
        #(10);     
        
        $display("---- test end -----");    
    $stop;
    end
endmodule
