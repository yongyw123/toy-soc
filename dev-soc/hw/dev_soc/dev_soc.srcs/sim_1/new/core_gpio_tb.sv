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


module core_gpio_tb();
    // general;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    
    // specific;
    localparam PORT_WIDTH = 16;            // gpio port width;
    logic cs;                               // input; chip select;
    logic write;                            // input;
    logic read;                             // input;
    logic [REG_ADDRESS_WIDTH -1:0] addr;    // input; register address;
    logic [DATA_WIDTH-1:0] wr_data;         // input;
    logic [DATA_WIDTH-1:0] rd_data;     // input;
    tri [PORT_WIDTH-1:0] dinout;        // tristate for gpio;
    
    // internal register of the core;
    localparam REG_DATA_OUT_OFFSET = 2'b00;         // for output data;
    localparam REG_DATA_IN_OFFSET = 2'b01;          // for input data;
    localparam REG_CTRL_DIRECTION_OFFSET = 2'b10;   // for direction control;
    
    // simulation var;
    logic [PORT_WIDTH-1:0] temp_wr_data;
    logic [PORT_WIDTH-1:0] temp_rd_data;
    logic [PORT_WIDTH-1:0] dir_all_out_data;
    logic [PORT_WIDTH-1:0] dir_all_in_data;
    logic [PORT_WIDTH-1:0] clean_data;

    // instantiation;
    core_gpio #(.PORT_WIDTH(PORT_WIDTH)) uut(.*);
    
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // reset before simulating;
    // by default, all data input output buffers are zero;
    // by default, the direction is input;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
        @(negedge clk); // avoid data setup and hold time for subsequent simulation;
    end
    
    // setup some init value;
    // this is necessary since not all bits are used;
    // need to set the rest to avoid "X" unknown values;
    initial
    begin
        addr = 5'b0;        // reset the register address
        wr_data = 32'b0;     // reset the write data;  
    end
    
    /* (main) what to test;
    1. the hard part is that different port could have different directions;
    2. separate into easy case and hard case;
    
    easy case;
    1. either all out or all in;
    2. if all out; then what is written will be passed to the output;
    3. if all in; then what is on the port will be fed into the input;
    
    hard case;
    1. randomly set the direction of each port;
    2. same criteria as above;
    */
    initial
    begin
        temp_wr_data = PORT_WIDTH'($random);
        temp_rd_data = PORT_WIDTH'($random);
        dir_all_out_data = PORT_WIDTH'(32'hFFFF);
        dir_all_in_data = PORT_WIDTH'(0);
        clean_data = PORT_WIDTH'(0);
    end
    
    /* input port direction */
    // dinout is tri-type;
    // cannot be assigned by another value in a procedural block;
    assign dinout = (read && !write) ? temp_rd_data : PORT_WIDTH'(16'bz);
    
    initial
    begin
    
        // enable write operation;
        read = 1'b0;    // read signal is not used in the timer module; ignored;
        write = 1'b1;
        cs = 1'b1;
        
        /* test 01: easy case; input direction but forceful write (output) */
        $display("----- test 01 -----");
        @(negedge clk);
        // write data to the output buffer;
        // but direction is configured as input by the reset above;
        addr[1:0] = REG_DATA_OUT_OFFSET;    
        wr_data[PORT_WIDTH - 1:0] = temp_wr_data;
        // expect the dinout to be high impedance because direction is inwards;
        @(negedge clk);   
        #1 assert(dinout == PORT_WIDTH'(16'bz)) $display("Ok");
            else $error("%0t", $time);
        
        // now change all ports to output direction;
        @(negedge clk);
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_all_out_data;
        // it takes one clock cycle to update the state;
        @(negedge clk); 
        // expect that the dinout reflects the write data;
        #1 assert(dinout == temp_wr_data) $display("Ok");
                else $error("%0t", $time);
        
        // now change back to input direction;
        @(negedge clk);
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_all_in_data;
        
        // enable read and disable write;
        @(negedge clk); 
        read = 1'b1;
        write = 1'b0;
        
        // it takes one clock cycle to update the state;
        @(negedge clk); 
        
        // expect that the dinout reflects the data written at the input port for reading;
        #1 assert(dinout == temp_rd_data) $display("Ok");
            else $error("%0t", $time);
            
            
       /* test 02: hard case; mixture */
       
    $stop;
    end
    
    
endmodule
