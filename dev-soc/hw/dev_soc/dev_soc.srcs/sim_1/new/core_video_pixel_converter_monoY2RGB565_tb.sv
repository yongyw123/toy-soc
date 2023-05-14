`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 20:55:38
// Design Name: 
// Module Name: core_video_pixel_converter_monoY2RGB565_tb
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
`ifndef CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TB_SV
`define CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TB_SV

`include "IO_map.svh"


module core_video_pixel_converter_monoY2RGB565_tb
    (
        
        // general;
        input logic clk_sys,
        
        // bus interface;
        output logic cs,
        output logic write,
        output logic read,
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data, 
        input logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // fifo upstream interface;
        output logic up_wr,
        output logic [7:0] up_wr_data,
        
        // fifo downatream interface;
        output logic down_rd,
        input logic down_full,
        input logic down_empty

    );
    
    initial begin
    $display("test starts");
    @(posedge clk_sys);
    cs <= 1'b1;
    read <= 1'b1;   // dont care;
    write <= 1'b1;  
    wr_data <= 0;// converter disabled;
    down_rd <= 1'b0;    // downstream disabled;
    up_wr <= 1'b0;
    addr <= 0;
    
    /*------- test one: converter disabled */
    // fill up the upstream buffer;
    @(posedge clk_sys);
    for(int i = 1; i < 9; i++) begin
        @(posedge clk_sys);
        up_wr <= 1'b1;
        up_wr_data <= i;    
    end
    @(posedge clk_sys);
    up_wr <= 1'b0;
    
    
    // downstream fifo is halved the size of the upstream fifo;
    // expect it to be full;
    wait(down_full == 1'b1);
    #(50);     
    @(posedge clk_sys);
    down_rd <= 1'b1;
    
    /*
    // disable the downstream read once the downstream fifo is empty;
    @(posedge clk_sys);    
    wait(down_empty == 1'b1);    
    @(posedge clk_sys);
    down_rd <= 1'b1;
    */
    
    #(100);
    $display("test ends");
    $stop;
    end
endmodule

`endif //CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TB_SV