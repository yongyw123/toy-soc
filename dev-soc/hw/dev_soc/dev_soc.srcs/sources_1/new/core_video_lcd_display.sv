`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 23:05:40
// Design Name: 
// Module Name: core_video_lcd_display
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

`ifndef CORE_VIDEO_LCD_DISPLAY_SV
`define CORE_VIDEO_LCD_DISPLAY_SV

`include "IO_map.svh"

/**************************************************************
* V0_DISP_LCD
--------------------
this core wraps this module: LCD display controller 8080;
this is for the ILI9341 LCD display via mcu 8080 (protocol) interface;

this has six (6) registers;

background;

Register Map
1. register 0 (offset 0): status register 
2. register 1 (offset 1): program write clock period
3. register 2 (offset 2): program read clock period;
4. register 3 (offset 3): write data;
5. register 4 (offset 4): read data;
6. register 5 (offset 5): user commands;

Register Definition:
1. register 0: status register
        bit[0] ready flag;  // the lcd controller is 
        bit[1] done flag;   // [optional ??] when the lcd just finishes reading or writing;
        
2. register 1: program the write clock period;
        bit[15:0] defines the clock counter mod for LOW WRX period;
        bit[31:16] defines the clock counter mod for HIGH WRX period;

2. register 2: program the read clock period;
        bit[15:0] defines the clock counter mod for LOW RDX period;
        bit[31:16] defines the clock counter mod for HIGH RDX period;

3. regisert 3: write data;
        bit[7:0] data to write to the lcd;

4. register 4: read data;
        bit[7:0] data read from the lcd;
   
5. register 5: user commands;
        bit[1:0]: to store user commands;
        
Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;
4. register 3: write only;
5. register 4: read only;
6. register 5: write only;
******************************************************************/

module core_video_lcd_display
    #(
        parameter BITS_PER_PIXEL = 16 // bpp
    )
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data
                
    );
endmodule

`endif //CORE_VIDEO_LCD_DISPLAY_SV