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
    sink_ready <= 1'b1; // always sinking;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    // do not start the decoder;
    wr_data <= 2'b00;  
    
    // read the system init status;
    @(posedge clk_sys);
    addr <= REG_FIFO_SYS_INIT_STATUS_OFFSET;
    read <= 1'b1;
    // expect the macro fifo eventually resets successfully;
    wait(rd_data[0] == 1'b1);
    
    // read the bram fifo status;
    @(posedge clk_sys);
    addr <= REG_FIFO_STATUS_OFFSET;
    read <= 1'b1;
    
    // start the decoder;
    @(posedge clk_sys);
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b01;   // the msb is for counter-clearing;
    
    // read the decoder status;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_DECODER_STATUS_OFFSET;
    
    // checking for decoder start bit;
    // depending on at which point the decoder is enabled;
    // it may miss the current vsync;
    // if so, it will NOT miss the second one;
    // expect the decoder detects a frame start eventually;
    // disable the decoder once detected; otherwise; it will 
    // keep going foreverl
    wait(rd_data[0] == 1'b1);
    
    @(posedge clk_sys);
    write <= 1'b1;
    read <= 1'b1;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b00;    
    
    
    // expect the decoder to eventually end at the frame end;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_DECODER_STATUS_OFFSET;
    wait(rd_data[1] == 1'b1);
    
    // read the fifo statistics;
    // the write and read counts;
    // expect write == read count;
    // because sink_ready is always enabled;
    // so the write rate == read rate;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FIFO_CNT_OFFSET;
    
    // read the frame counter;
    // expect it to be one only;
    // because we only enable the decoder once previously;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FRAME_OFFSET;
    
    
    // clear the frame counter;
    // and read it thereafter; expect it to reset to zero;
    @(posedge clk_sys);    
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b10;
    
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FRAME_OFFSET;
    
    // allow the decoder  run over more than say 4 frames;
    @(posedge clk_sys);    
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b01;
    
    // check the frame counter;
    // disable the decoder once the target is reached;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FRAME_OFFSET;
    
    wait(rd_data == 3);
    // target has been reached; disable the decoder;
    @(posedge clk_sys);    
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b00;
    
    // read the fifo stats;
    // expect it to be four times more in terms of the read and write counts;
    // and read == write count;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FIFO_CNT_OFFSET;
    
    // disable sink ready; so fifo will not be read;
    // start the decoder;
    // once the decoder is finished;
    // then only enable the fifo read;
    // see if it matches the expectation;
    // expectation;
    // expect the fifo stats read count != write count;
    // expect that the stream out data will be on hold;
    // until the sink is ready;
    @(posedge clk_sys);    
    sink_ready <= 1'b0;
    
    // start the decoder;
    @(posedge clk_sys);    
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b01;
    
    // disable the decoder after it has started;
    // otherwise it will keep going;
    // wait for the decoder to finish;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_DECODER_STATUS_OFFSET;
    wait(rd_data[0] == 1'b1);

    // start the decoder;
    @(posedge clk_sys);    
    write <= 1'b1;
    read <= 1'b0;
    addr <= REG_CTRL_OFFSET;
    wr_data <= 2'b00;   
        
    // wait for the decoder to finish;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_DECODER_STATUS_OFFSET;
    wait(rd_data[1] == 1'b1);
    
    // check for fifo stats;
    // expect write count != read count;
    @(posedge clk_sys);    
    write <= 1'b0;
    read <= 1'b1;
    addr <= REG_FIFO_CNT_OFFSET;
    
    
    
    
    
    
    #(100);
    $display("test ends");
    $stop;
    
    end
endprogram

`endif //CORE_VIDEO_CAM_DCMI_INTERFACE_TB_SV

/* ----------------------------    
??????
TO DO
1. allow the decoder and emulator run over more than say 4 frames;
2. toggle sink ready to test the fifo sinking;
???
*---------------------------------------*/    

