`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 15:34:08
// Design Name: 
// Module Name: mcs_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: main system (SoC) to be driven by the SW;
//      1. contain the mircoblaze cpu ip-generated;
//      2. bridge between ublaze mcs io bus and the user-space bus;
//      3. mmio controller; interface between ublaze processor and io cores;
//      4. already-constructed io cores;
//      5. video controller; interface between the ublaze processor and the video cores;
//      6. already-constructed video cores;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef _MCS_TOP_SV
`define _MCS_TOP_SV

`include "IO_map.svh"

module mcs_top
    // this is given the datasheet of the microblaze;
    //#(parameter MCS_BRIDGE_BASE_ADDR = `BUS_MICROBLAZE_IO_BASE_ADDR_G)    
    (
         // 100 MHz;
        input logic clk_in1,       
        
        // async cpu (soft core) reset button; 
        // **important; it is active low; need to invert;
        input logic CPU_RESETN,     
        
        /*-------------------------------------------- 
        * GPO and GPI;
        --------------------------------------------*/
        input logic [15:0] SW,      // use all switches available on the board;
        output logic [15:0] LED,    // use all leds available on the board;
        
        /*--------------------------------------------
        * uart;
        * beware of the mix of tx and rx;
        * note: uart flow ctrl is not implemented; so no cts/rts pins;
        --------------------------------------------*/
        input logic UART_TXD_IN,  // this connects to the system uart rx;
        output logic UART_RXD_OUT, // this connects to the system uart tx;
        
        /* --------------------------------------------
        * SPI; not used;
        * uses PMOD jumper @ JC;
        -------------------------------------------*/
        /*
        output logic SPI_SCLK_JC1,
        output logic SPI_MOSI_JC2,
        input logic SPI_MISO_JC3,
        output logic SPI_SS_JC4, // slave select; asset active low;
        output logic SPI_DC_JC7,  // is the current MOSI a data or command for the slave?
        */
                
        /*--------------------------------------------
        * LCD ili9341
        * uses PMOD jumpers @ JC and JD
        --------------------------------------------*/   
        // control pins;
        output logic LCD_CSX_JD01,     // chip select;
        output logic LCD_DCX_JD02,     // data or command; LOW for command;          
        output logic LCD_WRX_JD03,     //  to drive the lcd for write op;
        output logic LCD_RDX_JD04,     // to drive the lcd for read op;
        
        // data bus; shared between the host and the lcd;
        inout tri[7:0] LCD_DATA_JC,
        
        /*-------------------------------------------- 
        * hw reset pins
        * software controlled;
        * configure a pmod jumper as gpio;
        --------------------------------------------*/
        inout tri GPIO_CAM_OV7670_RESETN_JB09,  // for camera ov7670;      
        inout tri GPIO_LCD_ILI9341_RSTN_JD07,   // for lcd ili9341;        
        
        /*-------------------------------------------- 
        * CAMERA OV7670 Control 
        * 1. use i2c protocol;
        * 2. require a clock driver of 24 MHz (to drive the camera itself);
        * 3. use a HW reset;
        --------------------------------------------*/
        // i2c;
        // uses PMOD jumper @ JB;
        output tri I2C_SCL_JB07,    // spi clock; tri because we have a pull up resistor;
        inout tri I2C_SDA_JB08,      // spi data; inout becos shared between master and slaves;
        
        // output clocks @ JB jumpers;
        output CLKOUT_24M_JB02, // the camera requires an input clock to operate;
        
        /* ------------------------------------------
        * CAMERA OV7670 Synchronization Signals
        * and Data;        
        --------------------------------------------*/             
        input logic CAM_OV7670_PCLK_JB10,       // driven by the camera at 24 MHz;
        input logic CAM_OV7670_VSYNC_JB03,      // vertical synchronization;
        input logic CAM_OV7670_HREF_JB04,       // horizontal synchronization;
        input logic [7:0] CAM_OV7670_DATA_JA,    // 8-bit pixel data;
        
        /* ------------------------------------------
        * DDR2 SDRAM;        
        --------------------------------------------*/
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
    
    /*-------------------------------------------------------------
    * signal declarations;
    -------------------------------------------------------------*/
    // MMCM clock;
    logic clkout_100M;  // 100MHz generated from the MMCM;
    logic clkout_200M;  // 200MHz generated from the MMCM;    
    logic sys_clk;      // sys_clk = clkout_100M;
    
    // for ip-generated mmcm clock;
    // note that this lock signal from MMCM is asynchronous;
    logic mmcm_clk_locked;   // whether the clock has stabilized or not?
    
    // mcs io bus signals; these are fixed;
    logic io_addr_strobe;   // output wire IO_addr_strobe
    logic [31:0] io_address;       // output wire [31 : 0] IO_address
    logic [3:0] io_byte_enable;   // output wire [3 : 0] IO_byte_enable
    logic [31:0] io_read_data;     // input wire [31 : 0] IO_read_data
    logic io_read_strobe;   // output wire IO_read_strobe
    logic io_ready;         // input wire IO_ready
    logic [31:0] io_write_data;    // output wire [31 : 0] IO_write_data
    logic io_write_strobe;  // output wire IO_write_strobe
    
    // user-bus signals after bridging;
    logic user_mmio_cs;
    logic user_video_cs;
    logic user_wr;
    logic user_rd;
    logic [31:0] user_wr_data;
    logic [31:0] user_rd_data;
    logic [`BUS_USER_SIZE_G-1:0] user_addr;
    
    // for multiplexing the read data from mmio or video system;
    logic [31:0] user_rd_data_mmio;
    logic [31:0] user_rd_data_video;
    
    /*-------------------------------------------
    * System Reset Signals
    -------------------------------------------*/
    /*
    NOTE on ASYNC_REG;
    1. This is reported in the route design;
    2. Encountered Error: "TIMING-10#1 Warning
        Missing property on synchronizer  
        One or more logic synchronizer has been detected between 2 clock domains 
        but the synchronizer does not have the property ASYNC_REG defined on one 
        or both registers.
        It is recommended to run report_cdc for a complete and detailed CDC coverage
    "
    3. See Xilinx UG901 (https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/ASYNC_REG)
    The ASYNC_REG is an attribute that affects many processes in the Vivado tools flow. 
    The purpose of this attribute is to inform the tool that a register is capable of receiving 
    asynchronous data in the D input pin relative to the source clock, 
    or that the register is a synchronizing register within a synchronization chain.
    */    
  
    // registers for asynchronous reset signals;
    logic reset_sys_raw;    // to invert the input reset;
    (* ASYNC_REG = "TRUE" *) logic reset_sys_reg;       // ff synchronizer;
    (* ASYNC_REG = "TRUE" *) logic reset_sys_sync;      // ff synchronizer;
   
    // to stretch the synchronized signal over some N system clock cycles;
    localparam RST_SYS_CYCLE_NUM = 1024;
    logic [11:0] cnt_rst_sys_reg, cnt_rst_sys_next; // width should at least hold the parameter above;
    logic reset_sys_stretch;
    logic reset_sys_stretch_reg; // to filter for glitch;
    
    // conform the signals;
    /* ?? to do ??, need to debounce this reset button; */
    // inverted since cpu reset button is "active LOW";
    // locked=HIGH means clock has stabilized;
    // need to hold reset asserted until both CPU and locked signals are OK;
    assign reset_sys_raw = ~CPU_RESETN || ~mmcm_clk_locked;      
    
        
    // use better name for the system clock;
    assign sys_clk = clkout_100M;
    
    /* -------------------------------------------------------------------
    * Synchronize the reset signals via double FF;
    * currently; it is asynchronous
    * implementation error encountered: LUT drives async reset alert
    -------------------------------------------------------------------*/

    // use the input clock, rather than from the MMCM?    
    always_ff @(posedge sys_clk) begin
        // system reset;
        reset_sys_reg   <= reset_sys_raw;
        reset_sys_sync  <= reset_sys_reg;
    end
    
    /*--------------------------------------------------
    * To stretch the synchronized reset_sys_sync over N system clock periods;
    * where the system clock is the 100MHz clock generated from MMCM;
    --------------------------------------------------*/
    always_ff @(posedge sys_clk) begin
        // note that this reset signal has been synchronized;
        if(reset_sys_sync) begin
            cnt_rst_sys_reg <= 0;
        end 
        else begin
            cnt_rst_sys_reg <= cnt_rst_sys_next;
        end    
    end
    
    // next state logic;
    // stop the count if the threshold has been met;
    assign cnt_rst_sys_next = (cnt_rst_sys_reg == RST_SYS_CYCLE_NUM) ? cnt_rst_sys_reg : cnt_rst_sys_reg + 1;    
    assign reset_sys_stretch = (cnt_rst_sys_reg != RST_SYS_CYCLE_NUM);
    
    // filter the rst_sys_stretch to avoid glitch since it comes from a combinational block;
    always_ff @(posedge sys_clk) begin
        // note that this reset signal has been synchronized;
        if(reset_sys_sync) begin
            reset_sys_stretch_reg <= 0;
        end 
        else begin
            reset_sys_stretch_reg <= reset_sys_stretch;
        end    
    end
    
    /* -------------------------------------------------------------------
    * instantiation;
    * 0. clock unit   : ip-generated MMCM (mixed mode clock manager);
    * 1. cpu_unit     : ip-generated microblaze mcs
    * 2. bridge unit  : bridge between microblaze io bus and user bus;
    * 3. mmio_unit    : mmio system (where all the io cores reside);
    * 4. video_unit   : video system; 
    -------------------------------------------------------------------*/
    
    // ip-generated clock management circuit;
    clk_wiz_0 clock_unit
   (
    // Clock out ports
    .clkout_24M(CLKOUT_24M_JB02),     // output clkout_24M
    .clkout_100M(clkout_100M),     // output clkout_100M
    .clkout_200M(clkout_200M),     // output clkout_200M
    .clkout_250M(),     // output clkout_250M
   
    // Status and control signals
    .locked(mmcm_clk_locked),   // output locked; locked (HIGH) means the clock has stablized; 
   
   // Clock in ports
    .clk_in1(clk_in1) // input clk_in1: 100MHz;
   );      
  
    // cpu
    microblaze_mcs_cpu cpu_unit(
      .Clk(sys_clk),                          // input wire Clk
      .Reset(reset_sys_stretch_reg),                      // input wire Reset
      .IO_addr_strobe(io_addr_strobe),    // output wire IO_addr_strobe
      .IO_address(io_address),            // output wire [31 : 0] IO_address
      .IO_byte_enable(io_byte_enable),    // output wire [3 : 0] IO_byte_enable
      .IO_read_data(io_read_data),        // input wire [31 : 0] IO_read_data
      .IO_read_strobe(io_read_strobe),    // output wire IO_read_strobe
      .IO_ready(io_ready),                // input wire IO_ready
      .IO_write_data(io_write_data),      // output wire [31 : 0] IO_write_data
      .IO_write_strobe(io_write_strobe)  // output wire IO_write_strobe
    );

    // bridge;
    mcs_bus_bridge bridge_unit
    (
        .mcs_bridge_base_addr(`BUS_MICROBLAZE_IO_BASE_ADDR_G),
        // microblaze address space;
        .io_addr_strobe(io_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_byte_enable(io_byte_enable),
        .io_address(io_address),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data),
        .io_ready(io_ready),
        
        // on the other sie of the bridge: user-own address space
        .user_mmio_cs(user_mmio_cs),
        .user_video_cs(user_video_cs),
        .user_wr(user_wr),
        .user_rd(user_rd),
        .user_addr(user_addr),
        .user_wr_data(user_wr_data),
        .user_rd_data(user_rd_data)
    );
    
    
    // multiplexing read data between mmio and video system;
    // user_mmio_cs and user_video_cs should be mutually exclusive;
    assign user_rd_data = (user_mmio_cs) ? user_rd_data_mmio : user_rd_data_video;
    
    // mmio system;
    mmio_sys 
    #(.SW_NUM(16), 
        .LED_NUM(16),
        
        /* uart for serial console debugging */
        .UART_DATA_BIT(8),      
        .UART_STOP_BIT_SAMPLING_NUM(16),
        
        /* for lcd sanity control */
        .SPI_DATA_BIT(8),
        .SPI_SLAVE_NUM(1),
        
        /* for camera ov7670 */
        .I2C_DATA_BIT(8),   // for camera control;
        .GPIO_PORT_NUM(2)   // for camera, LCD hw resets;
    )
    
    mmio_unit
    (
        .clk(sys_clk),
        .reset(reset_sys_stretch_reg),
        .mmio_addr(user_addr),
        .mmio_cs(user_mmio_cs),
        .mmio_wr(user_wr),
        .mmio_rd(user_rd),
        .mmio_wr_data(user_wr_data),
        //.mmio_rd_data(user_rd_data),
        .mmio_rd_data(user_rd_data_mmio),
        .sw(SW),
        
        // not used; 
        .led(),
        
        // uart signals; 
        .uart_tx(UART_RXD_OUT), 
        .uart_rx(UART_TXD_IN),
        
        // spi; not used;
        .spi_sclk(),
        .spi_mosi(),
        .spi_miso(),
        .spi_ss_n(),
        .spi_data_or_command(),
        /*
        .spi_sclk(SPI_SCLK_JC1),
        .spi_mosi(SPI_MOSI_JC2),
        .spi_miso(SPI_MISO_JC3),
        .spi_ss_n(SPI_SS_JC4),
        .spi_data_or_command(SPI_DC_JC7),
        */
        
        /* 
        i2c; 
        camera ov7670; 
        */        
        .i2c_scl(I2C_SCL_JB07),
        .i2c_sda(I2C_SDA_JB08),
        
        /* hw reset pins;
        * 1. camera : OV7670;
        * 2. LCD    : ILI9341;
        */
        .gpio({GPIO_LCD_ILI9341_RSTN_JD07 ,GPIO_CAM_OV7670_RESETN_JB09})
        
    );
    
    // video system;
    video_sys 
    #(
        .BITS_PER_PIXEL(16),
        .LCD_DISPLAY_DATA_WIDTH(8),
        .FIFO_LCD_ADDR_WIDTH(8)
    )
    video_unit
    (
        // general;
        .clk_sys(sys_clk),      // 100 MHz;
        .reset(reset_sys_stretch_reg),  // async;
        
        .video_cs(user_video_cs),        // chip select for mmio system;
        .video_wr(user_wr),             // write enable;
        .video_rd(user_rd),             // read enable;
        .video_addr(user_addr),       // addr to decode for video core address and its register address;
        .video_wr_data(user_wr_data),   // 32-bit;
        //.video_rd_data(user_rd_data??)  // 32-bit;
        .video_rd_data(user_rd_data_video),
        
        /* --------- HW pin mapping (by the constraint file) ------------*/
        /* LCD display (ILI9341); */
        .lcd_drive_csx(LCD_CSX_JD01),     // chip select;
        .lcd_drive_dcx(LCD_DCX_JD02),     // data or command; LOW for command;          
        .lcd_drive_wrx(LCD_WRX_JD03),     //  to drive the lcd for write op;
        .lcd_drive_rdx(LCD_RDX_JD04),     // to drive the lcd for read op;
        
        // this is shared between the host and the lcd;
        .lcd_dinout(LCD_DATA_JC),
        
        /* camera ov7670 sync signals and data */
        .dcmi_pclk(CAM_OV7670_PCLK_JB10),    // driven by the camera at 24 MHz;
        .dcmi_vsync(CAM_OV7670_VSYNC_JB03),  // vertical synchronization;
        .dcmi_href(CAM_OV7670_HREF_JB04),    // horizontal synchronization;
        .dcmi_pixel(CAM_OV7670_DATA_JA),         // 8-bit pixel data;
        
        /* MIG interface core; */
        .LED(LED),
        .MMCM_locked(mmcm_clk_locked),    // MMCM locked status;
        .clk_mem(clkout_200M),        // 200MHz to drive the MIG;
        
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
        .ddr2_odt(ddr2_odt) // output [0:0]                       ddr2_odt
    );
        
    
endmodule

`endif // _MCS_TOP_SV;
