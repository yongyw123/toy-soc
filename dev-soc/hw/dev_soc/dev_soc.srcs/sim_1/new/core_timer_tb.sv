`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 14:26:38
// Design Name: 
// Module Name: core_timer_tb
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


module core_timer_tb();
    // general;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    localparam OUTPUT_WIDTH = 8;        // output data width size;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    
    // main input of the uut;
    logic cs;                               // input; chip select;
    logic write;                            // input;
    logic read;                             // input;
    logic [REG_ADDRESS_WIDTH -1:0] addr;    // register address;
    logic [DATA_WIDTH-1:0] wr_data;         // input;
    logic [DATA_WIDTH-1:0] rd_data;         // input;
    
    // register map of the timer core;
    localparam REG_CNTLOW_OFFSET = 2'b00;
    localparam REG_CNTHIGH_OFFSET = 2'b01;
    localparam REG_CTRL_OFFSET = 2'b10;
    localparam REG_CTRL_GO_POS = 1'b0;
    localparam REG_CTRL_CLEAR_POS = 1'b1;
    
    // simulation var;
    int j;  // loop index;
    
    // uut instantiate;
    core_timer uut(.*);
    
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // reset before simulating;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
        @(negedge clk); // avoid data setup and hold time for subsequent simulation;
    end
    
    /* what to test;
    background
    1. timer core has three registers;
    2. first two registers are for counter value; each reg holds 32-bit;
    3. last register is the control register;
    4. timer core has two control signals: clear and go located in the ctrl reg;
    
    to test
    1. control signals;
    2. register mapping;
    
    expectation;
    0. if clear is applied, then the counter should reset to zero;
    1. if clear is always asserted, then the counter value should
        always be zero regardless of the go status;
    2. with clear deasserted, HIGH go should have the counter free running;
        LOW go should pause the counter;
    
    difficult to test;
    1. the timer counter is 64-bit;
    2. hard to check the counter value;
    3. this is not checked as the author has not found a way to test this yet;
    
    backnote;
    1. 64-bit counter;
    2. each clock should increment the count;
    
    */
    
    // setup some init value;
    // this is necessary since not all bits are used;
    // need to set the rest to avoid "X" unknown values;
    initial
    begin
        addr = 5'b0;        // reset the register address
        wr_data = 32'b0;     // reset the write data;  
    end
    
    initial
    begin
        /*
        for(int j = 0; j < 10; j++) begin
            @(posedge clk);
            $display("time: %0t, index: %0d", $time, j);
        end
        */  
        /* --------- test 01: go asserted + counter free running */
        $display("----- test 01 -----");
        @(negedge clk);
        // enable write operation;
        read = 1'b0;    // read signal is not used in the timer module; ignored;
        write = 1'b1;
        cs = 1'b1;
        addr[1:0] = REG_CTRL_OFFSET;    // control register;
        wr_data[1:0] = 2'b01;           // go HIGH, clear LOW:
        
        @(posedge clk); // clock in the inputs above;
        
        // let the counter run;
        // expect the counter to increment from zero;
        // and match with the index, i;
        for(j = 0; j < 10; j++) begin
            @(posedge clk);
            $display("time: %0t, index: %0d", $time, j);
        end
        
        // get the counter value;
        // expect the lowerword has some value; upperword to be zero;
        addr[1:0] = REG_CNTLOW_OFFSET;
        $display("check the counter val");
        #1 $display("lowercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        addr[1:0] = REG_CNTHIGH_OFFSET;
        #1 $display("uppercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
                     
        /* ---------- test 02: go paused + check counter paused */
        $display("----- test 02 -----");
        @(negedge clk);
        // enable write operation;
        read = 1'b0;    // read signal is not used in the timer module; ignored;
        write = 1'b1;
        cs = 1'b1;
        addr[1:0] = REG_CTRL_OFFSET;    // control register;
        wr_data[1:0] = 2'b00;           // go LOW, clear LOW:
        
        // clock in the inputs above;
        // expect this to increment the counter by one;
        @(posedge clk); 
        
        // check the counter value before let the clock running;
        // compare this and the value after the clock has run;
        $display("before paused; check the counter val");
        addr[1:0] = REG_CNTLOW_OFFSET;
        #1 $display("lowercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        addr[1:0] = REG_CNTHIGH_OFFSET;
        #1 $display("uppercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        
        // chekc if the counter runs;
        $display("clock is free running");
        for(j = 0; j < 10; j++) begin
            @(posedge clk);
            $display("time: %0t, index: %0d", $time, j);
        end
        
        // get the counter value;
        // expect the lower word to be the same as in the previous tets;
        addr[1:0] = REG_CNTLOW_OFFSET;
        $display("after paused; check the counter val");
        #1 $display("lowercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        addr[1:0] = REG_CNTHIGH_OFFSET;
        #1 $display("uppercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        /* ---------- test 03: clear */
        $display("----- test 03 -----");
        @(negedge clk);
        // enable write operation;
        read = 1'b0;    // read signal is not used in the timer module; ignored;
        write = 1'b1;
        cs = 1'b1;
        addr[1:0] = REG_CTRL_OFFSET;    // control register;
        wr_data[1:0] = 2'b10;           // go LOW, clear HIGH:
        
        @(posedge clk); // clock in the inputs above;
        
        // get the counter value;
        // expect counter to reset to zero;
        addr[1:0] = REG_CNTLOW_OFFSET;
        $display("check the counter val");
        #1 $display("lowercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        addr[1:0] = REG_CNTHIGH_OFFSET;
        #1 $display("uppercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        /* ---------- test 04: clear and go asserted simultaneously*/
        $display("----- test 04 -----");
        @(negedge clk);
        // enable write operation;
        read = 1'b0;    // read signal is not used in the timer module; ignored;
        write = 1'b1;
        cs = 1'b1;
        addr[1:0] = REG_CTRL_OFFSET;    // control register;
        wr_data[1:0] = 2'b11;           // go HIGH, clear HIGH;
        
        @(posedge clk); // clock in the inputs above;
        
        // let it running;
        // expect the counter to be zero regardless;
        // chekc if the counter runs;
        for(j = 0; j < 10; j++) begin
            @(posedge clk);
            $display("time: %0t, index: %0d", $time, j);
        end
        
        // get the counter value;
        // expect counter to reset to zero;
        addr[1:0] = REG_CNTLOW_OFFSET;
        $display("check the counter val");
        #1 $display("lowercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
        addr[1:0] = REG_CNTHIGH_OFFSET;
        #1 $display("uppercount - time: %0t, index: %0d, rd_datab: %0B, rd_datad: %0d",
                     $time, j, rd_data, rd_data);
        
    $stop;
    end
    
    
    
    
    
endmodule
