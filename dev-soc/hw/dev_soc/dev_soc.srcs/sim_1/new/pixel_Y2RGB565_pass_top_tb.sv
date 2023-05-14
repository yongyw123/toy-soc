`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 17:44:46
// Design Name: 
// Module Name: pixel_Y2RGB565_pass_top_tb
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



module pixel_Y2RGB565_pass_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset;        // async system reset;
    
    /* uut arguments; */
    // interface with the upper stream;
    logic src_valid;    
    logic src_ready;
    
    // interface with the upper conversion block;
    logic [15:0] converted_rgb565_in;
    
    // interface with the down stream;
    logic sink_ready;
    logic sink_valid;
    logic [7:0] rgb565_out;
    
    
    /* fifo upstream arguments */
    logic up_rd;
    logic up_wr;
    logic up_empty;
    logic up_full;
    logic [15:0] up_wr_data;
    logic [15:0] up_rd_data;
    
    assign up_rd = !up_empty && src_ready;
    assign src_valid = !up_empty;
    assign converted_rgb565_in = up_rd_data;
    
    /* fifo downstream arguments */
    logic down_rd;
    logic down_wr;
    logic down_empty;
    logic down_full;
    logic [7:0] down_wr_data;
    logic [7:0] down_rd_data;
    
    assign down_wr_data = rgb565_out;
    assign sink_ready = !down_full;
    assign down_wr = sink_valid;    
    
    /* instantiation */
    // upstream fifo (16-bit);
    FIFO 
    #(
        .DATA_WIDTH(16), 
        .ADDR_WIDTH(4)
    )
    fifo_upstream
    (
        .clk(clk_sys),
        .reset(reset),
        
        .ctrl_rd(up_rd),
        .ctrl_wr(up_wr),
        .flag_empty(up_empty),
        .flag_full(up_full),
        
        .rd_data(up_rd_data),
        .wr_data(up_wr_data)
    );
    
    // downstream fifo (8-bit)
    FIFO 
    #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(2)
    )
    fifo_downstream
    (
        .clk(clk_sys),
        .reset(reset),
        
        .ctrl_rd(down_rd),
        .ctrl_wr(down_wr),
        .flag_empty(down_empty),
        .flag_full(down_full),
        
        .rd_data(down_rd_data),
        .wr_data(down_wr_data)
                
    );
    
    // uut;
    core_video_pixel_converter_monoY2RGB565(.*);
    
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
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end

    /* monitoring system */
    //initial begin
         
    

endmodule
