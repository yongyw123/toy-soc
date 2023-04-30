`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2023 01:36:46
// Design Name: 
// Module Name: core_video_lcd_test_pattern_gen_top_tb
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
`ifndef CORE_VIDEO_LCD_TEST_PATTERN_GEN_TOP_TB_SV
`define CORE_VIDEO_LCD_TEST_PATTERN_GEN_TOP_TB_SV

`include "IO_map.svh"


module core_video_lcd_test_pattern_gen_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // constants;
    localparam SINK_BITS_PER_PIXEL = 8;
    localparam SRC_BITS_PER_PIXEL = 16;
    localparam LCD_WIDTH = 4;   
    localparam LCD_HEIGHT = 1;
    localparam COUNTER_WIDTH = 10; 
            
    
    /* uut signals */
    logic cs;    
    logic write;              
    logic read;               
    logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr;  //  19-bit;         
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    logic [SINK_BITS_PER_PIXEL-1:0] stream_out_rgb; // 8-bit for the LCD;
    logic sink_ready; // signal from the lcd fifo;
    logic sink_valid; // signal to the lcd fifo

    /* instantiation */
    core_video_lcd_test_pattern_gen
    #(
        .LCD_WIDTH(LCD_WIDTH),   
        .LCD_HEIGHT(LCD_HEIGHT), 
            
        // pixel width;
        .SRC_BITS_PER_PIXEL(SRC_BITS_PER_PIXEL),
        .SINK_BITS_PER_PIXEL(SINK_BITS_PER_PIXEL)        
    )
    uut(.*);
    
    // test stimulus;
    core_video_lcd_test_pattern_gen_tb tb(.*);
   
       
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
        $monitor("time: %t, write: %0b, read: %0b, addr: %3b, wr_data: %d, rd_data: %3B, rgb: %4H, sink_ready: %0b, sink_valid: %0b, uut.frame_start: %0b, uut.frame_end: %0b",
        $time,
        write,
        read,
        addr,
        wr_data,
        rd_data,
        stream_out_rgb,
        sink_ready,
        sink_valid,
        uut.frame_start,
        uut.frame_end);
            
    end
    
endmodule

`endif //CORE_VIDEO_LCD_TEST_PATTERN_GEN_TOP_TB_SV