`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 01:22:49
// Design Name: 
// Module Name: core_video_lcd_display_top_tb
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
`ifndef CORE_VIDEO_LCD_DISPLAY_TOP_TB_SV
`define CORE_VIDEO_LCD_DISPLAY_TOP_TB_SV

`include "IO_map.svh"


module core_video_lcd_display_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    
    /* interface arguents;; */
    localparam PARALLEL_DATA_BITS = 8;
    // input;
    logic cs;
    logic write;
    logic read;
    logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr;    
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
   
   // output;
   logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
   logic lcd_drive_wrx;
   logic lcd_drive_rdx;
   logic lcd_drive_csx;
   logic lcd_drive_dcx;
   tri[PARALLEL_DATA_BITS-1:0] lcd_dinout;
   
   
   // sim var;
   logic [31:0] test_index;
   
   // instantiation;
   core_video_lcd_display uut
   (
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .write(write),
        .read(read),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .lcd_drive_wrx(lcd_drive_wrx),
        .lcd_drive_rdx(lcd_drive_rdx),
        .lcd_drive_csx(lcd_drive_csx),
        .lcd_drive_dcx(lcd_drive_dcx),
        .lcd_dinout(lcd_dinout),
        // empty for now;
        .stream_out_read_flag(),
        .stream_in_pixel_data(),
        .stream_in_wr_valid()
   );
   
   // test stimulus;
   core_video_lcd_display_tb tb (.*);
   
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
    
   /* monitoring */
   initial begin
   
    $monitor("time: %t, #: %0d, addr: %0d, wr_data: %0B, rd_data: %0B, wrx: %0b, rdx: %0b, csx: %0b, dcx: %0b, dinout: %0B",
    $time,
    test_index,
    addr,
    wr_data,
    rd_data,
    lcd_drive_wrx,
    lcd_drive_rdx,
    lcd_drive_csx,
    lcd_drive_dcx,
    lcd_dinout);
    
    
   end
    
endmodule


`endif //CORE_VIDEO_LCD_DISPLAY_TOP_TB_SV