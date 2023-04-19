`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 15:07:53
// Design Name: 
// Module Name: core_i2c_master
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
`ifndef CORE_I2C_MASTER_SV
`define CORE_I2C_MASTER_SV

`include "IO_map.svh"

/**************************************************************
* S6_I2C_MASTER
--------------------
i2c master has three registers;

Register Map
1. register 0 (offset 0): read register 
2. register 1 (offset 1): i2c clock rate set register;
3. register 2 (offset 2): write register;

Register Definition:
1. register 0: read register
        bit[7:0]    received slave data;
        bit[8]      slave ACK bit;
        bit[9]      i2c master controller ready status

2. register 1: i2c clock rate register;
        all 32 bits are dedicated to the program the i2c clock;
        this is to program the clock counter modulus (mod):

3. register 2: write register;
        bit[7:0]    master 8-bit data to slave;
        bit[10:8]   i2c user commands;

Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;                 
******************************************************************/


module core_i2c_master
    #(parameter
        I2C_DATA_BIT = 8,
        I2C_TOTAL_CMD_NUM = 3   // total number of i2c commands;
    )
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        /* EXTERNAL PINS: I2C specific;*/
        // I2C standard signals;
        // i2c clock; only driven by the master;
        // declared state because in HiZ, the line is resistor-pulled-up;
        output tri scl, 
        // inout because shared between the master and the slave'
        // also, tri by the same reason as above; resistor pull up and multiple lines sharing;
        inout tri sda   
    );
      
    
    // constants;
    localparam I2C_REG_READ_OFFSET      = 2'b00;  
    localparam I2C_REG_CLKMOD_OFFSET    = 2'b01; 
    localparam I2C_REG_WRITE_OFFSET     = 2'b10;
    localparam I2C_REG_WRITE_BIT_POS_CMD_START  = 8;
    localparam I2C_REG_WRITE_BIT_POS_CMD_END    = 10;
    
    // enable signals;
    logic wr_en;
    logic wr_clkmod;
    //logic rd_en;  
    
    // i2c master controller siganls;
    logic[I2C_TOTAL_CMD_NUM-1:0] user_cmd;
    logic wr_i2c;
    logic [I2C_DATA_BIT-1:0] din;
    logic ready_flag;
    logic ack;
    logic [I2C_DATA_BIT-1:0] dout;
    
    /*
    register;
    1. only one register is needed here to register the i2c clock mod;
    2. the rest has already been created in the i2c_master_controller() module;
    */
    logic [31:0] clkmod_reg, clkmod_next;
    
    // instantiation;
    i2c_master_controller #(.I2C_DATA_BIT(I2C_DATA_BIT))
    unit
    (
        .clk(clk),
        .reset(reset),
        .user_cnt_mod(clkmod_reg),
        .user_cmd(user_cmd),
        .wr_i2c(wr_i2c),
        .din(din),
        .ready_flag(ready_flag),
        
        .ack(ack),
        .dout(dout),
        .scl(scl),
        .sda(sda),
        
        // not used
        .done_flag(),   
        .debug_scl_sim(),
        .debug_sda_sim() 
        
    ); 
   
    always_ff @(posedge clk, posedge reset)
        if(reset)
            clkmod_reg <= 0;    // 0 means disabled;
        else
            if(wr_clkmod)
                clkmod_reg <= clkmod_next;

    /* write decoding; */
    assign wr_en = cs & write;
    assign wr_clkmod = wr_en & (addr[1:0] == I2C_REG_CLKMOD_OFFSET);
    // make this automatically: to start the i2c controller when write register is decoded;
    assign wr_i2c = wr_en & (addr[1:0] == I2C_REG_WRITE_OFFSET);
    
    /* inputs to the unit;*/
    // need to be careful of the bit position since the register shares multiple data;
    assign din = wr_data[I2C_DATA_BIT-1:0];
    assign user_cmd = wr_data[I2C_REG_WRITE_BIT_POS_CMD_END: I2C_REG_WRITE_BIT_POS_CMD_START];
    assign clkmod_next = wr_data; 
    
    // read multiplezing;
    // this is not necessary since there is only one read register;
    //assign rd_en = cs & write & (addr[1:0] == I2C_REG_READ_OFFSET);  
    
    /*
    1. register 0: read register
        bit[7:0]    received slave data;
        bit[8]      slave ACK bit;
        bit[9]      i2c master controller ready status
    */
    //assign rd_data = (rd_en) ? {22'b0, ready_flag, ack, dout} : 32'b0;
    assign rd_data = {22'b0, ready_flag, ack, dout};
    
    
endmodule


`endif // CORE_I2C_MASTER_SV
