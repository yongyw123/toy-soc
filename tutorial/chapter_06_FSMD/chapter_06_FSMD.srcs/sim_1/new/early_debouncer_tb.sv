`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 17:06:05
// Design Name: 
// Module Name: early_debouncer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for early_debouncer module;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module early_debouncer_tb();

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
    early_debouncer #(.N(N)) uut(.*);
            
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
    * recall that the debouncer filter window is set to around 80 ns;
    * so set glitches to < 80ms; this should be enough;
    */
    
    initial
    begin
        // avoid data setup and hold time;
    
        @(negedge clk);
        // first change from LOW to HIGH
        sw = 1'b1;
        // expect the db output to change from LOW to HIGH here instantaenously
        // but it is not possible to have instant change;
        // wait for some tiny delay before probing it;
        #(T/2);
        assert(db_output == 1'b1) $display("detected change, toggle the output");
            else $error("something went wrong");
        
        // introduce some glitechs between the filter window;
        @(negedge clk);
        sw = 1'b0;
        // expect that the db output remains high;
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        @(negedge clk);
        sw = 1'b1;
        
        @(negedge clk);
        sw = 1'b0;
        // still within the ignore-window;
        // expect that the db output remains high;
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        @(negedge clk);
        sw = 1'b1;
       
        #(4*T);                   
        @(negedge clk);
        sw = 1'b0;
        
        // more than 80 ns has elapsed since first change;
        // ignore-window expires
        // expect that the db output to change instantatenously;
        #(T/2);
        assert(db_output == 1'b0) $display("OK");
            else $error("something went wrong");
        
        // valid changes during ignore-window;
        @(negedge clk);
        sw = 1'b1;
       
        // entering into ignore-window;
        // expect the db output remains low;
        
        @(negedge clk);
        sw = 1'b1;
        assert(db_output == 1'b0) $display("OK");
            else $error("something went wrong");
        
        // 90ns > 80 ns;
        // ignore-windo expires;
        // expect the db output to change instantaneously to HIGH;
        // because the sw input is high at this point;
        #(8*T);     
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        // entering into ignore-window;
        // introduce change during this window;
        @(negedge clk);
        sw = 1'b0;
        // expect db to remain high
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        // introduce some glitches within the ignore window;
        // expect the db output not to changed;
        @(negedge clk);
        sw = 1'b1;
        
        // wait for another 75 ns to exit ignore-window;
        wait(debug_db_tick == 1'b1);    // asserted;
        wait(debug_db_tick == 1'b0);    // deasserted ==> ignore-window expires
        // introduce new change aftter ignore-window;
        @(negedge clk);
        sw = 1'b0;
        // expect db to change instantaneously;
        #(T/2);
        assert(db_output == 1'b0) $display("OK");
            else $error("something went wrong");
        
        // exiting ignore-window;
        // expect db changes;   
        @(negedge clk);
        sw = 1'b0;
        #(8*T);
        assert(db_output == 1'b0) $display("OK");
            else $error("something went wrong");
            
            
        // introduce sudden change after ignore-window expires 
        @(negedge clk);
        sw = 1'b1;
        // expect db outptu to instantaneously change to HIGH;
        #(T/2);
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        // introduce a valid change during the ignore-window;
        @(negedge clk);
        sw = 1'b0;
        // expect db not to change;
        assert(db_output == 1'b1) $display("OK");
            else $error("something went wrong");
        
        // exiting ignore window;
        #(8*T);
        // expect db to change;
        assert(db_output == 1'b0) $display("OK");
            else $error("something went wrong");
         
    
    $display("done");
    $stop;
    end        
endmodule