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
        /*assumption;
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
        input logic increment,
        input logic sync_clr,   // synchrouse clear;
        
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
        input logic sink_read,       // sink is ready to accept new pixel;
        output logic [SINK_BITS_PER_PIXEL-1:0] pixel_sink
        
    );
    
    // signal;
    logic [COUNTER_WIDTH:0] x_reg, x_next;
    logic [COUNTER_WIDTH:0] y_reg, y_next;
    
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            x_reg <= 0;
            y_reg <= 0;            
        end
        // synchronous clear;
        else if(sync_clr) begin
            x_reg <= 0;
            y_reg <= 0;
        end
        else begin
            x_reg <= x_next;
            y_reg <= y_next;     
        end
   
   // counter logic;
   always_comb begin
        /* ----------------
        * x-coor;
        ------------------*/
        if(increment) begin
            // reach the boundary;
            // wrap around;
            if(x_reg == (LCD_WIDTH -1))
                x_next = 0;
            else
                x_next = x_reg + 1; 
        end
        // no increment? remain as it is;
        else begin
            x_next = x_reg;            
        end
        /* ----------------
        * y-coor;
        ------------------*/
        if(increment) begin
            // reach the boundary;
            // wrap around;
            if(y_reg == (LCD_HEIGHT -1))
                y_next = 0;
            else
                y_next = y_reg + 1; 
        end
        // no increment? remain as it is;
        else begin
            y_next = y_reg;            
        end
   end
   
   /* output; */
   // coordinate drive;
   assign x_coor = x_reg;
   assign y_coor = y_reg;
   
   // status;
   assign frame_start = ((x_reg == 0) && (y_reg == 0));
   assign frame_end = ((x_reg == (LCD_WIDTH - 1)) && (y_reg == (LCD_HEIGHT - 1)));
endmodule
