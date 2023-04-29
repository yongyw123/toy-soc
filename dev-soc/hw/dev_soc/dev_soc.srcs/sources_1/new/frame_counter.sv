`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.04.2023 20:45:36
// Design Name: 
// Module Name: frame_counter
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
purpose : frame counter to drive pixel generation modules;
how     : it uses the (x,y) coordinate to represent the pixel location;

intended display device: 
device      : LCD-TFT ILI9341
interface   : MCU 8080-I series protocol;
note        : this device is configured to use 16-bit but driven on 8-bit parallel data bits;

assumption + construction:
1. by above, this frame counter drives the pixel generation modules that generates
    16-bit per pixel; 
2. but unpack the 16-bit to 8-bit "on-the-fly";
*/

module frame_counter
    #(parameter 
        // lcd dimension;  
        /* assumption;
            this assumes that the LCD scanning direction
            is width x height;
        
        otherwise; the LCD display will display gibberish; 
        */
        LCD_WIDTH = 240,   
        LCD_HEIGHT = 320, 
        
        // counter width; for the dimension above;
        COUNTER_WIDTH = 10,
        
        // pixel width;
        SRC_BITS_PER_PIXEL = 16,    // coming from the source;
        SINK_BITS_PER_PIXEL = 8     // for the sink;
    )
    (
        /* standard signals */
        input logic clk,
        input logic reset,      // asynchronous reset;
        
        /* general interface */
        // command from the control centre to start the counter;
        input logic cmd_start,         
        
        // synchronous clear the counter for convenience;
        input logic sync_clr,
        
        // status;
        output logic frame_start,
        output logic frame_end,
        
        /* interface with the pixel generation modules */
        input logic [SRC_BITS_PER_PIXEL-1:0] pixel_src,
        // coordinate driver to dictate the source;
        output logic [COUNTER_WIDTH:0] xcoor,
        output logic [COUNTER_WIDTH:0] ycoor,
                
        /* interface with the sink; */
        output logic sink_valid,    // signal to the sink that there is output;
        input logic sink_ready,       // sink is ready to accept new pixel;
        output logic [SINK_BITS_PER_PIXEL-1:0] pixel_sink
    );
    
    // signal;
    logic [COUNTER_WIDTH:0] x_reg, x_next;
    logic [COUNTER_WIDTH:0] y_reg, y_next;        
    logic [1:0] unpack_pointer_reg, unpack_pointer_next;    
    
    // enabler;
    logic increment_counter;
    
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            x_reg <= 0;
            y_reg <= 0;                 
            unpack_pointer_reg <= 0;                  
        end
        
        else if(sync_clr) begin
            x_reg <= 0;
            y_reg <= 0;                 
            unpack_pointer_reg <= 0;
        end
        
        else begin
            x_reg <= x_next;
            y_reg <= y_next;                
            unpack_pointer_reg <= unpack_pointer_next;             
        end
   
   // counter next state logic;
   always_comb begin
        // default;
        x_next = x_reg;
        y_next = y_reg;
        /* ----------------
        * x-coor;
        ------------------*/
        if(increment_counter) begin
            // reach the boundary;
            // wrap around;
            if(x_reg == (LCD_WIDTH -1))
                x_next = 0;
            else
                x_next = x_reg + 1; 
        end
        
        /* ----------------
        * y-coor;
        ------------------*/
        // only move to the next y-line after previous x-column is complete;
        if(increment_counter && (x_reg == (LCD_WIDTH - 1))) begin
            // reach the boundary;
            // wrap around;
            if(y_reg == (LCD_HEIGHT -1))
                y_next = 0;
            else
                y_next = y_reg + 1; 
        end        
   end
   
   // next state logic on when to enable the counter;
   always_comb begin
        // default;
        unpack_pointer_next = unpack_pointer_reg;
        increment_counter = 1'b0; 
        sink_valid = 1'b0;
        
        // the first byte of the same 16-bit pixel;
        if(unpack_pointer_reg == 0) begin            
            // if the sink could still accept more data;
            if(cmd_start && sink_ready) begin
                sink_valid = 1'b1;
                unpack_pointer_next = unpack_pointer_reg + 1;
            end                       
        end
        
        // move on the second byte of the same pixel;
        else if(unpack_pointer_reg == 1) begin
            // if the sink could still accept more data;
            if(cmd_start && sink_ready) begin
                sink_valid = 1'b1;
                unpack_pointer_next = 0;    // reset;
                
                // current pixel is done; next pixel;            
                increment_counter = 1'b1;
            end
        end
   end
   
   // unpacking for pixel sink
   always_comb begin
        // default;
        pixel_sink = pixel_src[3:0]; 
        
        // unpack the MSB for the first byte to send;
        if(unpack_pointer_reg == 0) begin
            pixel_sink = pixel_src[15:8];
        end
        
        // move on to the next byte of the same pixel;
        else if(unpack_pointer_reg == 1) begin
            pixel_sink = pixel_src[7:0];
        end                  
   end
      
   /* output; */
   // interface with the pixel source;
   assign xcoor = x_reg;
   assign ycoor = y_reg;
   
   // status;
   assign frame_start = ((x_reg == 0) && (y_reg == 0));
   assign frame_end = ((x_reg == (LCD_WIDTH - 1)) && (y_reg == (LCD_HEIGHT - 1)));
endmodule
