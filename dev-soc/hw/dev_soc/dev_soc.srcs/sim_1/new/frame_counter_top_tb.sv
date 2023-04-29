`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.04.2023 00:41:44
// Design Name: 
// Module Name: frame_counter_top_tb
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


module frame_counter_top_tb();
// general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    /* constants */
    //  no need to go through the actual LCD dimension: 240 x 320;
    localparam LCD_WIDTH = 3;
    localparam LCD_HEIGHT = 1;
   
    // pixel width;
    localparam SRC_BITS_PER_PIXEL = 16;    // coming from the source;
    localparam SINK_BITS_PER_PIXEL = 8;    // for the sink;
    localparam COUNTER_WIDTH = 10;
    
    /* uut arguments; */
        
    // command from the control centre to start the counter;
    logic cmd_start;          // input;
    
    // status;
    logic frame_start;   // output
    logic frame_end;     // output;
    
    /* interface with the pixel generation modules */
    logic [SRC_BITS_PER_PIXEL-1:0] pixel_src; // input;
    
    // coordinate driver to dictate the source;
    logic [COUNTER_WIDTH:0] xcoor;  // output;
    logic [COUNTER_WIDTH:0] ycoor; // output;
            
    /* interface with the sink; */
    logic frame_sink_valid;    // signal to the sink that there is output; output;
    logic frame_sink_ready;       // sink is ready to accept new pixel; input;
    logic [SINK_BITS_PER_PIXEL-1:0] pixel_sink; // output;

    /* fifo arguments */
    logic [SINK_BITS_PER_PIXEL-1:0] fifo_sink_data;
    logic fifo_sink_valid;
    logic fifo_sink_ready;
    
    /* simulate a pixel generation module driven by the uut */
    always_comb begin
        // have the upper byte different than the lower byte;
        // for testing convenience;
        pixel_src = {(1'b1 + 7'(xcoor)), (8'(xcoor))};     
    end
    
    /* instantiation */
    frame_counter 
    #(
    .LCD_WIDTH(LCD_WIDTH),
    .LCD_HEIGHT(LCD_HEIGHT), 
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .SRC_BITS_PER_PIXEL(SRC_BITS_PER_PIXEL),
    .SINK_BITS_PER_PIXEL(SINK_BITS_PER_PIXEL)    
    )
    uut(.*, .sink_ready(frame_sink_ready), .sink_valid(frame_sink_valid));
    
    // test stimulues;
    frame_counter_tb tb(.*);
    
    /* simulate the sink using a fifo */
    // fifo interface acting as the sink;
   
   fifo_core_video_lcd_display 
    #(
    .DATA_WIDTH(SINK_BITS_PER_PIXEL),
    .ADDR_WIDTH(8) // could hold up to 2^3 = 8 data; 
    )
    fifo_src
    (
    .clk(clk),
    .reset(reset),
    // from the frame counter;
    .src_data(pixel_sink),
    .src_valid(frame_sink_valid),
    .src_ready(frame_sink_ready), 
    
    // not used;
    .sink_data(fifo_sink_data),
    .sink_valid(fifo_sink_valid),
    .sink_ready(fifo_sink_ready)
    );
    
    /* simulate clk */
     always
        begin 
           clk = 1'b1;  
           #(T/2); 
           clk = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse and value initialization */
     initial
        begin
           // initialize other value;
           fifo_sink_ready = 1'b0;
           cmd_start = 1'b0;
           
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end
   
    
    /* monitoring */
    initial begin
        $monitor("time: %t, cmd_start: %0b, frame_start: %0b, frame_end: %0b, pixel_src: %16B, xcoor: %d, ycoor: %d, sink_valid: %0b, sink_ready: %0b, pixel_sink: %8B, uut.xreg: %d, uut.yreg: %d, fifo_sink_data: %8B, fifo_sink_valid: %0b, fifo_sink_ready: %0b",
        $time,
        cmd_start,
        frame_start,
        frame_end,
        pixel_src,
        xcoor,
        ycoor,
        frame_sink_valid,
        frame_sink_ready,
        pixel_sink,
        uut.x_reg,
        uut.y_reg,
        fifo_sink_data,
        fifo_sink_valid,
        fifo_sink_ready);
          
    
    end

endmodule
