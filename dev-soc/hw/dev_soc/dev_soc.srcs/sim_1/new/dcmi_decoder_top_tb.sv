`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 21:17:16
// Design Name: 
// Module Name: dcmi_decoder_top_tb
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


module dcmi_decoder_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    // constants;
    localparam DATA_BITS = 8;
    
    
    // signals for dcmi emulator to test the dcmi decoder;
    logic pclk;
    logic emulator_start;
    logic vsync;
    logic href;
    logic [DATA_BITS-1:0] emulator_dout;
    logic frame_start_tick;
    logic frame_complete_tick;
    
    localparam PCLK_MOD            = 4;   // 100/4 = 25;
    localparam VSYNC_LOW           = 10;   //vlow;
    localparam HREF_LOW            = 5;    // hlow; 
    localparam BUFFER_START_PERIOD = 7;    // between vsync assertion and href assertion;
	localparam BUFFER_END_PERIOD   = 5;	// between the frame end and the frame start;
    localparam HREF_TOTAL          = 4;  // total href assertion to generate;
    localparam PIXEL_BYTE_TOTAL    = 14;   // 320 pixels per href with bp = 16-bit;
     
    
    // signals for uut: dcmi decoder;
    logic decoder_start;
    logic decoder_data_valid;
    logic decoder_data_ready;
    logic [DATA_BITS-1:0] decoder_dout;
    
    /* instantiation */
    // dcmi emulator;
    dcmi_emulator
    #(
        .PCLK_MOD(PCLK_MOD), 
        .VSYNC_LOW(VSYNC_LOW),
        .HREF_LOW(HREF_LOW),  
        .BUFFER_START_PERIOD(BUFFER_START_PERIOD),
        .BUFFER_END_PERIOD(BUFFER_END_PERIOD), 	
        .HREF_TOTAL(HREF_TOTAL),          
        .PIXEL_BYTE_TOTAL(PIXEL_BYTE_TOTAL)     
    )
    emulator_unit
    (
        .clk_sys(clk_sys),
        .reset_sys(reset_sys),
        .start(emulator_start),
        .pclk(pclk),
        .vsync(vsync),
        .href(href),
        .dout(emulator_dout),
        .frame_start_tick(frame_start_tick),
        .frame_complete_tick(frame_complete_tick)    
    );
    
    // uut;
    dcmi_decoder
    #(
        .DATA_BITS(DATA_BITS),
        .HREF_COUNTER_WIDTH(8),
        .HREF_TOTAL(HREF_TOTAL),
        .FRAME_COUNTER_WIDTH(32) 
    )
    uut
    (
        .reset_sys(reset_sys),
        .cmd_start(decoder_start),
        .pclk(pclk),
        .href(href),
        .vsync(vsync),
        .din(emulated_dout),
        .data_valid(decoder_data_valid),
        .data_ready(decoder_data_ready),
        .dout(decoder_dout)
        
    );
    
    // test stimulus;
     dcmi_decoder_tb tb(.*);
     
    
    
    /* simulate system clk */
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
        

endmodule
