`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 00:55:39
// Design Name: 
// Module Name: core_gpo_tb
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


module core_gpo_tb();
    // general;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    localparam OUTPUT_WIDTH = 8;        // output data width size;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    // main input of the uut;
    logic cs;                       // input; chip select;
    logic write;                    // input;
    logic read;                     // input;
    logic [OUTPUT_WIDTH-1:0] addr;  // register address;
    logic [DATA_WIDTH-1:0] wr_data; // input;
    logic [DATA_WIDTH-1:0] rd_data; // input;
    logic [OUTPUT_WIDTH-1:0] dout;
    
    
    /*
    * expectation (what could go wrong);
    * 1.  only inputs: write AND cs will trigger a write operation;
    * 2. input: read;  no effect;
    * 3. output: dout: truncated to W-size;
    *
    */

    // uut instantiate;
    core_gpo #(.W(OUTPUT_WIDTH)) uut(.*);
            
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // reset for the counter before simulating;
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
    * control signal: cs and write vs dout;
    * four combinations;
    * {cs, write};
    */
    bit[3:0] i;
    initial
    begin
        // go beyond 4 patterns with randomized random data;
        // by above, only expect the dout to be updated with cs and write set;
        // otherwise, dout should maintain as it is;
        for(i = 0; i <= 4'b0111 ; i++) begin 
            @(negedge clk);
            cs = i[0];
            write = i[1];
            read = i[0];            // expect to be ignored;
            wr_data = 32'h2 * 10'($random);  // some random pattern;
            addr = 5'h12345;         // expect to be ignored;
            
            // it takes one clock cycle to update the output;
            @(negedge clk);
            
            $display("time: %0t, index: %0B, cs: %0b, write: %0b, wr_data: %0B, dout: %0b",
                     $time, i, cs, write, wr_data, dout);
        end
        
    $display("done");
    $stop;
    end 
endmodule
