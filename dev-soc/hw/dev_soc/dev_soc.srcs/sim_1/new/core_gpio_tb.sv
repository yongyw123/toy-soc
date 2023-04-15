`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2023 01:51:44
// Design Name: 
// Module Name: core_gpio_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for core_gpio module;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


program core_gpio_tb
    #(parameter
    PORT_WIDTH = 4,
    REG_ADDRESS_WIDTH = 5
    )
    (
    input logic clk,
    output logic reset,
    // uart system;
    output logic read,
    output logic write,
    output logic cs,
    logic [REG_ADDRESS_WIDTH-1:0] addr,
    output logic [PORT_WIDTH-1:0] wr_data,
    output logic[4:0] test_index
    
    );
    
    // internal register of the core;
    localparam REG_DATA_OUT_OFFSET = 2'b00;         // for output data;
    localparam REG_DATA_IN_OFFSET = 2'b01;          // for input data;
    localparam REG_CTRL_DIRECTION_OFFSET = 2'b10;   // for direction control;
    
    initial begin
    $display("start");
    /* test;
    1. expect if cs is not asserted;
    2. rd and wr have no effect on the rd_data and dinout;
    3. rd_data and dinout should be unknown;
    */
    
    // try read data;
    @(posedge clk);
    test_index <= 0;
    
    cs <= 1'b0;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_DATA_IN_OFFSET;
    
    // try read direction;
    @(posedge clk);
    test_index <= 1;
    
    cs <= 1'b0;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    
    /*test : chip enabled; read input data;
    1. after reset; rd_data is all high impedance;
    2. since direction is all input which sets the output port to high impedance;
    */
    // try read data;
    @(posedge clk);
    test_index <= 2;
    
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_DATA_IN_OFFSET;
    
    /*test : chip enabled; read direction data;
    1. after reset; direction is all input 
    */
    
    // try read direction;
    @(posedge clk);
    test_index <= 3;
    
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    
    /*test : chip enabled; write direction;
    1. set all ports to out; 
    2. expect rd_data to retain prev rd_data since rd is disabled;
    3. expect dinout to be all zero, since wr_data is reset to zero;
    */
    
    @(posedge clk);
    test_index <= 4;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    wr_data = (PORT_WIDTH)'(32'hFFFF_FFFF);
   
    // read the direction reg;
    @(posedge clk);
    test_index <= 5;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    
    
    /*test : chip enabled; write something with all ports in write direction
    1. expect rd_data to retain prev rd_data since rd is disabled;
    2. expect dinout to reflect the write data (after one clock cycle);
    */
    
    @(posedge clk);
    test_index <= 6;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr[1:0] = REG_DATA_OUT_OFFSET;
    wr_data = (PORT_WIDTH)'(32'hAAAA_AAAA);
    // it takes one clock cycle to update the dinout;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b0;
    
    /*test : chip enabled; set all ports to read;
    1. expect dinout to be all high impedance after one cycle;
    */
    @(posedge clk);
    test_index <= 7;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    wr_data = (PORT_WIDTH)'(32'h0000_0000);
    
    // it takes one clock cycle to update the dinout;
    // expect rd_data to take in previous dinout;
    // because by construction; rd_data will sample dinout every clock
    // cycle without any control enable;

    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_DATA_IN_OFFSET;
    
    // check the ctrl dir register;
    // expect rd_data to reflect the set control direction;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    
    /*test : mix direction;
    * if the port is set to input; dinout of that port shall be high imepdance;
    * otherwise, it shall reflect whatever is written at its port;
    */
    // first write some data before changing the direction;
    @(posedge clk);
    test_index <= 8;
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr[1:0] = REG_DATA_OUT_OFFSET;
    wr_data = (PORT_WIDTH)'($random);
    
    // mix the direction;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b0;
    write <= 1'b1;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    wr_data = (PORT_WIDTH)'($random);
    
    // check the rd_data;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_DATA_IN_OFFSET;
    
    @(posedge clk);
    
    // check the ctrl dir register;
    @(posedge clk);
    cs <= 1'b1;
    read <= 1'b1;
    write <= 1'b0;
    addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
    
    @(posedge clk);
    
    @(posedge clk);
    cs <= 1'b0;
    read <= 1'b1;
    write <= 1'b0;
    
   
    
    #(10);
    $display("done");
    $stop;
    end
    
    
endprogram
