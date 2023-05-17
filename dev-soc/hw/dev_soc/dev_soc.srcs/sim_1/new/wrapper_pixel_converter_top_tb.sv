`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2023 16:11:42
// Design Name: 
// Module Name: wrapper_pixel_converter_top_tb
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


module wrapper_pixel_converter_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    /* ----------------------------
    * signals and mapping;
    ------------------------------*/
    // uut arguments;
    logic src_valid;
    logic src_ready;
    logic [7:0] src_data;
    logic sink_ready;
    logic sink_valid;
    logic [7:0] sink_data;
    
    logic debug_pass_src_valid;
    logic debug_pass_src_ready;
    logic [15:0] debug_pass_in_data;
    logic debug_pass_sink_ready;
    logic debug_down_wr;
    logic [7:0] debug_down_src_data;
    
    
    //> upstream fifo;
    // write interface (driven by the test stimulus)
    logic up_wr;
    logic up_full;
    logic [7:0] up_wr_data;
    
    // read interface (driven by the uut source side);
    logic up_rd;
    logic up_empty;    
    logic [7:0] up_rd_data;
    assign up_rd = src_ready && !up_empty;
    assign src_data = up_rd_data;
    assign src_valid = !up_empty;
    
    //> downstream fifo;
    // write interface (driven by the uut sink);
    logic down_wr;
    logic down_full;
    logic [7:0] down_wr_data;
    assign down_wr = sink_valid;
    assign sink_ready = !down_full;
    assign down_wr_data = sink_data;
    
    // read interface (driven by the test stimulus);
    logic down_rd;
    logic down_empty;    
    logic [7:0] down_rd_data;
    
    /* ----------------------------
    * instantiation;
    ------------------------------*/
    // upstream fifo;    
    FIFO 
    #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(8)
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
    
    
    // downstream fifo;        
    FIFO 
    #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(8)
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
    wrapper_pixel_converter uut(.clk(clk_sys), .reset(reset_sys), .*);
    
    // test stimulus;
    wrapper_pixel_converter_tb tb(.*);
    
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
       
    end    
    
endmodule
