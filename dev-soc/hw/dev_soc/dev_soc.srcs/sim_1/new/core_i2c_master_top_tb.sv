`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 16:01:01
// Design Name: 
// Module Name: core_i2c_master_top_tb
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

`ifndef CORE_I2C_MASTER_TOP_TB_SV
`define CORE_I2C_MASTER_TOP_TB_SV

`include "IO_map.svh"

module core_i2c_master_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    /* interface arguents;; */
    // input;
    logic cs;
    logic write;
    logic read;
    logic [`REG_ADDR_SIZE_G-1:0] addr;    
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
   
    // output;
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    // i2c specific;
    tri scl;
    tri sda;
    
    // debugging;
    logic [32:0] test_index;

    
    /* instantiation */
    
    core_i2c_master uut
    (
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .write(write),
        .read(read),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .scl(scl),
        .sda(sda)
    );
    
    // test stimulus;
    core_i2c_master_tb tb(.*);
    
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
        $monitor("time: %0t, test index: %0d, cs: %0b, wr: %0b, rd: %0b, addr: %0B, user_cmd: %0B, wrdatad: %0D, wrdatab: %0B, rddata: %0B, scl: %0b, sda: %0b, uut.wr_clkmod: %0b, uut.wr_i2c: %0b",
            $time,
            test_index,
            cs,
            write,
            read,
            addr[2:0],
            uut.user_cmd,
            wr_data,
            wr_data,
            rd_data,
            scl,
            sda,
            uut.wr_clkmod,
            uut.wr_i2c,
           );
    end
    
    
    
endmodule

`endif //CORE_I2C_MASTER_TOP_TB_SV
