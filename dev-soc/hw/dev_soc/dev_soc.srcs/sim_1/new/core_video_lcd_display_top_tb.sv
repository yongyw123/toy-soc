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
    
    
    /* uut interface arguents;; */
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
   
   
   // not from or for the processor;
   logic [PARALLEL_DATA_BITS-1:0] stream_in_pixel_data;
   logic stream_valid_flag;
   logic stream_ready_flag;
   
   /* fifo interface signal declare */
   logic [PARALLEL_DATA_BITS-1:0] fifo_src_data;
   logic fifo_src_valid;
   logic fifo_src_ready; 
   
   
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

        .stream_ready_flag(stream_ready_flag),
        .stream_in_pixel_data(stream_in_pixel_data),
        .stream_valid_flag(stream_valid_flag)
   );
   
   // test stimulus;
   core_video_lcd_display_tb tb (.*);
   
   // fifo interface acting as the source;
   // this is to test the stream control;
   // if the control is over to the cpu;
   // then this fifo interface src will be ignored;
   fifo_core_video_lcd_display 
    #(
    .DATA_WIDTH(PARALLEL_DATA_BITS),
    .ADDR_WIDTH(3) // could hold up to 2^3 = 8 data; 
    )
    fifo_src
    (
    .clk(clk),
    .reset(reset),
    .src_data(fifo_src_data),
    .src_valid(fifo_src_valid),
    .src_ready(fifo_src_ready),
    .sink_data(stream_in_pixel_data),
    .sink_valid(stream_valid_flag),
    .sink_ready(stream_ready_flag)
    );
    
   
   
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
   $monitor("time: %t, addr: %3d, wr_data: %3B, uut.wr_en: %0b, uut.wr_csx_en: %0b, uut.csx_reg: %0b, uut.csx_next: %0b",
   $time, addr, wr_data, uut.wr_en, uut.wr_en_csx, uut.csx_reg, uut.csx_next);
   
    /*
    //$monitor("time: %t, #: %0d, addr: %0d, wr_data: %0B, rd_data: %0B, wrx: %0b, rdx: %0b, csx: %0b, dcx: %0b, dinout: %0B, uut.start: %0b, uut.cmd: %0B",
    $monitor("time: %10t, #: %d, addr: %d, wr_data: %20B, rd_data: %10B, ready: %b, wrx: %b, rdx: %b, csx: %b, dcx: %b, dinout: %B, uut.start: %b, uut.cmd: %B",
    $time,
    test_index,
    addr,
    wr_data,
    rd_data,
    stream_ready_flag,
    lcd_drive_wrx,
    lcd_drive_rdx,
    lcd_drive_csx,
    lcd_drive_dcx,
    lcd_dinout,
    uut.lcd_user_start,
    uut.lcd_user_cmd);
    */
    
   end
    
endmodule


`endif //CORE_VIDEO_LCD_DISPLAY_TOP_TB_SV