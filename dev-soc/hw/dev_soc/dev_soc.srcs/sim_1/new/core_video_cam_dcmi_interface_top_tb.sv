`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 17:44:55
// Design Name: 
// Module Name: core_video_cam_dcmi_interface_top_tb
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

`ifndef CORE_VIDEO_CAM_DCMI_INTERFACE_TOP_TB_SV
`define CORE_VIDEO_CAM_DCMI_INTERFACE_TOP_TB_SV

`include "IO_map.svh"

module core_video_cam_dcmi_interface_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    /* ------ uut signals; */
    localparam DATA_BITS = 8;
    localparam HREF_COUNTER_WIDTH  = 8;    // to count href;
    localparam HREF_TOTAL          = 3;  // expected to have 240 href for a line;
    localparam FRAME_COUNTER_WIDTH = 32;    // count the number of frames;
    
    // uut bus interface signals;
    logic cs;    
    logic write;              
    logic read;               
    logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr;  //  19-bit;         
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    // for downstream signals;
    logic [DATA_BITS-1:0] stream_out_data;
    logic sink_ready;     // signal from the sink to this interface;
    logic sink_valid;     // signal from this interface to the sink;
    
      // for debugging;
    logic debug_RST_FIFO;
    logic debug_FIFO_rst_ready;
    logic debug_decoder_complete_tick;
    logic debug_decoder_start_tick;
    logic debug_detect_vsync_edge;
      
    /* ----- signals for HW DCMI emulator; */
    localparam PCLK_MOD            = 4;    // 100/4;
    localparam VSYNC_LOW           = 10;   //vlow;
    localparam HREF_LOW            = 5;    // hlow; 
    localparam BUFFER_START_PERIOD = 7;    // between vsync assertion and href assertion;
    localparam BUFFER_END_PERIOD   = 5;	// between the frame end and the frame start;
    localparam PIXEL_BYTE_TOTAL    = 8;   // 320 pixels per href with bp = 16-bit; 
    localparam FIFO_RST_LOW_CYCLES = 3; // for macro fifo reset req;
    localparam FIFO_RST_HIGH_CYCLES = 6; // for macro fifo reset req;
    logic DCMI_PCLK;
    logic DCMI_VSYNC;
    logic DCMI_HREF;
    logic [DATA_BITS-1:0] DCMI_DOUT;    
     
    /* instantiation */
    // dcmi emulator to drive the DCMI sync signals for the uut;
    dcmi_emulator
    #(
        // for HW DCMI emulator;
        .PCLK_MOD(PCLK_MOD),            
        .VSYNC_LOW(VSYNC_LOW),           
        .HREF_LOW(HREF_LOW),            
        .BUFFER_START_PERIOD(BUFFER_START_PERIOD), 
        .BUFFER_END_PERIOD(BUFFER_END_PERIOD),
        .HREF_TOTAL(HREF_TOTAL),
        .PIXEL_BYTE_TOTAL(PIXEL_BYTE_TOTAL)             
    )
    dcmi_emulator_unit
    (
        .clk_sys(clk_sys),
        .reset_sys(reset_sys),
        .start(1),  // free running to simulate the actual cam ov7670 setting;
        .pclk(DCMI_PCLK),
        .vsync(DCMI_VSYNC),
        .href(DCMI_HREF),
        .dout(DCMI_DOUT),
               
        // not used;
        .frame_start_tick(),
        .frame_complete_tick()
        
    );
    
    // uut; dcmi decoder;
    core_video_cam_dcmi_interface
    #(
        .DATA_BITS(DATA_BITS),           
        .HREF_COUNTER_WIDTH(HREF_COUNTER_WIDTH),  
        .HREF_TOTAL(HREF_TOTAL),          
        .FRAME_COUNTER_WIDTH(FRAME_COUNTER_WIDTH), 
        
        // for macro bram fifo reset req;
        .FIFO_RST_LOW_CYCLES(FIFO_RST_LOW_CYCLES),
        .FIFO_RST_HIGH_CYCLES(FIFO_RST_HIGH_CYCLES)
     )
     uut
     (
        .clk_sys(clk_sys),    // 100 MHz;
        .reset_sys(reset_sys),  // async;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        .cs(cs),    
        .write(write),              
        .read(read),               
        .addr(addr),  //  19-bit;         
        .wr_data(wr_data),    
        .rd_data(rd_data),
        
        // specific external  signals;
        .DCMI_PCLK(DCMI_PCLK),
        .DCMI_HREF(DCMI_HREF),
        .DCMI_VSYNC(DCMI_VSYNC),
        .DCMI_DIN(DCMI_DOUT),
        
        // for downstream signals;
        .stream_out_data(stream_out_data),
        .sink_ready(sink_ready),     // signal from the sink to this interface;
        .sink_valid(sink_valid),     // signal from this interface to the sink;
        
        // for debugging;
        .debug_RST_FIFO(debug_RST_FIFO),
        .debug_FIFO_rst_ready(debug_FIFO_rst_ready),
        .debug_decoder_complete_tick(debug_decoder_complete_tick),
        .debug_decoder_start_tick(debug_decoder_start_tick),
        .debug_detect_vsync_edge(debug_detect_vsync_edge)
    
     );
     
     // test stimulus;
     core_video_cam_dcmi_interface_tb tb(.*);
     
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

    /* monitoring system */
    initial begin
        $monitor("time: %t, cs; %0b, write: %0b, read: %0b, addr: %D, wr_data: %8B, rd_data: %8H, stream_out_rgb: %8B, sink_ready: %0b, sink_vald: %0b, debug_fifo_ready: %0b, uut.decstart: %0b, uut.decend: %0b, uut.decoder_cmd_start: %0b",
        $time,
        cs,
        write,
        read,
        addr,
        wr_data,
        rd_data,
        stream_out_data,
        sink_ready,
        sink_valid,
        debug_FIFO_rst_ready,
        uut.decoder_start_tick,
        uut.decoder_complete_tick,
        uut.decoder_cmd_start
        );
       
    end    
endmodule

`endif //CORE_VIDEO_CAM_DCMI_INTERFACE_TOP_TB_SV
