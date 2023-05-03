`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 15:13:39
// Design Name: 
// Module Name: core_video_cam_dcmi_interface
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


/**************************************************************
* V3_CAM_DCMI_IF
-----------------------
Camera DCMI Interface

Purpose:
1. Mainly, to interface with camera OV7670 which drives the synchronization signals;
2. Note that this is asynchronous since this module is driven by OV7670 24MHz PCLK;

Constituent Block:
1. A dual-clock BRAM FIFO for the cross time domain;
2. A mux to select between the actual camera ov7670 OR
     a HW testing-circuit which emulates the DCMI signals;
3. the HW DCMI emulator itself;
      
Assumptions:
1. The synchronization signal settings are fixed; 
    thus; require the camera to be configured apriori;
    

Register Map
1. register 0 (offset 0): control register;
2. register 1 (offset 1): status register;
3. register 2 (offset 2): frame counter read register;  

Register Definition:
1. register 0: control register;
    bit[0] select which to source: the HW emulator or the camera;
            0 for HW emulator; 
            1 for camera OV7670;
    bit[1] start the decoder;
            0 to disable the decoder;
            1 to enable the decoder;
    bit[2] start the HW emulator;
            0 disabled;
            1 enabled;
             
2. register 1: status register;
    bit[0] detect the start of a frame
        1 yes; 
        0 otherwise
        *this will clear by itself;
    bit[1] detect the end of a frame (finish decoding);
        1 yes;
        0 otherwise;
        *this will clear by itself;
        
3. register 2: frame counter read register;
        bit[31:0] to store the number of frame detected;
        *note: 
            - this will overflow and wrap around;
            - will clear to zero after a system reset;
            

Register IO access:
1. register 0: write and read;
2. register 1: read only;
3. register 2: read only;
******************************************************************/

`ifndef CORE_VIDEO_CAM_DCMI_INTERFACE_SV
`define CORE_VIDEO_CAM_DCMI_INTERFACE_SV

`include "IO_map.svh"

module core_video_cam_dcmi_interface
    #(parameter
        // for dcmi;
        DATA_BITS           = 8,    // camera ov7670 drives 8-bit parallel data;
        HREF_COUNTER_WIDTH  = 8,    // to count href;
        HREF_TOTAL          = 240,  // expected to have 240 href for a line;
        FRAME_COUNTER_WIDTH = 32,    // count the number of frames;
        
        // for HW DCMI emulator;
        PCLK_MOD            = 4,    // 100/4 = 25;
        VSYNC_LOW           = 10,   //vlow;
        HREF_LOW            = 5,    // hlow; 
        BUFFER_START_PERIOD = 7,    // between vsync assertion and href assertion;
        BUFFER_END_PERIOD 	= 5,	// between the frame end and the frame start;
        PIXEL_BYTE_TOTAL    = 640   // 320 pixels per href with bp = 16-bit; 
        
    )
    (
        // system input;
        input logic clk_sys,    // 100 MHz;
        input logic reset_sys,  // async;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // specific external input signals;
        input logic PCLK,
        input logic HREF,
        input logic VSYNC,
        input logic [DATA_BITS-1:0] DIN,
        
        // for downstream signals;
        output logic [DATA_BITS-1:0] stream_out_data,
        input logic sink_ready,     // signal from the sink to this interface;
        output logic sink_valid     // signal from this interface to the sink;
         
    );
    
    // constanst
    localparam REG_CTRL_OFFSET      = 3'b000;
    localparam REG_STATUS_OFFSET    = 3'b001;
    localparam REG_FRAME_OFFSET     = 3'b010;
    
    // enablers;
    logic wr_en;
    logic wr_ctrl_en;
    logic rd_en;    
    
    // user command signals;
    logic select_emulator_or_cam;
    logic decoder_cmd_start;
    logic emulator_cmd_start;
    
    // interface signals between decoder and the sinking dual-clock fifo;
    logic decoder_data_valid;
    logic decoder_data_ready;
    logic [DATA_BITS-1:0] decoder_dout;
    
    
    /* registers;
    1. no need to explicitly create for frame counter read register;
        this has already been registered in the dcmi_decoder module;
    2. need to create for the rest;
    */
    logic [`REG_DATA_WIDTH_G-1:0] ctrl_reg, ctrl_next;
    logic [`REG_DATA_WIDTH_G-1:0] status_reg, status_next;
    
    always_ff @(posedge clk_sys, reset_sys) begin
        if(reset_sys) begin
            ctrl_reg    <= 0;
            status_reg  <= 0;                
        end
        else begin
            if(wr_ctrl_en) begin
                ctrl_reg    <= ctrl_next;
            end
            status_reg  <= status_next;
        end
    end
    
    /* -------- writing */
    // decoding;
    assign wr_en = write && cs;
    assign wr_ctrl_en = (wr_en && addr[2:0] == REG_CTRL_OFFSET);
    // next state;
    assign ctrl_next = wr_data;
    // mapping;
    assign select_emulator_or_cam   = ctrl_reg[`V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_MUX];
    assign decoder_cmd_start        = ctrl_reg[`V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_START];
    assign emulator_cmd_start       = ctrl_reg[`V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_EM_START];
     
     
     /* --------------  instantiations */
     // decoder;
     dcmi_decoder
     #(
        .DATA_BITS(DATA_BITS),
        .HREF_COUNTER_WIDTH(HREF_COUNTER_WIDTH),
        .HREF_TOTAL(HREF_TOTAL),         
        .FRAME_COUNTER_WIDTH(FRAME_COUNTER_WIDTH)
     )
     dcmi_decoder_unit
     (
        // system;
        .reset_sys(reset_sys),
        .cmd_start(decoder_cmd_start),
        
        // dcmi interface;
        .pclk(PCLK),        // not 100MHz (asynchronous to the system);
        .href(HREF),
        .vsync(VSYNC),
        .din(DIN),
        
        // interface with the internal dual clock fifo write port;
        .data_valid(decoder_data_valid),
        .data_ready(decoder_data_ready),
        .dout(decoder_dout),
        
        // status;
        .decoded_frame_counter(),
        .decoder_complete_tick(),
        .decoder_start_tick(),
        
        // not used;
        .debug_detect_vsync_edge()
     );
     

    // dual clock bram fifo;
         
    
endmodule

`endif //CORE_VIDEO_CAM_DCMI_INTERFACE_SV