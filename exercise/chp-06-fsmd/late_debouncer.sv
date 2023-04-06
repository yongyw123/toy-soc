`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 14:27:10
// Design Name: 
// Module Name: late_debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:
//      1.  only set the debounced level after the input level stabilise for 40ms;
//      2. hence late debouncer;
//      3. this code is adapted from a code listing from the book referenced below;
// 
// Acknowledgment:
//      1. Book: "FPGA Prototyping by SystemVeriog Examples"
//      2. Author: Pong P. Chu
//      3. Code Listing: 6.1
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module late_debouncer
    #(parameter N = 22) // default counter bit width, 22 ==> 40ms with 100MHz clock;
    (
    input logic clk,            // 100MHz;
    input logic reset,          // async reset;
    input logic sw,             // input to debounce;
    output logic db_output,     // debounced;
    output logic debug_db_tick  // for debugging convenience;
    );
    
    /*
    * FSM state declaration;
    *   1. ST_ZERO, ST_ONE are states where the input level has been LOW
    *       or HIGH for indefinitely long;
    *   2. ST_WAIT_ZERO, ST_WAIT_ONE are the state to start the timer
    *       to filter out the glitches;
    */
    typedef enum {ST_ZERO, ST_WAIT_ZERO, ST_ONE, ST_WAIT_ONE} state_type;
    
    /* default;
    * timer/counter;
    * clk is 10ns;
    * required to filter for 40ms;
    * 2^{N} * 10 ns = 40 ms ==> N = 22;
    */
    //localparam N = 22;
    
    // signal declaration;
    state_type  state_curr, state_next;
    logic [N-1:0] q_curr, q_next;   // register for the counter;
    logic q_zero;           // flag when counter reaches zero;
    logic q_load;           // flag to reload the counter;
    logic q_decrement;      // flag to the counter to decrement;
    
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                q_curr <= 0;
                state_curr <= ST_ZERO;
            end
        else
            begin
                q_curr <= q_next;
                state_curr <= state_next;
            end
        
    // counter next state logic;
    assign q_next = (q_load) ? {N{1'b1}} :      // reset the counter;
                    (q_decrement) ?   q_curr  - 1: q_curr;   // decrement?
                    
    assign q_zero = (q_next == 0);
    
    // FSM logic;
    always_comb 
    begin
        // default;
        state_next = state_curr;
        q_load = 1'b0; 
        q_decrement = 1'b0;
        db_output  = 1'b0;
        debug_db_tick = 1'b0;
        
        // start the state trasnition;  
        case(state_curr)
            // state: input has been LOW for indefinitely long;
            ST_ZERO : begin
                // detect HIGH from LOW;
                if(sw) begin
                    state_next = ST_WAIT_ONE;  
                    q_load = 1'b1;      // load the counter;         
                end
               // else case has been covered in the default above;
               // i.e. if LOW, then remain as it is;
            end
            
            // state: wait for the input to be at HIGH for N times;
            // to be considered as valid LOW to HIGH input;
            ST_WAIT_ONE : begin
                // ensure the input remains HIGH;
                if(sw) begin
                    // decrement the timer;
                    q_decrement  = 1'b1;
                    
                    // continue counting until timer expires;
                    if(q_zero) begin
                        // input does not change after N time;
                        // considered stabilized;
                        state_next = ST_ONE ;   
                        debug_db_tick  = 1'b1;  // flag it
                    end
                // input changes before timer expires;                      
                end
                else begin
                    state_next  = ST_ZERO ;
                end
            end
            // state: input has been HIGH for indefinitely long;
            ST_ONE: begin
                // output debounce level;
                db_output  = 1'b1;
                // the input changes from HIGH to LOW;
                // otherwise, remain as it is;
                if(~sw) begin
                    state_next  = ST_WAIT_ZERO; 
                    q_load = 1'b1;      // reset the counter;
                end
            end
            // state: wait for the input to be at LOW for N times;
            // to be considered as valid HIGG to LOW input;
            ST_WAIT_ZERO : begin
                // output remains HIGH until considered otherwise;
                db_output  = 1'b1;
                  
                if(~sw) begin
                    q_decrement  = 1'b1;
                    if(q_zero) begin
                        state_next = ST_ZERO;
                    end
                end
                // not stable LOW, it is a glitch;
                else begin
                    state_next  = ST_ONE;
                end            
            end
            default: state_next = ST_ZERO;
        endcase 
    end
endmodule
