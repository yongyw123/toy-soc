`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 15:32:18
// Design Name: 
// Module Name: universal_binary_counter_tb
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


module universal_binary_counter_tb();
    // declare;
    localparam T = 20;  // clk period: 20ns
    localparam N = 3;   // number of bits for the counter;
    logic clk;
    logic reset;
    
    // main input
    logic syn_clr;
    logic load;
    logic en;
    logic up;
    logic [N-1:0] d;
    logic [N-1:0] q;
    logic max_flag, min_flag;
    
    // uut instantiate;
    universal_binary_counter #(.N(N)) uut(.*);
    
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
    end
    
    // start;
    initial
    begin
        // setup init value;
        syn_clr  = 1'b0;
        load = 1'b0;        
        en = 1'b0;
        up = 1'b1;
        d = 3'b000;
        @(negedge reset);   
        @(negedge clk);

        // test load;
        load = 1'b1;
        d = 3'b011;
        @(negedge clk);
        load = 1'b0;
        repeat(2) @(negedge clk);
 
        // test syn clear;
        syn_clr  = 1'b1;
        @(negedge clk );
        syn_clr  = 1'b0;
        
        // test enable and count up;
        en = 1'b1;
        up = 1'b1;
        repeat(10) @(negedge clk);
        en = 1'b0;	// pause counting;
		repeat(2) @(negedge clk);
		en = 1'b1;	// resume counting;
		repeat(2) @(negedge clk);
		
        // test enable and count down;
		up = 1'b0;	// count down;
		repeat(10) @(negedge clk);

        // test min and max flags;
        wait(q == 2);
		@(negedge clk);
		up = 1'b1;
		@(negedge clk);
		wait(min_flag);
		@(negedge clk);
		up = 1'b0;
		
		#(4*T);
		en = 1'b0;
		#(4*T);
    
        $stop;
    end
endmodule
