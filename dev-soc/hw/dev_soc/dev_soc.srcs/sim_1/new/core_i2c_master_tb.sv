`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.04.2023 16:00:43
// Design Name: 
// Module Name: core_i2c_master_tb
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

`ifndef CORE_I2C_MASTER_TB_SV
`define CORE_I2C_MASTER_TB_SV

`include "IO_map.svh"

module core_i2c_master_tb
    (
        input logic clk,
        input logic reset,
        
        // test stimulus;
        output logic cs,
        output logic write,
        output logic read,
        output logic [`REG_ADDR_SIZE_G-1:0] addr,    
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data, 
        input logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // i2c pins;
        input tri scl,
        inout tri sda,
        
        // sim;
        output logic [32:0] test_index  
    );
    
    localparam sys_freq = 100_000_000;  // 100MHz;
    //localparam scl_rate_candidate_01 = 2_500_000; // 2.5 MHz;
    localparam scl_rate_candidate_01 = 25_000_000; // 25 MHz;
    //localparam scl_program_candidate_mod_01 =  sys_freq/(4*scl_rate_candidate_01) - 1;
    localparam scl_program_candidate_mod_01 =  sys_freq/(4*scl_rate_candidate_01);
    
    // command constants;
    localparam CMD_NOP      = 3'b000;   // no operation;
    localparam CMD_START    = 3'b001;   // generate start condition;
    localparam CMD_WR       = 3'b010;   // master write to slave;
    localparam CMD_RD       = 3'b011;   // master reads from slave;
    localparam CMD_STOP     = 3'b100;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b101;   // generate repeated_start condition;

    // register offset;
    localparam I2C_REG_READ_OFFSET      = 2'b00;  
    localparam I2C_REG_CLKMOD_OFFSET    = 2'b01; 
    localparam I2C_REG_WRITE_OFFSET     = 2'b10;
    
    // bit pos;
    localparam I2C_REG_READ_BIT_POS_ACK = 8;
    localparam I2C_REG_READ_BIT_POS_READY = 9;
    
    logic[7:0] master_data;
    
    initial 
    begin
    $display("test starts");
    $display("----- master write --------");
    
    /* test - write mode only;
    1. set i2c clock rate;
    2. start i2c;
    3. issue write command;
    4. stop i2c;
    5. read ready flag;
    */
    // set clock rate;
    @(posedge clk);
    test_index <= 0;
    write <= 1'b1;
    read <= 1'b0;
    cs <= 1'b1;
    addr <= I2C_REG_CLKMOD_OFFSET;
    wr_data <= scl_program_candidate_mod_01;
    
    // issue a start;
    master_data = 8'($random);
    @(posedge clk);
    test_index <= 1;
    write <= 1'b1;
    cs <= 1'b1;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_START, master_data};
  
    // issue a write command; 
    @(posedge clk);
    test_index <= 2;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_WR, master_data};
    
    
    // probe the ready flag; 
    // issue a stop command;
    @(posedge clk);     // it takes one clock cycle to update the relevant bits;
    //wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b0);  // expect it to be busy;  
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b1);  // expect it to be eventually free;
    
    @(posedge clk);
    test_index <= 3;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_STOP, master_data};
    
    // expect the i2c controller to generate
    // a stop condition;
    // hence it will be busy for awhile to do this;
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b0);
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b1);
    
    // rest;
    #(100);
    
    $display("----- master read slave --------");
    /* test - read mode only;
    1. start i2c;
    3. issue read command;
    4. stop i2c;
    5. read ready flag;
    */
    
    // issue a start;
    @(posedge clk);
    test_index <= 4;
    
    // prep master ack bit (0) to distinguish;
    // if high, it will be HiZ on the sda line;
 
    master_data = {7'($random), 1'b0};  
    write <= 1'b1;
    cs <= 1'b1;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_START, master_data};
  
    // issue a read command; 
    @(posedge clk);
    test_index <= 5;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_RD, master_data};
    
    
    @(posedge clk);     // it takes one clock cycle to update the relevant bits;
    //wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b0);  // expect it to be busy;  
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b1);  // expect it to be eventually free;
    
    // issue stopl
    @(posedge clk);
    test_index <= 6;
    addr <= I2C_REG_WRITE_OFFSET;
    wr_data <= {21'b0, CMD_STOP, master_data};
    
    // expect the i2c controller to generate
    // a stop condition;
    // hence it will be busy for awhile to do this;
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b0);
    wait(rd_data[I2C_REG_READ_BIT_POS_READY] == 1'b1);
    
    
    #(100);
    
    $display("test stops");
    $stop;
    end
                                                                                                                                                                                                                                                                                            
    
endmodule

`endif //CORE_I2C_MASTER_TB_SV