`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 15:50:11
// Design Name: 
// Module Name: fifo_core_video_lcd_display_top_tb
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


module fifo_core_video_lcd_display_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    /* signal declare; */
    localparam DATA_WIDTH = 8;
    
    // source: left side of the fifo;
    logic [DATA_WIDTH-1:0] src_data;   // 8 bits;
    logic src_valid;   // source data is ready; perform the write;
    logic src_ready;  // fifo is ready to accept new data;
    
    // sink: right side of the fifo;
    logic [DATA_WIDTH-1:0] sink_data;
    logic sink_valid; // fifo is non-empty;
    logic sink_ready; // the sink is ready to ready data from this fifo;
    
    // instantiation;
    fifo_core_video_lcd_display 
    #(.DATA_WIDTH(DATA_WIDTH))
    uut
    (.*);
    
    // test stimulus;
    fifo_core_video_lcd_display_tb
    #(.DATA_WIDTH(DATA_WIDTH))
    tb
    (.*);
    
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
            sink_ready = 1'b0;
            src_valid = 1'b0;
            
            reset = 1'b1;
            #(T/2);
            #(100*T);
            reset = 1'b0;
            #(T/2);
        end
        
     /* monitoring */
     initial begin
        $monitor("time: %10t, src_data: %8B, src_valid: %b, src_ready: %b, sink_data: %8B, sink_valid: %b, sink_ready: %b",
        $time,
        src_data,
        src_valid,
        src_ready,
        sink_data,
        sink_valid,
        sink_ready
        );
        
     
     end
    
endmodule
