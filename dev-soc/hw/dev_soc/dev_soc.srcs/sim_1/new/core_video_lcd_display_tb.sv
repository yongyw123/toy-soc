`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 01:22:21
// Design Name: 
// Module Name: core_video_lcd_display_tb
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

`ifndef CORE_VIDEO_LCD_DISPLAY_TB_SV
`define CORE_VIDEO_LCD_DISPLAY_TB_SV


program core_video_lcd_display_tb
    #(parameter PARALLEL_DATA_BITS = 8)
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        // test stimulus;
        output logic cs,    
        output logic write,              
        output logic read,               
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,
      
        // output from the uut;
        input logic [31:0] rd_data,
        
        // inout;
        inout tri [PARALLEL_DATA_BITS-1:0] lcd_dinout,
        
        // from other sources besides the cpu;
        output logic [PARALLEL_DATA_BITS-1:0] fifo_src_data,
        output logic fifo_src_valid,
        input logic fifo_src_ready,
        input logic stream_valid_flag,
        input logic stream_ready_flag,
        
       // debugging;
        output logic [31:0] test_index 
    );
    
    // register offset constanst;
    localparam REG_WR_CLOCKMOD_OFFSET = 3'b001;
    localparam REG_RD_CLOCKMOD_OFFSET = 3'b010;
    localparam REG_WR_DATA_OFFSET = 3'b011; 
    localparam REG_STREAM_CTRL_OFFSET = 3'b100;
    localparam REG_CSX_OFFSET = 3'b101;
    
    // bit pos;
    localparam REG_RD_DATA_BIT_POS_READY = 8;
    localparam REG_RD_DATA_BIT_POS_DONE = 9;
    
    // available commands;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
    
    // sim var;
    logic [15:0] wrx_fhalf_mod = 2;
    logic [15:0] wrx_shalf_mod = 3;
    logic [15:0] rdx_fhalf_mod = 4;
    logic [15:0] rdx_shalf_mod = 5;
    
    logic csx_select = 1'b1;
    logic dcx_command = 1'b1;
    
    initial begin
    $display("test starts");
    /* --------------- setting the clock mod ---------------------*/
    // set for wrx;
    @(posedge clk);
    test_index <= 0;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_WR_CLOCKMOD_OFFSET;
    wr_data <= {2'b0, wrx_shalf_mod, wrx_fhalf_mod};
    
    // set for rdx;
    @(posedge clk);
    test_index <= 1;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_RD_CLOCKMOD_OFFSET;
    wr_data <= {2'b0, rdx_shalf_mod, rdx_fhalf_mod};
    
    /*---------------- write -------------------- */
    // start a write that is a data;
    // enable chip select;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 1;
        
    @(posedge clk);
    test_index <= 2;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {21'b0, CMD_WR, dcx_command, 8'($random)};
    
    // issue a CMD_NOP immediately after one write;
    // otherwise, it will keep on writing on the next ready;
    @(posedge clk);
    wr_data <= {21'b0, CMD_NOP, dcx_command, 8'($random)};
    
    // expect the ready flag to change to busy then back to ready;
    //@(posedge clk); // it takes one clock cycle to update the flag;
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b0);
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b1);

    // terminate immediately after one write;
    // otherwise, it will keep on writing;
    @(posedge clk);
    cs <= 1'b1;
    write <= 1'b1;
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {21'b0, CMD_NOP, !dcx_command, 8'($random)};

    // deselect the chip;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 0;
        
   
    /*---------------- read -------------------- */
    // start a read command;
    // enable chip select;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 1;
    
    // by specs; data-or-command must be DATA;
    @(posedge clk);
    test_index <= 3;
    cs <= 1'b1;
    write <= 1'b1;
    read <= 1'b1;   // dont care since there is no read multiplexing in place;
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {21'b0, CMD_RD, !dcx_command, 8'($random)};

    // issue a NOP; 
    // same reason as above;
    // otherwise, it will keep reading from the lcd;
    @(posedge clk);
    wr_data <= {21'b0, CMD_NOP, !dcx_command, 8'($random)};
    
    // as above; there should be change in the ready status flag;
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b0);
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b1);
    
    // clean up by deselecting;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 0;
    
    //@(posedge clk);
    //wr_data <= {21'b0, CMD_NOP, !dcx_command, 8'($random)};

    
    /* ------------------- test stream control ------------------------*/
    // setup;
    // change the clock mod to shorter period;
    @(posedge clk);
    // this corresponds to 20ns;
    wrx_fhalf_mod <= 1; 
    // this corresponds to one 10ns; but with ready flag adding up;
    // it will be equivalent to 20ns;
    wrx_shalf_mod <= 0; 
    
    @(posedge clk);
    cs <= 1'b1;
    write <= 1'b1;
    addr <= REG_WR_CLOCKMOD_OFFSET;
    wr_data <= {2'b0, wrx_shalf_mod, wrx_fhalf_mod};
    
    // test 01;
    // fill up the fifo src;
    // but cpu is the stream;
    // expect that the fifo stimulus to be ignored for the lcd display;
    
    for(int i = 0; i < 10; i++) begin
        @(posedge clk);
        fifo_src_data <= 8'($random);
        fifo_src_valid <= 1'b1;    
    end
    
    // stop adding more fifo source;
    @(posedge clk);
    fifo_src_valid <= 1'b0;
    
    // test 02;
    // disable the cpu stream;
    // expect that lcd will be driven by the fifo until all data is drawn out;
    @(posedge clk);
    addr  <= REG_STREAM_CTRL_OFFSET;
    wr_data <= {31'b0, 1'b1};   // hand the control to the video streams;
    
    // try deselect the chip;
    // expect that it has no effect;
    // since the control is not with the cpi;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 0;
    
    // expect that fifo will be drawn out; hence the src stream will be invalid;
    @(posedge clk);
    wait(stream_valid_flag == 1'b0);
    
    // expect that the lcd controller will be ready;
    wait(stream_ready_flag == 1'b1);
    
    // test 03;
    // disable the cpu stream;
    // burst (transfer) create fifo source;
    // check if the each source
    // is triggered everytime;
    for(int i = 0; i < 10; i++) begin
        @(posedge clk);
        fifo_src_data <= 8'($random);
        fifo_src_valid <= 1'b1;    
    end
    
    // stop adding more fifo source;
    @(posedge clk);
    fifo_src_valid <= 1'b0;
    
    // we know the transfer end to end is done;
    // when the two following conditions are true;
    wait((stream_ready_flag == 1'b1) && (stream_valid_flag == 1'b0));
    #(50);
    
    // test 04;
    // re-enable the cpu stream;
    // to test interchangeability between two streams;
    // try both writing and reading;
    
    // handling the control over to the cpu;
    @(posedge clk);
    addr  <= REG_STREAM_CTRL_OFFSET;
    wr_data <= {31'b0, 1'b0};   
     
    // pause;
    // expect nothing happens?
    // this depends on the existing write register;
    #(50);
    
    
    // start writing;
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 1;   // enable chip;

    @(posedge clk);
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {21'b0, CMD_WR, dcx_command, 8'($random)};
    
    // issue a CMD_NOP immediately after one write;
    // otherwise, it will keep on writing on the next ready;
    @(posedge clk);
    wr_data <= {21'b0, CMD_NOP, dcx_command, 8'($random)};
    
    // expect the ready flag to change to busy then back to ready;
    //@(posedge clk); // it takes one clock cycle to update the flag;
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b0);
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b1);
    
    // start reading;
    @(posedge clk);
    addr <= REG_WR_DATA_OFFSET;
    wr_data <= {21'b0, CMD_RD, dcx_command, 8'($random)};
    
    // issue a CMD_NOP immediately;
    // otherwise, it will keep on reading on the next ready;
    @(posedge clk);
    wr_data <= {21'b0, CMD_NOP, dcx_command, 8'($random)};
    
    // expect the ready flag to change to busy then back to ready;
    //@(posedge clk); // it takes one clock cycle to update the flag;
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b0);
    wait(rd_data[REG_RD_DATA_BIT_POS_READY] == 1'b1);
    
    // deselect the chip
    @(posedge clk);
    addr <= REG_CSX_OFFSET;
    wr_data <= 0;   

    #(20);
    
    // change back to disabling cpu control;
    @(posedge clk);
    addr  <= REG_STREAM_CTRL_OFFSET;
    wr_data <= {31'b0, 1'b1};   // hand the control to the video streams;
    
    // again start the last burst fifo source;
    for(int i = 0; i < 10; i++) begin
        @(posedge clk);
        fifo_src_data <= 8'($random);
        fifo_src_valid <= 1'b1;    
    end
    
    // stop adding more fifo source;
    @(posedge clk);
    fifo_src_valid <= 1'b0;
    
    // we know the transfer end to end is done;
    // when the two following conditions are true;
    wait((stream_ready_flag == 1'b1) && (stream_valid_flag == 1'b0));
    #(50);
    
    $display("test ends");
    $stop;
    end
endprogram 

`endif //CORE_VIDEO_LCD_DISPLAY_TB_SV