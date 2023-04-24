`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 15:21:48
// Design Name: 
// Module Name: fifo_core_video_lcd_display
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

/*
Construction: 
this is a FIFO buffer between the pixel generation (source) and the sink (lcd)
via the core_video_lcd_display_module();

Sink Device:
1. LCD ILI9341
2. Interface Protocol: MCU 8080-I series;
*/


module fifo_core_video_lcd_display
    #(parameter
        DATA_WIDTH = 8,     // this corresponds to LCD parallel 8-bit;
        ADDR_WIDTH = 5  // 2^5 = 32 fifo depth;
    )
    (
        // general;
        input clk,  // system clock; 100MHz;
        input reset, // async;
        
        // source: left side of the fifo;
        input logic [DATA_WIDTH-1:0] src_data,   // 8 bits;
        input logic src_valid,   // source data is ready; perform the write;
        output logic src_ready,  // fifo is ready to accept new data;
        
        // sink: right side of the fifo;
        output logic [DATA_WIDTH-1:0] sink_data,
        output logic sink_valid, // fifo is non-empty;
        input logic sink_ready // the sink is ready to ready data from this fifo;
       
    );
    
    
    logic almost_empty; // not used;
    logic almost_full;
    logic flag_full;         // not used;
    logic flag_empty;
    
    assign sink_valid = !flag_empty;  // as soon as the fifo has some data;
    assign src_ready = !flag_full;    
    
    FIFO
    #(.DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH))
    fifo_unit
    (
        .clk(clk),
        .reset(reset),
        .ctrl_rd(sink_ready), // read request;
        .ctrl_wr(src_valid), // write request;
        .flag_empty(flag_empty),
        .flag_full(flag_full),
        
        .rd_data(sink_data),
        .wr_data(src_data)
	);			
endmodule
