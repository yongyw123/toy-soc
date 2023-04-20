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
    localparam CMD_NOP      = 3'b000;   // no operation;
    localparam CMD_START    = 3'b001;   // generate start condition;
    localparam CMD_WR       = 3'b010;   // master write to slave;
    localparam CMD_RD       = 3'b011;   // master reads from slave;
    localparam CMD_STOP     = 3'b100;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b101;   // generate repeated_start condition;
    
    /* uut argument; */
    // input;
    logic [I2C_CLK_WIDTH-1:0] user_cnt_mod;    // counter modulus;
    logic [I2C_TOTAL_CMD_NUM-1:0] user_cmd;    // what command: stop, start,?
    logic wr_i2c;                // initiate the i2c master;
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
    logic [I2C_DATA_BIT-1:0] slave_data_write;
    // scl is either HiZ or Zero; so created anothe replicate of scl that is either high or low (well defined);
    logic debug_scl_sim;
    // fake sda; same reason as above;
    logic debug_sda_sim;
    
        
    /* instantiation */
    i2c_master_controller uut(.*);      // uut;
    i2c_master_controller_tb tb(.*);    // test stimulus;
    
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
        $monitor("cnt mod: %0d, uut.phase_quarter: %0d, uut.phase_half: %0d", user_cnt_mod, uut.phase_quarter, uut.phase_half);
        $monitor("time: %0t, index: %0d, uut.state: %s, cmd: %0d, start: %0b, ready: %0b, done: %0b, ack: %0b, din: %0B, dout: %0B, scl: %0b, scl_sim: %0b, sda: %0b, sda_sim: %0b, uut.sda_reg: %0b, uut.sethiz: %0b, uut.scl_next: %0b, uut.sda_next: %0b, uut.datacnt: %0d, uut.con_rd_slave: %0b, uut.wr_master: %0b, uut.phase: %0b, uut.cmd_reg: %0d, cmd_next: %0d",
         $time,
          test_index,
          uut.state_reg.name,
            user_cmd,
          wr_i2c,
          ready_flag,
          done_flag,
          ack,
          din,
          dout,
          scl,
          debug_scl_sim, 
            sda,
            debug_sda_sim,
         uut.sda_reg,
         uut.set_hiz,
         uut.scl_next,
         uut.sda_next,
         uut.data_cnt_reg,
         uut.condition_read_slave_data,
         uut.condition_master_read_ack,
         uut.phase_data,
         uut.cmd_reg,
         uut.cmd_next
         
         );
    end
endmodule
