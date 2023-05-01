`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 01:33:15
// Design Name: 
// Module Name: dcmi_decoder
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
purpose         : decoding logic for OV7670 camera;
what to decode  : OV7670 synchronization signals;
caution         : this interface is driven by the OV7670 camera clock (PCLK);
                so, this is asynchronous; need a dual-clock fifo
                for cross-clock domain;
                
assumption      : assume camera synchronization signal settings are fixed; 
               
OV7670 setting:
1. Resolution: QVGA (320 x 240);
2. Format: RGB565 or YUV422                           
3. Bits per pixel: 16-bit;

OV7670 Synchronization Setting;
1. PCLK     : 24 MHz;
2. HREF     : changes at the falling edge of PCLK;
   HREF     : active high (low during idle);
3. VSYNC    : chnages at the falling edge of PCLK;
   VSYNC    : active high (low during idle);
4. DATA     : updated by OV7670 at the falling edge of PCLK;
   DATA     : changes simultaneously with HREF (no delay after HREF changes);
   
Rough Construction:
1. By above, we use VSYNC to detect the start and the end of a frame;
2. Use HREF signal to start the Data sampling;
3. Data sampling occurs at the rising edge of PCLK;

Frame Timing;
1. Refer to the Datasheet;
2. define:
    vlow    : the time period when the VSYNC is LOW (during idle);
    hlow    : the time period when the HREF is low during idle;
2. define;
    tpclk   : the time period of PCLK;
    tp      : if YUV/RGB, tp = 2*tpclk; 
    tline   : a constant: tline = 784*tp;

4. we have:
    tpclk   : 41.67 ns
    vlow    : 3*tline = 4704*tpclk;
    hlow    : at least >= 2*144*tp = 244*tpclk;  
*/

module dcmi_decoder
    #(parameter 
        DATA_BITS = 8   // camera ov7670 drives 8-bit parallel data;
     )
    (
        // general;
        input logic reset_sys,    // async from the system (not camera);
        
        // driving inputs from the camera ov7670;
        input logic pclk,  // fixed at 24MHz;
        input logic href,
        input logic vsync,
        input logic [DATA_BITS-1:0] din,
        
        // interface the dual-clock fifo;
        output logic data_valid, // to the fifo;
        input logic data_ready,  // from the fifo;
        output logic [DATA_BITS-1:0] dout   // sampled pixel data from the cam;
        
    );
    
    
endmodule
