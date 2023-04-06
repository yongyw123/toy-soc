`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 02:25:20
// Design Name: 
// Module Name: core_gpi_tb
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


module core_gpi_tb();
    // general;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    localparam INPUT_WIDTH = 8;        // input data width size;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    
    // main input of the uut;
    logic cs;                       // input; chip select;
    logic write;                    // input;
    logic read;                     // input;
    logic [REG_ADDRESS_WIDTH -1:0] addr;  // input; register address;
    logic [DATA_WIDTH-1:0] wr_data; // input;
    logic [DATA_WIDTH-1:0] rd_data; // input;
    logic [INPUT_WIDTH-1:0] din;
    
    // uut instantiate;
    core_gpi #(.W(INPUT_WIDTH)) uut(.*);
            
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
    
    /* 
    * what to test?
    * as of now, the GPI core is constructed as a simple 
    * register to sample the input without relying any control signals 
    * of the core interface;
    *
    * so, check:
    * 1. whether the input is sampled correctly
    * 2. the sampled data is truncated correctly before passed as output;
    */
    bit[3:0] i;
    
    initial
    begin
        for(i = 0; i <= 4'b0111 ; i++) begin 
            @(negedge clk);
            // control signals should not matter but included just in case;
            cs = i[0];
            write = i[1];
            read = i[0];                     // expect to be ignored;
            wr_data = 32'h2 * 10'($random);  // expect to be ignored;
            addr = 5'h12345;                // expect to be ignored;
            
            // main stimulus;
            din = INPUT_WIDTH'($random);
            
            /* main response to check: rd_data;*/
            
            // it takes one clock cycle to update the output;
            @(negedge clk);
            
            $display("time: %0t, index: %0B, cs: %0b, write: %0b, wr_data: %0B, din: %0B, rd_data: %0B",
                     $time, i, cs, write, wr_data, din, rd_data);
    
        end    
    $display("done");
    $stop;
    
    
    end
endmodule
