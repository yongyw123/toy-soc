`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2023 03:21:34
// Design Name: 
// Module Name: lcd_8080_interface_controller_top_tb
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


module lcd_8080_interface_controller_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    localparam PARALLEL_DATA_BITS = 8;
    
    // command constanst;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
    
    // uut arguments;
    // the mod here corresponds to the half write/read cycle period;
    logic [31:0] set_wr_mod;     // set the write cycle time;
    logic [31:0] set_rd_mod;     // set the read cycle time;
    
    // user argument;      
    logic user_start;     // start communicating with the lcd;        
    logic [1:0] user_cmd;       // read or write?
    
    logic [PARALLEL_DATA_BITS-1:0] wr_data;   
    logic [PARALLEL_DATA_BITS-1:0] rd_data;

    // status;
    logic ready_flag;    // idle;
    logic done_flag;    // just finish the rd/wr operation;
    
    /* hw pins 
    note that there are other hw pins not listed here;
    dcx, rst, and cs;
    these pins could be configured as general pins;
    not necessary to integrate here;       
    */
    logic drive_wrx;  //  to drive the lcd for write op;
    logic drive_rdx;   // to drive the lcd for read op;          
    tri[PARALLEL_DATA_BITS-1:0] dinout; // this is shared between the host and the lcd;

    // sim var;
    logic [31:0] test_index;
    
    /* instantiation */
    lcd_8080_interface_controller uut(.*);      // uut;
    lcd_8080_interface_controller_tb tb(.*);    // test stimulus;
    
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
    initial
    begin
        $monitor("cnt mod: %0d", set_wr_mod);
        $monitor("time: %0t, index: %0d, uut.state: %s, cmd: %0d, start: %0b, ready,: %0b, done: %0b, wrx: %0b, rdx: %0b, wr_data: %0B, rd_data: %0B, dinout: %0B, uut.cmd_reg: %0d, uut.hiz: %0b",
        $time,
        test_index,
        uut.state_reg.name,
        user_cmd,
        user_start, 
        ready_flag,
        done_flag,
        drive_wrx,
        wr_data, 
        drive_rdx,
        rd_data,
        dinout,
        uut.cmd_reg,
        uut.set_hiz);
    end

    
   
    
endmodule
