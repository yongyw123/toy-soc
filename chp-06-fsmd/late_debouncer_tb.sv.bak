`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 15:02:09
// Design Name: 
// Module Name: late_debouncer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for module: late_debouncer;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module late_debouncer_tb();
    // declare;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    
    // main input of the uut;
    logic sw;            // input to debounce;
    logic db_output;     // output; debounced;
    logic debug_db_tick;  // output; for debugging convenience;
    
    // uut instantiate;
    /*
    * note;
    * by default, debouncer filter window is 40ms;
    * this requires N = 22-bit counter;
    * this wastes the simulation time;
    * instead, we use N = 3 ==> 2^{N} * 10ns = 80 ns; 
    * for simulation purposes; 
    * note that since N = 3 is in nano scale;
    * it would be an exact 80 ns; it will be slightly off (?);
    */
    localparam N = 3;
    late_debouncer #(.N(N)) uut(.*);
            
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
        
        @(negedge reset); // avoid data setup and hold time for subsequent simulation;
    end
    
    // setup the input;
    initial
    begin
        sw = 1'b0;
    end
    
    /*
    * start the test;
    *  test 01: LOW to HIGH transition;
    *       1. have a few glitches before stablizing at HIGH;
    * test 02: flip test 01;
    *
    * recall that the debouncer filter window is 40ms;
    * so set glitches to < 20ms; this should be enough;
    */
    
    initial
    begin
        /* test 01: transition from LOW to HIGH */
        // avoid data setup and hold time;
           
        @(negedge clk);
        // simulate glitches;
        sw = 1'b1;
        @(negedge clk);
        sw = 1'b0;
        @(negedge clk);
        sw = 1'b1;
        @(negedge clk);
        sw = 1'b0;
        @(negedge clk);
        sw = 1'b1;
        
        // this amounts tp 40ns of HIGH but still considered as glitches;
        // since the filter window is 80ns;
        #(4*T);             
        assert(db_output == 1'b0) $display("considered glitches");
            else $error("something went wrong");
        
        // simulate stable input;
        @(negedge clk);
        sw = 1'b1;
        #(9*T);     // 90ns > 80 ns; considered stable;
        assert(db_output == 1'b1) $display("debounced to HIGH");
            else $error("something went wrong");
        
        /* test 02: transition from HIGH to LOW */
        @(negedge clk);
        sw = 1'b0;
        @(negedge clk);
        sw = 1'b1;
        @(negedge clk);
        sw = 1'b0;
        // this amounts tp 40ns of LOW but still considered as glitches;
        // since the filter window is 80ns;    
        #(4*T);
        assert(db_output == 1'b1) $display("considered glitches");
            else $error("something went wrong");
            
        // LOW for at least 80 ns; considered as valid transition;
        @(negedge clk);
        sw = 1'b0;
        #(8*T);
        assert(db_output == 1'b0) $display("debounced to LOW");
            else $error("something went wrong");
    
    $display("done");
    $stop;
    end        
endmodule
