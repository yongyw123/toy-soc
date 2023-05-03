`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 17:45:28
// Design Name: 
// Module Name: core_video_cam_dcmi_interface_tb
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

`ifndef CORE_VIDEO_CAM_DCMI_INTERFACE_TB_SV
`define CORE_VIDEO_CAM_DCMI_INTERFACE_TB_SV

`include "IO_map.svh"


program core_video_cam_dcmi_interface_tb
    (
        input logic clk_sys,
        
        output logic cs,
        output logic write,
        output logic read,
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,        
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        input logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        output logic sink_ready
            
    );
    // constanst
    localparam REG_CTRL_OFFSET                  = 3'b000;
    localparam REG_DECODER_STATUS_OFFSET        = 3'b001;
    localparam REG_FRAME_OFFSET                 = 3'b010;
    localparam REG_FIFO_STATUS_OFFSET           = 3'b011;
    localparam REG_FIFO_CNT_OFFSET              = 3'b100;    
    localparam REG_FIFO_SYS_INIT_STATUS_OFFSET  = 3'b101;
    
    initial begin
    @(posedge clk_sys);
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 3'b110;
    
    
    
    
    #(1000);
    $display("test ends");
    $stop;
    
    end
endprogram

`endif //CORE_VIDEO_CAM_DCMI_INTERFACE_TB_SV