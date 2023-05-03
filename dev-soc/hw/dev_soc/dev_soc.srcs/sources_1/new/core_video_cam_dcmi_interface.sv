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
4. register 3 (offset 3): BRAM FIFO status register;
5. register 4 (offset 4): BRAM FIFO read and write counter;  

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

4. register 3: BRAM FIFO status register;
        bit[0] - almost empty;
        bit[1] - almost full;
        bit[2] - empty;
        bit[3] - full;
        bit[4] - read error;
        bit[5] - write error;

5. register 4: BRAM FIFO read and write counter;
        bit[10:0]   - read count;
        bit[21:11]  - write count;      
            

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
    localparam REG_CTRL_OFFSET          = 3'b000;
    localparam REG_STATUS_OFFSET        = 3'b001;
    localparam REG_FRAME_OFFSET         = 3'b010;
    localparam REG_FIFO_STATUS_OFFSET   = 3'b011;
    localparam REG_FIFO_CNT_OFFSET      = 3'b100;
    
    // enablers;
    logic wr_en;
    logic wr_ctrl_en;
    logic rd_en;    
    
    // user command signals;
    logic select_emulator_or_cam;
    logic decoder_cmd_start;
    logic emulator_cmd_start;
    
    // signals for decoder;
    logic decoder_complete_tick;
    logic decoder_start_tick;
    logic [FRAME_COUNTER_WIDTH-1:0] decoded_frame_counter;
    
    // interface signals between decoder and the sinking dual-clock fifo;
    logic decoder_data_valid;
    logic decoder_data_ready;
    logic [DATA_BITS-1:0] decoder_dout;
    
    // signals for dual clock bram fifo;
    localparam FIFO_DEPTH_BIT = 11;
    
    logic FIFO_almost_empty;
    logic FIFO_almost_full;
    logic [DATA_BITS-1:0] FIFO_dout;
    logic FIFO_empty;
    logic FIFO_full;
    logic [DATA_BITS-1:0] FIFO_din;
    logic FIFO_rd_en;
    logic FIFO_wr_en;
    
    logic FIFO_rd_error;    
    logic [FIFO_DEPTH_BIT-1:0] FIFO_rd_count;
    
    logic FIFO_wr_error;    
    logic [FIFO_DEPTH_BIT-1:0] FIFO_wr_count;
    
    /* registers;
    1. no need to explicitly create for frame counter read register;
        this has already been registered in the dcmi_decoder module;
    2. need to create for the rest;
    */
    logic [`REG_DATA_WIDTH_G-1:0] ctrl_reg, ctrl_next;
    logic [`REG_DATA_WIDTH_G-1:0] status_reg, status_next;
    logic [`REG_DATA_WIDTH_G-1:0] fifo_status_reg, fifo_status_next;
    logic [`REG_DATA_WIDTH_G-1:0] fifo_cnt_reg, fifo_cnt_next;
    
    
    always_ff @(posedge clk_sys, reset_sys) begin
        if(reset_sys) begin
            ctrl_reg    <= 0;
            status_reg  <= 0;
            fifo_status_reg <= 0;
            fifo_cnt_reg    <= 0;                
        end
        else begin
            if(wr_ctrl_en) begin
                ctrl_reg    <= ctrl_next;
            end
            status_reg      <= status_next;
            fifo_status_reg <= fifo_status_next;
            fifo_cnt_reg    <= fifo_cnt_next;
            
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
     
    /* ------ reading */
    assign rd_en = (read && cs);
    assign status_next = {30'b0, decoder_complete_tick, decoder_start_tick};
    assign fifo_status_next = {26'b0, FIFO_wr_error, FIFO_rd_error, FIFO_full, FIFO_empty, FIFO_almost_full, FIFO_almost_empty};
    assign fifo_cnt_next = {10'b0, FIFO_wr_count, FIFO_rd_count};

    always_comb begin
        // default;
        rd_data = {32{1'b0}};
        case({rd_en, addr[2:0]})
            {1'b1, REG_STATUS_OFFSET}       : rd_data = status_reg;
            {1'b1, REG_FRAME_OFFSET}        : rd_data = decoded_frame_counter;
            {1'b1, REG_FIFO_STATUS_OFFSET}  : rd_data = fifo_status_reg;
            {1'b1, REG_FIFO_CNT_OFFSET}     : rd_data = fifo_cnt_reg;            
            default: ; // nop;
        endcase
    end
    
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
        .decoded_frame_counter(decoded_frame_counter),
        .decoder_complete_tick(decoder_complete_tick),
        .decoder_start_tick(decoder_start_tick),
        
        // not used;
        .debug_detect_vsync_edge()
     );
     
    /* ----- mapping between the dcmi decoder and the fifo; */
    assign FIFO_wr_en           = (decoder_data_valid && !FIFO_full);        
    assign FIFO_din             = decoder_dout;   
    assign decoder_data_ready   = !FIFO_almost_full;
    
    // mapping between the fifo with the downstream ;
    assign FIFO_rd_en       = (sink_ready && !FIFO_empty);
    assign stream_out_data  = FIFO_dout;
    assign sink_valid       = !FIFO_empty;     
    
    // dual clock bram fifo;
    /* fifo sinking the pixel decoded from the dcmi_decoder */
    // FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
    //                       Artix-7
    // Xilinx HDL Language Template, version 2021.2
    
    /////////////////////////////////////////////////////////////////
    // DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
    // ===========|===========|============|=======================//
    //   37-72    |  "36Kb"   |     512    |         9-bit         //
    //   19-36    |  "36Kb"   |    1024    |        10-bit         //
    //   19-36    |  "18Kb"   |     512    |         9-bit         //
    //   10-18    |  "36Kb"   |    2048    |        11-bit         //
    //   10-18    |  "18Kb"   |    1024    |        10-bit         //
    //    5-9     |  "36Kb"   |    4096    |        12-bit         //
    //    5-9     |  "18Kb"   |    2048    |        11-bit         //
    //    1-4     |  "36Kb"   |    8192    |        13-bit         //
    //    1-4     |  "18Kb"   |    4096    |        12-bit         //
    /////////////////////////////////////////////////////////////////

    FIFO_DUALCLOCK_MACRO  #(
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(DATA_BITS),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DEVICE("7SERIES"),  // Target device: "7SERIES" 
      .FIFO_SIZE ("18Kb"), // Target BRAM: "18Kb" or "36Kb" 
      .FIRST_WORD_FALL_THROUGH ("TRUE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
    ) bram_fifo_dual_clock_unit (
      .ALMOSTEMPTY(FIFO_almost_empty), // 1-bit output almost empty
      .ALMOSTFULL(FIFO_almost_full),   // 1-bit output almost full
      .DO(FIFO_dout),                   // Output data, width defined by DATA_WIDTH parameter
      .EMPTY(FIFO_empty),             // 1-bit output empty
      .FULL(FIFO_full),               // 1-bit output full
      .RDCOUNT(FIFO_rd_count),         // Output read count, width determined by FIFO depth
      .RDERR(FIFO_rd_error),             // 1-bit output read error
      .WRCOUNT(FIFO_wr_count),         // Output write count, width determined by FIFO depth
      .WRERR(FIFO_wr_error),             // 1-bit output write error
      .DI(FIFO_din),                   // Input data, width defined by DATA_WIDTH parameter
      .RDCLK(clk_sys),             // 1-bit input read clock
      .RDEN(FIFO_rd_en),               // 1-bit input read enable      
      .RST(reset_sys),                 // 1-bit input reset
      .WRCLK(PCLK),             // 1-bit input write clock
      .WREN(FIFO_wr_en)                // 1-bit input write enable
    );
           
      
    
endmodule

`endif //CORE_VIDEO_CAM_DCMI_INTERFACE_SV