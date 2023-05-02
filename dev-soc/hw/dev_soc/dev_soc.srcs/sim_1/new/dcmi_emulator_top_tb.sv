`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 16:03:20
// Design Name: 
// Module Name: dcmi_emulator_tb
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


module dcmi_emulator_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    // uut signals
    localparam DATA_BITS = 8;
    logic pclk;  // fixed at 25 MHz (cannot emulate 24MHz using 100MHz clock);
    logic vsync; 
    logic href;
    logic [DATA_BITS-1:0] dout;
    logic start;
    logic frame_complete_tick;
    logic frame_start_tick;
    
    /* uut parameters; */
    localparam PCLK_MOD            = 4;     // 100/4 = 25;
    localparam VSYNC_LOW           = 10;    //vlow;
    localparam HREF_LOW            = 5;     // hlow; 
    localparam BUFFER_START_PERIOD = 10;    // between vsync assertion and href assertion;
    localparam BUFFER_END_PERIOD   = 1;	    // between the frame end and the frame start;
    localparam HREF_TOTAL          = 5;     // total href assertion to generate;
    localparam PIXEL_BYTE_TOTAL    = 10;    // 320 pixels per href with bp = 16-bit; 
    
    
    /* simulate clk */
     always
        begin 
           clk_sys = 1'b1;  
           #(T/2); 
           clk_sys = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset_sys = 1'b1;
            #(T/2);
            reset_sys = 1'b0;
            #(T/2);
        end
     
     // uut;
     dcmi_emulator
     #(
     .DATA_BITS(DATA_BITS),
     .PCLK_MOD(PCLK_MOD),
     .VSYNC_LOW(VSYNC_LOW),
     .HREF_LOW(HREF_LOW),
     .BUFFER_START_PERIOD(BUFFER_START_PERIOD),
     .BUFFER_END_PERIOD(BUFFER_END_PERIOD),
     .HREF_TOTAL(HREF_TOTAL),
     .PIXEL_BYTE_TOTAL(PIXEL_BYTE_TOTAL)
     )
     uut
     (.*);
     
     // test stimulus;
     dcmi_emulator_tb tb(.*);
     
     /* monitoring */
     
     initial begin
        $monitor("time: %t, start: %0b, vsync: %0b, href: %0b, dout: %8B, frame_start: %0b, frame_end: %0b, uut.state_reg: %s",
        $time,
        start,
        vsync,
        href,
        dout,
        frame_start_tick,
        frame_complete_tick,
        uut.state_reg.name        
        );
     end     
endmodule
