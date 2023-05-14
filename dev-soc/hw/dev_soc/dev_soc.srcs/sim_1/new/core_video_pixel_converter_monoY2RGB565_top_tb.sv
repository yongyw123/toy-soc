`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 20:55:05
// Design Name: 
// Module Name: core_video_pixel_converter_monoY2RGB565_top_tb
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
`ifndef CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TOP_TB_SV
`define CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TOP_TB_SV

`include "IO_map.svh"

module core_video_pixel_converter_monoY2RGB565_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    

    // uut bus interface signals;
    logic cs;    
    logic write;              
    logic read;               
    logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr;  //  19-bit;         
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;

    /* uut specific argument */
    // interface with the upstream;
    logic src_valid;
    logic src_ready;
    logic [7:0] src_data;
    
    // interface with the downstream;
    logic sink_ready;
    logic sink_valid;
    logic [7:0] sink_data;
    
    /* upstream fifo argument */    
    logic up_rd;
    logic up_wr;
    logic up_empty;
    logic up_full;
    logic [7:0] up_rd_data;
    logic [7:0] up_wr_data;
    assign src_valid = !up_empty;
    assign up_rd = !up_empty && src_ready;
    assign src_data = up_rd_data;
    
    /* downstream fifo argument */
    logic down_rd;
    logic down_wr;
    logic down_empty;
    logic down_full;
    logic [7:0] down_rd_data;
    logic [7:0] down_wr_data;
    assign down_wr = !down_full && sink_valid;
    assign sink_ready = !down_full;
    assign down_wr_data = sink_data;
    
    /* ---------  instantiation */
    // upstream fifo to simulate upstream;
    FIFO 
    #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(4)
    )
    fifo_upstream
    (
        .clk(clk_sys),
        .reset(reset_sys),
        
        .ctrl_rd(up_rd),
        .ctrl_wr(up_wr),
        .flag_empty(up_empty),
        .flag_full(up_full),
        
        .rd_data(up_rd_data),
        .wr_data(up_wr_data)
    );
    
    // downstream fifo to simulate downstream;
    FIFO 
    #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(2)
    )
    fifo_downstream
    (
        .clk(clk_sys),
        .reset(reset_sys),
        
        .ctrl_rd(down_rd),
        .ctrl_wr(down_wr),
        .flag_empty(down_empty),
        .flag_full(down_full),
        
        .rd_data(down_rd_data),
        .wr_data(down_wr_data)
    );
    
        
    // uut;
    core_video_pixel_converter_monoY2RGB565
    uut
    (
        // general;
        .clk(clk_sys),
        .reset(reset_sys),  // async reset;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        .cs(cs),    
        .write(write),              
        .read(read),               
        .addr(addr),           
        .wr_data(wr_data),    
        .rd_data(rd_data),
        
        // interface with the upstream;
        .src_valid(src_valid),
        .src_ready(src_ready),
        .src_data(src_data),
        
        // interface with the downstream;
        .sink_ready(sink_ready),
        .sink_valid(sink_valid),
        .sink_data(sink_data)
    );
         
    // tb;
    core_video_pixel_converter_monoY2RGB565_tb tb(.*);
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
        
       $monitor("time: %t, uut.converted_rgb565: %16B, up_rd_data: %8B",
       $time,
       uut.converted_rgb565,
       up_rd_data
       );
       
    end    

                 
    
endmodule

`endif //CORE_VIDEO_PIXEL_CONVERTER_MONOY2RGB565_TOP_TB_SV