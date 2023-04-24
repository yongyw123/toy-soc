`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 15:50:11
// Design Name: 
// Module Name: fifo_core_video_lcd_display_top_tb
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


module fifo_core_video_lcd_display_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    /* uut signal declare; */
    localparam DATA_WIDTH = 8;
    
    // source: left side of the fifo;
    logic [DATA_WIDTH-1:0] src_data;   // 8 bits;
    logic src_valid;   // source data is ready; perform the write;
    logic src_ready;  // fifo is ready to accept new data;
    
    // sink: right side of the fifo;
    logic [DATA_WIDTH-1:0] sink_data;
    logic sink_valid; // fifo is non-empty;
    logic sink_ready; // the sink is ready to ready data from this fifo;
    
    
    /* sink device signal declar */
    localparam CMD_WR   = 2'b01;
    logic sink_drive_wrx;
    tri[DATA_WIDTH-1:0] sink_dinout;
    logic sink_ready_flag;
    
    /* link the fifo with the sink device */
    assign sink_ready = sink_ready_flag;
    
    // instantiation;
    fifo_core_video_lcd_display 
    #(.DATA_WIDTH(DATA_WIDTH))
    uut
    (
    .clk(clk),
    .reset(reset),
    .src_data(src_data),
    .src_valid(src_valid),
    .src_ready(src_ready),
    .sink_data(sink_data),
    .sink_valid(sink_valid),
    .sink_ready(sink_ready)
    );
    
    
    lcd_8080_interface_controller
    #(.PARALLEL_DATA_BITS(DATA_WIDTH))
    sink_device
    (
        .clk(clk),
        .reset(reset),
        // wrx;
        .set_wr_mod_fhalf(1),    // first half of the write clock;     
        .set_wr_mod_shalf(1),    // second half of the write clockl
        
        // rdx;
        .set_rd_mod_fhalf(),    // first halfl;
        .set_rd_mod_shalf(),    // first halfl;
        
        // user argument;      
        .user_start(sink_valid),     // start communicating with the lcd;        
        .user_cmd(CMD_WR),       // read or write?
        
        .wr_data(sink_data),   
        .rd_data(),

        // status;
        .ready_flag(sink_ready_flag),    // idle;
        .done_flag(),     // just finish the rd/wr operation;
        
        .drive_wrx(sink_drive_wrx),   //  to drive the lcd for write op;
        .drive_rdx(),   // to drive the lcd for read op;          
        .dinout(sink_dinout) // this is shared between the host and the lcd;
        
    );
    /*
    // sink device to test the uut;
    lcd_8080_interface_controller
    #(.PARALLEL_DATA_BITS(DATA_WIDTH))
    sink_device
    (
        .clk(clk),
        .reset(reset),
        // wrx;
        .set_wr_mod_fhalf(1),    // first half of the write clock;     
        .set_wr_mod_shalf(1),    // second half of the write clockl
        // rdx;
        .set_rd_mod_fhalf(2),    // first halfl;
        .set_rd_mod_shalf(3),    // first halfl;
        
        // user argument;      
        .user_start(sink_valid),     // start communicating with the lcd;        
        .user_cmd(CMD_WR),       // read or write?
        
        .wr_data(sink_data),   
        .rd_data(),

        // status;
        .ready_flag(sink_ready),    // idle;
        .done_flag(),     // just finish the rd/wr operation;
        
        .drive_wrx(sink_drive_wrx),   //  to drive the lcd for write op;
        .drive_rdx(),   // to drive the lcd for read op;          
        .dinout(sink_dinout) // this is shared between the host and the lcd;
        
    );
    */
    
    
    
    // source device;
    fifo_core_video_lcd_display_tb
    #(.DATA_WIDTH(DATA_WIDTH))
    src_device
    (.*);
    
    /* simulate clk */
     always
        begin 
           clk = 1'b1;  
           #(T/2); 
           clk = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end
        
     
     /* monitoring */
     initial begin
        $monitor("time: %10t, src_data: %8B, src_valid: %b, src_ready: %b, sink_data: %8B, sink_valid: %b, sink_ready: %b",
        $time,
        src_data,
        src_valid,
        src_ready,
        sink_data,
        sink_valid,
        sink_ready
        );
        
     
     end
    
endmodule
