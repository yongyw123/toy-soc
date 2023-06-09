`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 21:52:53
// Design Name: 
// Module Name: video_sys
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

`ifndef _VIDEO_SYS_SV
`define _VIDEO_SYS_SV

`include "IO_map.svh"

module video_sys
    #(
        parameter 
        // ov7670 camera pixel output is configured to be 16-bit;
        BITS_PER_PIXEL = 16,   
        
        
        /* buffer between the src and the lcd display; */
        // since the lcd display could only be driven by 8-bit parallel max;
        LCD_DISPLAY_DATA_WIDTH = 8,
        FIFO_LCD_ADDR_WIDTH = 8      // 2^8;
    )
    (
        // general;
        input logic clk_sys,    // 100 MHz;
        input logic reset,  // async;                
        
        /*
        // user bus interface;
        // where user bus is bridged by the microblaze MCS IO bus;
 
        */
        input logic video_cs,        // chip select for mmio system;
        input logic video_wr,
        input logic video_rd,
        input logic [`BUS_USER_SIZE_G-1:0] video_addr,       // addr to decode for IO core address and its register address;
        input logic [`REG_DATA_WIDTH_G-1:0] video_wr_data,   // 32-bit;
        output logic [`REG_DATA_WIDTH_G-1:0] video_rd_data,  // 32-bit;
        
        /* --------- HW pin mapping (by the constraint file) ------------*/
        
        /* LCD display (ILI9341); */
        output logic lcd_drive_wrx,     //  to drive the lcd for write op;
        output logic lcd_drive_rdx,     // to drive the lcd for read op;
        output logic lcd_drive_csx,     // chip select;
        output logic lcd_drive_dcx,     // data or command; LOW for command;          
        
        // this is shared between the host and the lcd;
        inout tri[LCD_DISPLAY_DATA_WIDTH-1:0] lcd_dinout, 
        
        /* camera ov7670 sync signals and data */
        input logic dcmi_pclk,       // driven by the camera at 24 MHz;
        input logic dcmi_vsync,      // vertical synchronization;
        input logic dcmi_href,       // horizontal synchronization;
        input logic [7:0] dcmi_pixel, // 8-bit pixel data;
        
        /* MIG interface core; */
        output logic [15:0] LED,
        input logic MMCM_locked,    // MMCM locked status;
        input logic clk_mem,        // 200MHz to drive the MIG;
        
        // ddr2 sdram memory interface (defined by the imported ucf file);
        output logic [12:0] ddr2_addr,   // address; 
        output logic [2:0]  ddr2_ba,    
        output logic ddr2_cas_n,  // output                                       ddr2_cas_n
        output logic [0:0] ddr2_ck_n,  // output [0:0]                        ddr2_ck_n
        output logic [0:0] ddr2_ck_p,  // output [0:0]                        ddr2_ck_p
        output logic [0:0] ddr2_cke,  // output [0:0]                       ddr2_cke
        output logic ddr2_ras_n,  // output                                       ddr2_ras_n
        output logic ddr2_we_n,  // output                                       ddr2_we_n
        inout tri [15:0] ddr2_dq,  // inout [15:0]                         ddr2_dq
        inout tri [1:0] ddr2_dqs_n,  // inout [1:0]                        ddr2_dqs_n
        inout tri [1:0] ddr2_dqs_p,  // inout [1:0]                        ddr2_dqs_p      
        output logic [0:0] ddr2_cs_n,  // output [0:0]           ddr2_cs_n
        output logic [1:0] ddr2_dm,  // output [1:0]                        ddr2_dm
        output logic [0:0] ddr2_odt // output [0:0]                       ddr2_odt
    );
    
    
    /***********************************************************
    * signal declarations
    ************************************************************/
    
    /*--------------------------------------------------------------
    * interface between the lcd and the fifo buffer 
    --------------------------------------------------------------*/
    logic [LCD_DISPLAY_DATA_WIDTH-1:0] lcd_stream_in_pixel_data;
    logic lcd_stream_valid_flag;
    logic lcd_stream_ready_flag;
        
    /* constants */  
    localparam VIDEO_CORE_NUM_TOTAL = `VIDEO_CORE_TOTAL_G; 
    localparam VIDEO_REG_BIT_TOTAL = `VIDEO_REG_ADDR_BIT_SIZE_G;    // 19 bit;
    localparam REG_DATA_WIDTH = `REG_DATA_WIDTH_G;                  // 32 bit;
  
    localparam LCD_WIDTH    = 240;
    localparam LCD_HEIGHT   = 320;
    
    // bits per pixel;
    localparam BPP_16B  = 16;   // 16-bit;   
    localparam BPP_8B   = 8;    // 8-bit;
    
    /*--------------------------------------------------------------
    * signals between the LCD fifo and the core_video_src_mux unit 
    --------------------------------------------------------------*/
    logic pixel_src_valid;              // from the mux to the fifo;
    logic pixel_src_ready;              // from the fifo to the mux;
    logic [BPP_8B-1:0] pixel_src_data;  // actual data;
    
    /*-----------------------------------------------
    * signals for the core_video_test_pattern_gen 
    -----------------------------------------------*/    
    logic pattern_valid;
    logic pattern_ready;
    logic [BPP_8B-1:0] pattern_pixel_data;   // actual data;
    
    /*-------------------------------------------------------------- 
    * signals for core_video_cam_dcmi_interface 
    --------------------------------------------------------------*/
    // for downstream;    
    logic DCMI_sink_ready;     // signal from the sink to this interface;
    logic DCMI_sink_valid;     // signal from this interface to the sink;
    logic [LCD_DISPLAY_DATA_WIDTH-1:0] DCMI_stream_out_data;    // 8-bit data;
    
    /* ----- broadcasting arrays; */
    // individual control signals for each core;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_cs_array; // chip select;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_wr_array; // write enable; 
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_rd_array; // read enable;
    
    // input, output, and register data for each core;
    logic [VIDEO_REG_BIT_TOTAL-1:0] core_addr_reg_array[VIDEO_CORE_NUM_TOTAL-1:0];  // register of each core;
    logic [REG_DATA_WIDTH-1:0]      core_data_rd_array[VIDEO_CORE_NUM_TOTAL-1:0];   // read data from each core;
    logic [REG_DATA_WIDTH-1:0]      core_data_wr_array[VIDEO_CORE_NUM_TOTAL-1:0];   // write data from each core;
    
    /*-------------------------------------------------------------- 
    * signals for core_video_src_mux 
    --------------------------------------------------------------*/
    logic [BPP_8B-1:0] video_src_mux_camera_rgb_data;
    logic video_src_mux_camera_ready;
    logic video_src_mux_camera_valid;
    
    /************************ instantiation *****************************/
    /*------------------------------------------------
    * video controller; 
    ------------------------------------------------*/
    video_ctrl ctrl_unit
    (
        .clk(clk_sys),
        .reset(reset),
        
        // system control sigmals;
        .video_cs(video_cs),  
        .video_rd(video_rd),
        .video_wr(video_wr),
        
        // address to decode;
        .video_addr(video_addr),
        
        // data;
        .video_wr_data(video_wr_data),
        .video_rd_data(video_rd_data),
        
        // broadcaster to all io cores;
        .core_ctrl_cs_array(core_ctrl_cs_array),    // chip select for each core;    
        .core_ctrl_wr_array(core_ctrl_wr_array),    // write enable for each core;
        .core_ctrl_rd_array(core_ctrl_rd_array),    // read enable for each core;
        .core_data_wr_array(core_data_wr_array),    // write data;
        .core_data_rd_array(core_data_rd_array),    // data to multiplex
        .core_addr_reg_array(core_addr_reg_array)    // register address to decode;      
    );
    
     
    /*------------------------------------------------ 
    fifo interfaceing the lcd display
    this fifo is buffering between the pixel source
    and the lcd display;
    
    pixel source is either coming from the camera ov7670
    or from HW pixel generation core;
    
    lcd display is the actual ILI9341;
    this lcd uses MCU 8080-I series;
    
    there is a mismatch in the source 
    rate and the sink rate;
    
    so a buffer is necessary;
    
    ------------------------------------------------*/
    fifo_core_video_lcd_display 
    #(
        .DATA_WIDTH(LCD_DISPLAY_DATA_WIDTH),
        .ADDR_WIDTH(FIFO_LCD_ADDR_WIDTH)  
    )
    fifo_lcd_unit
    (
        .clk(clk_sys),
        .reset(reset),
        
        // from the pixel source end;
        .src_data(pixel_src_data),     
        .src_valid(pixel_src_valid),
        .src_ready(pixel_src_ready),
        
        // for the sink end: LCD display;
        .sink_data(lcd_stream_in_pixel_data),
        .sink_valid(lcd_stream_valid_flag),
        .sink_ready(lcd_stream_ready_flag)
    );
    
    /* ------------------------------------------------
    * lcd display interface (ILI9341); 
    ------------------------------------------------*/
    core_video_lcd_display
    #(
        .PARALLEL_DATA_BITS(LCD_DISPLAY_DATA_WIDTH)
    )
    lcd_display_unit
    (
        // general;
        .clk(clk_sys),
        .reset(reset),
        
        // IO interface
        .cs(core_ctrl_cs_array[`V0_DISP_LCD]),
        .write(core_ctrl_wr_array[`V0_DISP_LCD]),
        .read(core_ctrl_rd_array[`V0_DISP_LCD]),
        .addr(core_addr_reg_array[`V0_DISP_LCD]),
        .wr_data(core_data_wr_array[`V0_DISP_LCD]),
        .rd_data(core_data_rd_array[`V0_DISP_LCD]),
        
        /* hw pin specific to the lcd controller */
        .lcd_drive_wrx(lcd_drive_wrx),     //  to drive the lcd for write op;
        .lcd_drive_rdx(lcd_drive_rdx),     // to drive the lcd for read op;
        .lcd_drive_csx(lcd_drive_csx),     // chip seletc;
        .lcd_drive_dcx(lcd_drive_dcx),     // data or command; LOW for command;          
        .lcd_dinout(lcd_dinout),   // this is shared between the host and the lcd;
        
        /* interface between the fifo */
        .stream_in_pixel_data(lcd_stream_in_pixel_data),
        .stream_valid_flag(lcd_stream_valid_flag),       // a lcd start write request from the fifo;
        .stream_ready_flag(lcd_stream_ready_flag)    // request a read from the fifo for more pixel;
    );
    
    
    /* ------------------------------------------------
    * multiplexer for different HW pixel sources to drive
    * the LCD; (not from the cpu)
    ------------------------------------------------*/
    core_video_src_mux
    #(
        .LCD_WIDTH(LCD_WIDTH),
        .LCD_HEIGHT(LCD_HEIGHT),
            
        // pixel width;
        .SRC_BITS_PER_PIXEL(BPP_16B),    // from the test pattern generator;
        .SINK_BITS_PER_PIXEL(BPP_8B)     // LCD only accepts 8-bit in parallel at a time;
    )
    video_src_mux_unit
    (
        // general;
        .clk(clk_sys),
        .reset(reset),
        
        // IO interface
        .cs(core_ctrl_cs_array[`V2_DISP_SRC_MUX]),
        .write(core_ctrl_wr_array[`V2_DISP_SRC_MUX]),
        .read(core_ctrl_rd_array[`V2_DISP_SRC_MUX]),
        .addr(core_addr_reg_array[`V2_DISP_SRC_MUX]),
        .wr_data(core_data_wr_array[`V2_DISP_SRC_MUX]),
        .rd_data(core_data_rd_array[`V2_DISP_SRC_MUX]),
        
        // specific;
        /* for downstream */
        /* for video downstream */       
        .stream_out_rgb(pixel_src_data), // 8-bit for the LCD;
        .sink_ready(pixel_src_ready), // signal from the lcd fifo;
        .sink_valid(pixel_src_valid), // signal to the lcd fifo
                
        /* from different upstream pixel sources */
        // from the test pattern;
        .pattern_rgb(pattern_pixel_data),  // pixel source;
        .pattern_ready(pattern_ready), // from lcd fifo to the test pattern generator;
        .pattern_valid(pattern_valid),  // from the test pattern gen to the lcd fifo;
        
        // from the upstream (camera) through some intermediate processing element(s);
        .camera_rgb(video_src_mux_camera_rgb_data),   // pixel source;
        .camera_ready(video_src_mux_camera_ready),     // from lcd fifo to the upstream;
        .camera_valid(video_src_mux_camera_valid)      // from the upstream to the fifo;; 
                          
    );
    
    
    /*------------------------------------------------
    * pixel test pattern generator for the LCD display
    ------------------------------------------------*/
    core_video_lcd_test_pattern_gen
    #(
        .LCD_WIDTH(LCD_WIDTH),   
        .LCD_HEIGHT(LCD_HEIGHT), 
            
        // pixel width;
        .SRC_BITS_PER_PIXEL(BPP_16B),    // from the test pattern generator;
        .SINK_BITS_PER_PIXEL(BPP_8B),     // LCD only accepts 8-bit in parallel at a time;
        
        // counter width from the frame counter
        .COUNTER_WIDTH(10)          
    )
    video_test_pattern_gen_unit    
    (
        // general;
        .clk(clk_sys),
        .reset(reset),
        
        // IO interface
        .cs(core_ctrl_cs_array[`V1_DISP_TEST_PATTERN]),
        .write(core_ctrl_wr_array[`V1_DISP_TEST_PATTERN]),
        .read(core_ctrl_rd_array[`V1_DISP_TEST_PATTERN]),
        .addr(core_addr_reg_array[`V1_DISP_TEST_PATTERN]),
        .wr_data(core_data_wr_array[`V1_DISP_TEST_PATTERN]),
        .rd_data(core_data_rd_array[`V1_DISP_TEST_PATTERN]),        
        
        // specific;       
        .stream_out_rgb(pattern_pixel_data), // 8-bit for the LCD;
        .sink_ready(pattern_ready), // signal from the lcd fifo;
        .sink_valid(pattern_valid) // signal to the lcd fifo
    
    );
    
    /*---------------------------------------
    * DCMI interface with camera ov7670;
    ----------------------------------------*/
    core_video_cam_dcmi_interface
    #(
        .DATA_BITS(BPP_8B),
        .HREF_COUNTER_WIDTH(8),      // to count for href assertions (max at 240);
        .HREF_TOTAL(LCD_WIDTH),     // href should correspond to the LCD width;
        .FRAME_COUNTER_WIDTH(32),   // frame counter; ok to overflow;    
        .FIFO_RST_LOW_CYCLES(5),     // for macro fifo reset conditions;
        .FIFO_RST_HIGH_CYCLES(8)     // for macro fifo reset conditions;
    )
    video_cam_dcmi_interface_unit
    (
        // general;
        .clk_sys(clk_sys),
        .reset_sys(reset),
        
        // IO interface
        .cs(core_ctrl_cs_array[`V3_CAM_DCMI_IF]),
        .write(core_ctrl_wr_array[`V3_CAM_DCMI_IF]),
        .read(core_ctrl_rd_array[`V3_CAM_DCMI_IF]),
        .addr(core_addr_reg_array[`V3_CAM_DCMI_IF]),
        .wr_data(core_data_wr_array[`V3_CAM_DCMI_IF]),
        .rd_data(core_data_rd_array[`V3_CAM_DCMI_IF]),
                
        /* specific; */
        // specific external  signals;
        // synchronization signals;
        .DCMI_PCLK(dcmi_pclk),
        .DCMI_HREF(dcmi_href),
        .DCMI_VSYNC(dcmi_vsync),
        .DCMI_DIN(dcmi_pixel),               
        
        // for downstream signals;
        .stream_out_data(DCMI_stream_out_data),
        .sink_ready(DCMI_sink_ready),     // signal from the sink to this interface;
        .sink_valid(DCMI_sink_valid),     // signal from this interface to the sink;
        
        // [not used] for debugging;
        .debug_RST_FIFO(),
        .debug_FIFO_rst_ready(),
        .debug_decoder_complete_tick(),
        .debug_decoder_start_tick(),
        .debug_detect_vsync_edge()
    );
    
    
    core_video_pixel_converter_monoY2RGB565
    #(
        // pixel width;
        .BITS_PER_PIXEL_16B(16),    
        .BITS_PER_PIXEL_8B(8)
    ) 
    video_pixel_converter_monoY2RGB565_unit
    (
       // general;
        .clk(clk_sys),
        .reset(reset),
        
        // IO interface
        .cs(core_ctrl_cs_array[`V4_PIXEL_COLOUR_CONVERTER]),
        .write(core_ctrl_wr_array[`V4_PIXEL_COLOUR_CONVERTER]),
        .read(core_ctrl_rd_array[`V4_PIXEL_COLOUR_CONVERTER]),
        .addr(core_addr_reg_array[`V4_PIXEL_COLOUR_CONVERTER]),
        .wr_data(core_data_wr_array[`V4_PIXEL_COLOUR_CONVERTER]),
        .rd_data(core_data_rd_array[`V4_PIXEL_COLOUR_CONVERTER]),
        
        /* ------------ specific */
        // interface with the upstream;
        .src_valid(DCMI_sink_valid),
        .src_ready(DCMI_sink_ready),
        .src_data(DCMI_stream_out_data),
        
        // interface with the downstream;
        .sink_ready(video_src_mux_camera_ready),
        .sink_valid(video_src_mux_camera_valid),
        .sink_data(video_src_mux_camera_rgb_data)
    );
    
    /*---------------------------------------
    * DISABLED;
    * rep;aced by CAMERA OV7670;
    * HW emulator for DCMI signals
    * this is a temporary replacement
    * for the actual camera OV7670;
    ----------------------------------------*/
    dcmi_emulator
    #(
        .DATA_BITS(8), // camera could only transmit 8-bit in parallel at at time;
    
        // dcmi sync;
        .PCLK_MOD(4),               // 100/4 = 25 MHz;
        .VSYNC_LOW(10),             //vlow;
        .HREF_LOW(5),               // hlow; 
        .BUFFER_START_PERIOD(7),    // between vsync assertion and href assertion;
        .BUFFER_END_PERIOD(5),	    // between the frame end and the frame start;
        .HREF_TOTAL(LCD_WIDTH),           // total href assertion to generate;
        .PIXEL_BYTE_TOTAL(640)      // 320 pixels per href with bp = 16-bit; 
    )
    dcmi_emulator_unit
    (
        .clk_sys(clk_sys),      // 100 MHz;
        .reset_sys(reset),      // async;
        
        // user command;
        .start(0),      
        
        // output; sycnhronization signals + dummy pixel data byte;
        .pclk(),   // fixed at 25 MHz (cannot emulate 24MHz using 100MHz clock);
        .vsync(), 
        .href(),
        .dout(),

        //[not used] status;
        .frame_start_tick(),
        .frame_complete_tick()
    );
    
    
    /*--------------------------------------------
    * MIG interface with the board's DDR2 SDRAM;
    -------------------------------------------*/
     core_video_mig_interface     
     #(
        /*------------------------------------------
        * parameter for the HW testing cicruit;
        ------------------------------------------*/
        // counter/timer;
        // N seconds led pause time; with 100MHz; 200MHz threshold is required;        
        .TIMER_THRESHOLD(50_000_000),  // 0.5 second;
        
        // traffic generator to issue the addr;
        // here we just simply use incremental basis;
        .INDEX_THRESHOLD(32) // wrap around; 2^{5};
    )
    video_core_mig_interface_unit
    (
        // general;        
        .clk_sys(clk_sys),    // 100MHz system;
        .clk_mem(clk_mem),    // 200MHz for MIG;       
        .reset_sys(reset),  // system reset;        
    
        /* --------------------------------------------------------------------------
        BUS INTERFACE
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        ---------------------------------------------------------------------------*/
        .cs(core_ctrl_cs_array[`V5_MIG_INTERFACE]),
        .write(core_ctrl_wr_array[`V5_MIG_INTERFACE]),
        .read(core_ctrl_rd_array[`V5_MIG_INTERFACE]),
        .addr(core_addr_reg_array[`V5_MIG_INTERFACE]),
        .wr_data(core_data_wr_array[`V5_MIG_INTERFACE]),
        .rd_data(core_data_rd_array[`V5_MIG_INTERFACE]),
        
        /* --------------------------------------------------------------------------
        * (Multiplexed) Input Interface with this video core: motion detection 
        ---------------------------------------------------------------------------*/
        // placeholder; not yet constructed;
        .core_motion_wrstrobe(),
        .core_motion_rdstrobe(),
        .core_motion_addr(),
        .core_motion_wrdata(),
        .core_motion_rddata(),
    
        // MIG DDR2 status;        
        .core_MIG_init_complete(),   // MIG DDR2 initialization complete;
        .core_MIG_ready(),           // MIG DDR2 ready to accept any request;
        .core_MIG_transaction_complete(), // a pulse indicating the read/write request has been serviced;
        .core_MIG_ctrl_status_idle(),    // MIG synchronous interface controller idle status;
                
        /*-----------------------------
        * external pin;
        * 1. LED;
        * 2. DDR2 SDRAM
        ------------------------------*/
        // LEDs;
        .LED(LED),
    
        // LED also display the MMCM locked status;
        .MMCM_locked(MMCM_locked),
                
        // ddr2 sdram memory interface (defined by the imported ucf file);
        .ddr2_addr(ddr2_addr),   // address; 
        .ddr2_ba(ddr2_ba),    
        .ddr2_cas_n(ddr2_cas_n),  // output                                       ddr2_cas_n
        .ddr2_ck_n(ddr2_ck_n),  // output [0:0]                        ddr2_ck_n
        .ddr2_ck_p(ddr2_ck_p),  // output [0:0]                        ddr2_ck_p
        .ddr2_cke(ddr2_cke),  // output [0:0]                       ddr2_cke
        .ddr2_ras_n(ddr2_ras_n),  // output                                       ddr2_ras_n
        .ddr2_we_n(ddr2_we_n),  // output                                       ddr2_we_n
        .ddr2_dq(ddr2_dq),  // inout [15:0]                         ddr2_dq
        .ddr2_dqs_n(ddr2_dqs_n),  // inout [1:0]                        ddr2_dqs_n
        .ddr2_dqs_p(ddr2_dqs_p),  // inout [1:0]                        ddr2_dqs_p      
        .ddr2_cs_n(ddr2_cs_n),  // output [0:0]           ddr2_cs_n
        .ddr2_dm(ddr2_dm),  // output [1:0]                        ddr2_dm
        .ddr2_odt(ddr2_odt), // output [0:0]                       ddr2_odt        
    
        /*--------------------------
        * debugging interface
        --------------------------*/            
        .debug_mig_reset_n(),    // reset signal for MIG:
        .debug_MIG_init_complete_status(),
        .debug_MIG_transaction_complete_status(),
        .debug_MIG_ctrl_status_idle(),
        .debug_mux_reg(),
        .debug_MIG_CPU_transaction_complete_status_reg(),
        .debug_MIG_CPU_transaction_complete_status_next()   
    );
    
    
    /* -------------------------------------------------------------------
    * ground the the read data signals from the unconstructed video cores 
    * for vivao synthesis optimization to opt out these unused signals 
     -------------------------------------------------------------------*/
    generate
        genvar i;
            for(i = 6; i < VIDEO_CORE_NUM_TOTAL; i++)
            begin
                // always HIGH ==> idle ==> not signals;
                assign core_data_rd_array[i] = 32'hFFFF_FFFF;
            end
        endgenerate

    
endmodule


`endif //_VIDEO_SYS_SV