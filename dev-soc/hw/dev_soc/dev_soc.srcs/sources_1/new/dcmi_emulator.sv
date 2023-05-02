`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 15:35:30
// Design Name: 
// Module Name: dcmi_emulator
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
purpose : this emulates the OV7670 synchronization drivers;
why     : this is to simulate the signals for the dcmi_decoder module;

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

Frame Timing;
1. Refer to the Datasheet;
2. define:
    vlow    : the time period when the VSYNC is LOW (during idle);
    hlow    : the time period when the HREF is low during idle;
2. define;
    tpclk   : the time period of PCLK;
    tp      : if YUV/RGB, tp = 2*tpclk; 
    tline   : a constant: tline = 624*tp (approx.)

4. we have:
    tpclk   : 41.67 ns
    vlow    : at least, 3*tline = 2496*tpclk;
    hlow    : at least, 2*144*tp = 244*tpclk;
       
*/

/* assumption;
1. 24MHz pclk cannot be emulated using 100Mhz system clock;
2. instead, we shall emulate 25Mhz
*/

module dcmi_emulator
    #(parameter DATA_BITS = 8)
    (
        input logic clk_sys,    // 100 MHz;
        input logic reset_sys,  // async;
        
        // output; sycnhronization signals + dummy pixel data byte;
        output logic pclk,  // fixed at 25 MHz (cannot emulate 24MHz using 100MHz clock);
        output logic vsync, 
        output logic href,
        output logic [DATA_BITS-1:0] dout        
    );
    
    // constants;
    localparam PCLK_MOD = 4; // 100/4 = 25;
        
    // registers;
    logic [3:0] cnt_pclk_reg, cnt_pclk_next;    
    
    // simulate the pclk;
    always_ff @(posedge clk_sys, posedge reset_sys) begin
        if(reset_sys) begin
            cnt_pclk_reg <= 0;        
        end
        else begin
             cnt_pclk_reg <= cnt_pclk_next;        
        end    
    end
    
    assign cnt_pclk_next = (cnt_pclk_reg == PCLK_MOD-1) ? 0 : (cnt_pclk_reg + 1);
    always_comb begin
        pclk = 1'b0;
        if(cnt_pclk_reg < 2)
            pclk = 1'b1;
        else
            pclk = 1'b0;
    end
    
endmodule
