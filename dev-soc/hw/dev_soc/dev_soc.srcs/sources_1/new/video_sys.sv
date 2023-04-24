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
        
        /*
        // buffer between the src and the lcd display;
        // it could hold up to 2^6 =64 data of size of 32-bit;
        // this is equivalent to 16 pixels 
        */
        // since the lcd display could only be driven by 8-bit parallel max;
        LCD_DISPLAY_DATA_WIDTH = 8,
        FIFO_LCD_ADDR_WITH = 6      // 2^6;
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
        inout tri[LCD_DISPLAY_DATA_WIDTH-1:0] lcd_dinout 
    );
    
    
    /* ----- signal declarations ------*/
    
    /* interface between the lcd and the fifo buffer */
    logic [LCD_DISPLAY_DATA_WIDTH-1:0] lcd_stream_in_pixel_data;
    logic lcd_stream_valid_flag;
    logic lcd_stream_ready_flag;
        
    /* constants */  
    localparam VIDEO_CORE_NUM_TOTAL = `VIDEO_CORE_TOTAL_G; 
    localparam VIDEO_CORE_BIT_SIZE = $clog2(VIDEO_CORE_NUM_TOTAL);
    localparam VIDEO_REG_BIT_TOTAL = `VIDEO_REG_ADDR_BIT_SIZE_G;    // 19 bit;
    localparam REG_DATA_WIDTH = `REG_DATA_WIDTH_G;  // 32 bit;
  
    /* ----- broadcasting arrays; */
    // individual control signals for each core;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_cs_array; // chip select;
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_wr_array; // write enable; 
    logic [VIDEO_CORE_NUM_TOTAL-1:0] core_ctrl_rd_array; // read enable;
    
    // input, output, and register data for each core;
    logic [VIDEO_REG_BIT_TOTAL-1:0] core_addr_reg_array[VIDEO_CORE_NUM_TOTAL-1:0]; // register of each core;
    logic [REG_DATA_WIDTH-1:0] core_data_rd_array[VIDEO_CORE_NUM_TOTAL-1:0]; // read data from each core;
    logic [REG_DATA_WIDTH-1:0] core_data_wr_array[VIDEO_CORE_NUM_TOTAL-1:0]; // write data from each core;
    
    /* -------------------- instantiation ------------------------*/
    /* video controller; */
    video_ctrl ctrl_unit
    (
        .clk(clk),
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
    
     
    /* fifo interfaceing the lcd display
    this fifo is buffering between the pixel source
    and the lcd display;
    
    pixel source is either coming from the camera ov7670
    or from HW pixel generation core;
    
    lcd display is the actual ILI9341;
    this lcd uses MCU 8080-I series;
    
    there is a mismatch in the source 
    rate and the sink rate;
    
    so a buffer is necessary;
    
    */
    fifo_core_video_lcd_display 
    #(
    .DATA_WIDTH(LCD_DISPLAY_DATA_WIDTH),
    .ADDR_WIDTH(FIFO_LCD_ADDR_WITH)  
    )
    fifo_lcd_unit
    (
    .clk(clk_sys),
    .reset(reset),
    .src_data(),    // empty for now;
    .src_valid(),
    .src_ready(),
    .sink_data(lcd_stream_in_pixel_data),
    .sink_valid(lcd_stream_valid_flag),
    .sink_ready(lcd_stream_ready_flag)
    );
    
    /* lcd display interface (ILI9341); */
    core_video_lcd_display
    #(.PARALLEL_DATA_BITS(LCD_DISPLAY_DATA_WIDTH))
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
    
    
    
    
    /* ground the the read data signals from the unconstructed video cores 
    for vivao synthesis optimization to opt out these unused signals */
    generate
        genvar i;
            for(i = 1; i < VIDEO_CORE_NUM_TOTAL; i++)
            begin
                // always HIGH ==> idle ==> not signals;
                assign core_data_rd_array[i] = 32'hFFFF_FFFF;
            end
        endgenerate

    
endmodule


`endif //_VIDEO_SYS_SV