`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.04.2023 14:44:13
// Design Name: 
// Module Name: stack_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: stack (LIFO) structure controller
//      1. this is an exercise of the book referenced below;
//      2. book: "FPGA Prototyping by SystemVerilog Examples"
//      3. author: Pong P. Chu
//      4. exercise: 7.7.6
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stack_ctrl
    #(parameter ADDR_WIDTH = 4) // total number of addresses = 2^{N};
    (
        input logic clk,    // 100MHz;
        input logic reset,  // async reset;
        input logic pop, push,  // stack equiv of reading and writing;
        output logic flag_overflow, flag_underflow, // flags of the stack status;
        output logic [ADDR_WIDTH-1:0] pop_addr,     // address to pop;
        output logic [ADDR_WIDTH-1:0] push_addr,    // address to push
        output logic [ADDR_WIDTH-1:0] stack_curr_size  // stack current size;
    );
    
    /* Note;
    1. the stack memory is in ascending order;
    2. the bottom stack is 0x00;
    3. each push operation will grow the stack towards the max size;
    */
    
    
    /*  signal; */
    localparam STACK_MAX_SIZE = 2**4;
    localparam STACK_MIN_SIZE = ADDR_WIDTH'(1'b0);
    
    // pointer points to the next available (empty) slot;
    logic  [ADDR_WIDTH - 1:0] top_ptr_curr, top_ptr_next;   
    
    // reg for the over/undeflow flags;
    logic overflow_curr, overflow_next;
    logic underflow_curr, underflow_next;
    
       
    // reg;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                overflow_curr <= 1'b0;
                underflow_curr <= 1'b1; // after reset, the stack is empty;
                top_ptr_curr <= 0;      // after reset, the start address is the empty slot;
            end
        else
            begin
                overflow_curr <= overflow_next;
                underflow_curr <= underflow_next;
                top_ptr_curr <= top_ptr_next;
            end
    
    // fsm;
    always_comb
    begin
        // default??
        underflow_next = underflow_curr;
        overflow_next = overflow_curr;
        top_ptr_next = top_ptr_curr;
        
        unique case({push, pop})
            // pop only;
            2'b01 : begin
                    if(~underflow_curr) begin
                        top_ptr_next = top_ptr_curr - 1;    // free up one slot;
                        overflow_next = 1'b0;               // definitely not overflow now;
                        
                        // undeflow if the next free-up slot is already at the bottom;
                        if(top_ptr_next == STACK_MIN_SIZE) begin
                            underflow_next = 1'b1;
                        end
                    end
               end 
            
            // push only;
            2'b10 : begin
                    if(~overflow_curr) begin
                        top_ptr_next = top_ptr_curr + 1;    // one more slot occupied;
                        underflow_next = 1'b0;              // definitely not undeflow now;
                        
                        // overflow if the current 
                        if(top_ptr_curr == (STACK_MAX_SIZE - 1)) begin
                            overflow_next = 1'b1;
                        end 
                    end
            end
            
            // push and pop;
            2'b11 : begin
                // no change since it is offset by each other;
                top_ptr_next = top_ptr_curr;
            end
            
            default: ; // 2'b00; no pop no push => nop;
         
        endcase    
    end
    
    // output;
    assign flag_overflow = overflow_curr;
    assign flag_underflow = underflow_curr;  
    assign push_addr = (overflow_curr) ? (STACK_MAX_SIZE - 1) : top_ptr_curr;
    assign pop_addr = (underflow_curr) ? STACK_MIN_SIZE : (top_ptr_curr - 1);
    assign stack_curr_size = push_addr;
endmodule
