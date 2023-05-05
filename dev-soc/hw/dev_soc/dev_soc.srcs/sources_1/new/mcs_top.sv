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
        input logic clk,       
        
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
        inout tri GPIO_CAM_OV7670_RESETN_JA04,  // for camera ov7670;      
        inout tri GPIO_LCD_ILI9341_RSTN_JD07,   // for lcd ili9341;        
        
        /*-------------------------------------------- 
        * CAMERA OV7670 Control 
        * 1. use i2c protocol;
        * 2. require a clock driver of 24 MHz (to drive the camera itself);
        * 3. use a HW reset;
        --------------------------------------------*/
        // i2c;
        // uses PMOD jumper @ JA;
        output tri I2C_SCL_JA01,    // spi clock; tri because we have a pull up resistor;
        inout tri I2C_SDA_JA02,      // spi data; inout becos shared between master and slaves;
        
        // output clocks @ JA jumpers;
        output CLKOUT_24M_JA03, // the camera requires an input clock to operate;
        
        /* ------------------------------------------
        * CAMERA OV7670 Synchronization Signals
        * and Data;
        --------------------------------------------*/             
        input logic CAM_OV7670_PCLK_JA07,       // driven by the camera at 24 MHz;
        input logic CAM_OV7670_VSYNC_JA08,      // vertical synchronization;
        input logic CAM_OV7670_HREF_JA09,       // horizontal synchronization;
        input logic [7:0] CAM_OV7670_DATA_JB    // 8-bit pixel data;
    );    
    
    // general;
    logic reset_sys;    // to invert the input reset;
    logic reset_clk;    // reset mmcm clock;
    
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
    
    // for ip-generated mmcm clock;
    logic mmcm_clk_locked;   // whether the clock has stabilized or not?
    
    // conform the signals;
    /* ?? to do ??, need to debounce this reset button; */
    // inverted since cpu reset button is "active LOW";
    // locked=HIGH means clock has stabilized;
    assign reset_sys = ~CPU_RESETN || ~mmcm_clk_locked;    
    assign reset_clk = ~CPU_RESETN;
    /* -------------------
    instantiation;
    0. clock unit   : ip-generated MMCM (mixed mode clock manager);
    1. cpu_unit     : ip-generated microblaze mcs
    2. bridge unit  : bridge between microblaze io bus and user bus;
    3. mmio_unit    : mmio system (where all the io cores reside);
    4. video_unit   : video system; 
    -----------------*/
    
    // ip-generated clock management circuit;
    clk_wiz_0 clock_unit
   (
    // Clock out ports
    .clkout_24M(CLKOUT_24M_JA03),     // output clkout_24M: for camera ov7670
    
    // Status and control signals
    .reset(reset_clk),          // input reset
    //.reset(0),      // allow free running? bad idea?
    .locked(mmcm_clk_locked),   // output locked; locked (HIGH) means the clock has stablized; 
   
   // Clock in ports
    .clk_in1(clk) // input clk_in1: 100MHz;
   );      

    // cpu
    microblaze_mcs_cpu cpu_unit(
      //.Clk(clkout_100M),                          // input wire Clk
      .Clk(clk),                          // input wire Clk
      .Reset(reset_sys),                      // input wire Reset
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
        //.clk(clkout_100M),
        .clk(clk),
        .reset(reset_sys),
        .mmio_addr(user_addr),
        .mmio_cs(user_mmio_cs),
        .mmio_wr(user_wr),
        .mmio_rd(user_rd),
        .mmio_wr_data(user_wr_data),
        //.mmio_rd_data(user_rd_data),
        .mmio_rd_data(user_rd_data_mmio),
        .sw(SW),
        .led(LED),
        
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
        .i2c_scl(I2C_SCL_JA01),
        .i2c_sda(I2C_SDA_JA02),
        
        /* hw reset pins;
        * 1. camera : OV7670;
        * 2. LCD    : ILI9341;
        */
        .gpio({GPIO_LCD_ILI9341_RSTN_JD07 ,GPIO_CAM_OV7670_RESETN_JA04})
        
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
        .clk_sys(clk),      // 100 MHz;
        .reset(reset_sys),  // async;
        
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
        .lcd_dinout(LCD_DATA_JC)
    );
    
    
endmodule

`endif // _MCS_TOP_SV;
