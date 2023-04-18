`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.04.2023 21:26:28
// Design Name: 
// Module Name: i2c_master_controller_top_tb
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


module i2c_master_controller_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // constanst;
    localparam I2C_CLK_WIDTH = 32;       // for i2c clock counter;
    localparam I2C_TOTAL_CMD_NUM = 3;   // number of i2c command: start, stop, repeat_start etc..?
    localparam I2C_DATA_BIT = 8;
    
    // command constants;
    localparam CMD_START    = 3'b000;   // generate start condition;
    localparam CMD_WR       = 3'b001;   // master write to slave;
    localparam CMD_RD       = 3'b010;   // master reads from slave;
    localparam CMD_STOP     = 3'b011;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b100;   // generate repeated_start condition;
    
    /* uut argument; */
    // input;
    logic [I2C_CLK_WIDTH-1:0] user_cnt_mod;    // counter modulus;
    logic [I2C_TOTAL_CMD_NUM-1:0] user_cmd;    // what command: stop, start,?
    logic wr_i2c_start;                // initiate the i2c master;
    logic [I2C_DATA_BIT-1:0] din;             // i2c write data;
    
    // output;
    logic ready_flag;    // idle;
    logic done_flag;     // just finish i2c communications;
    logic ack; 
    logic [I2C_DATA_BIT-1:0] dout;   // slave data;
    
    // inout; i2c sda scl lines;
    tri scl;
    tri sda;
    
    // sim var;
    logic [31:0] test_index;
    
    /* instantiation */
    i2c_master_controller_tb tb(.*);
    
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
        $monitor("time: %0t, index: %0d, ", $time, test_index, );
    end
endmodule
