`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.04.2023 15:51:37
// Design Name: 
// Module Name: stack_ctrl_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for stack_ctrl module; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stack_ctrl_tb();
// general;
    localparam T = 10;  // clk period; 10ns;
    localparam ADDR_WIDTH = 4;  // total address = 2^{4};
    localparam total_addr_num = 2**ADDR_WIDTH;
    logic clk;    
    logic reset;
    
    // inputs for the module under test;
    logic pop, push;     // [input] control signal fo read and write;
    logic flag_overflow, flag_underflow;     // [output] flag signals
    logic [ADDR_WIDTH-1:0] push_addr;  // [output] write address; pointing at the next available stack space;
    logic [ADDR_WIDTH-1:0] pop_addr;  // [output] read address; pointing at the top non-empty content;
    logic [ADDR_WIDTH-1:0] stack_curr_size; // [output] current stack size;
    // simulate clk;
    always
        begin
            clk = 1'b1;
            #(T/2);
            clk = 1'b0;
            #(T/2);
        end
   
   
   // uut instantiate;
   stack_ctrl #(.ADDR_WIDTH(ADDR_WIDTH)) uut(.*);
        
    // apply reset;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
        @(negedge clk); // avoid data setup and hold time for subsequent simulation;
    end
   
    // set up intiial values;
    initial
    begin
        pop = 1'b0;
        push = 1'b0;
        @(negedge clk); 
        
    end
    
    // start testing
    initial
    begin
    
    $display("---- check stack state after reset -----");
    $display("time: %0t, pop_addr: %0d, push_addr: %0d, flag_overflow: %0d, flag_underflow: %0d, stack curr size: %0d",
                     $time, pop_addr, push_addr, flag_overflow, flag_underflow, stack_curr_size);
    assert((flag_underflow == 1'b1)&&(flag_overflow == 1'b0)) $display("OK");
        else $error("something went wrong");
        
    $display("---- push until overflow -----");
    @(negedge clk);
    pop  = 1'b0;    // push only;
    for(int i = 0; i < (total_addr_num + 10); i++) begin
        @(negedge clk);
        push = 1'b1;
        #5 $display("time: %0t, index: %0d, push_addr: %0d, pop_addr: %0d, flag_overflow: %0d, flag_underflow: %0d, stack curr size: %0d",
                     $time, i, push_addr, pop_addr, flag_overflow, flag_underflow, stack_curr_size);
    end
    
    $display("--------- pop until underflow -------------");
    @(negedge clk);
    push = 1'b0; // pop only 
    for(int i = 0; i < (total_addr_num + 10); i++) begin
        @(negedge clk);
        pop = 1'b1;
        #5 $display("time: %0t, index: %0d, push_addr: %0d, pop_addr: %0d, flag_overflow: %0d, flag_underflow: %0d, stack curr size: %0d",
                     $time, i, push_addr, pop_addr, flag_overflow, flag_underflow, stack_curr_size);

    end
    
    $display("--------- pop and push simultaneously with stack content empty apriori -------------");
    /* expectation
        by previous underflow, this test section will always result in stack underflow;
        because pop and push simultaneous actions amount to nothing;
        thereby, we should also expect that the address will not change throughout;
    */
    @(negedge clk);
    pop = 1'b0; // reset;
    push = 1'b0; // reset; 
    for(int i = 0; i < (total_addr_num + 10); i++) begin
        @(negedge clk);
        pop = 1'b1;
        push = 1'b1;
        #5 $display("time: %0t, index: %0d, push_addr: %0d, pop_addr: %0d, flag_overflow: %0d, flag_underflow: %0d, stack curr size: %0d",
                     $time, i, push_addr, pop_addr, flag_overflow, flag_underflow, stack_curr_size);

    end


    $display("--------- pop and push simultaneously with non empty stack -------------");
    /* expectation: 
        this repeats the previous test but with non empty but non full stack;
        we should not expect underflow or overflow flags;
        also, by above simultaneous push and pop will not change the address;
    */
    
    // reset;
    reset = 1'b1;
    #(T/2);
    reset = 1'b0;
    #(T/2);
    
    // ensure non empty stack;
    @(negedge clk);
    push = 1'b1;
    pop = 1'b0;
    @(negedge clk);
    push = 1'b1;
    pop = 1'b0;
    
    // stack the operations;  
    for(int i = 0; i < (total_addr_num + 10); i++) begin
        @(negedge clk);
        pop = 1'b1;
        push = 1'b1;
        #5 $display("time: %0t, index: %0d, push_addr: %0d, pop_addr: %0d, flag_overflow: %0d, flag_underflow: %0d, stack curr size: %0d",
                     $time, i, push_addr, pop_addr, flag_overflow, flag_underflow, stack_curr_size);

    end

        
    
    $stop;
    end
    
    
    
endmodule
