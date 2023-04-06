`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 16:36:47
// Design Name: 
// Module Name: early_debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      1. early detection debouncer;
//      2. when the input chanegs from zero to one, the FSM responds immediately;
//          and ignore the input for N ms to avoid glitches;
//      3. after this N ms, the FMS checks the inputs for the falling edge;
//      4. likewise when the input transits from one to zero;
//
// Note:
//      1. this is an exercise from the book reference below;
//      2. exercise: 6.5.1
//
// Reference Book:
//      1. Book: "FPGA Prototyping by SystemVerilog Examples"
//      2. Author: Pong P. Chu
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module early_debouncer
    #(parameter N = 22) // default counter bit width, 22 ==> 40 ms with 100Mhz clk;
    (
    input logic clk,             // 100MHz;
    input logic reset,              // async reset;
    input logic sw,              // input to debounce;
    output logic db_output,       // debounced output;
    output logic debug_db_tick  // for debugging;
    );
    
    /* FSM 
    * two states:
    *   1. ST_CHECK_CHANGE: check transition: low to high or high to low;
    *   2. ST_IGNORE: ignore glitches for N amount of time;
    */
    
    typedef enum {ST_CHECK_CHANGE, ST_IGNORE} state_type;
    
    // signal declaration;
    state_type  state_curr, state_next;
    logic [N-1:0] q_curr, q_next;   // register for the counter;
    logic q_zero;           // flag when counter reaches zero;
    logic q_load;           // flag to reload the counter;
    logic q_decrement;      // flag to the counter to decrement;
    
    logic sw_curr;
    logic sw_next;
         
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                q_curr <= 0;
                state_curr <= ST_CHECK_CHANGE ;
                sw_curr <= 0;
            end
        else
            begin
                q_curr <= q_next;
                state_curr <= state_next;
                sw_curr <= sw_next;
            end
        
    // counter next state logic;
    assign q_next = (q_load) ? {N{1'b1}} :      // reset the counter;
                    (q_decrement) ?   q_curr - 1: q_curr;   // decrement?
                    
    assign q_zero = (q_next == 0);
    
    // fsm;
    always_comb 
    begin
        // default;
        state_next = state_curr;
        sw_next = sw_curr;
        
        q_load = 1'b0; 
        q_decrement = 1'b0;
        debug_db_tick = 1'b0;
        
        // important; db should correspond to the current state of the sw;
        db_output  = sw_curr;   
        
        case(state_curr)        
            ST_CHECK_CHANGE : begin
                // detect a change;
                if(sw != sw_curr) begin
                    sw_next = sw;       // update the switch state;
                    db_output  = sw;    // instantaneous update the debug output; otherwise, it will be one clock delay;
                    q_load  = 1'b1; // reset the timer;
                    state_next = ST_IGNORE;
                end
                // else has been covered in the default above;
            end
        
            ST_IGNORE : begin
                // decrement the timer;
                q_decrement  = 1'b1;
                    
                // continue counting until timer expires;
                // ignore the input to avoid glitches;
                if(q_zero) begin
                    state_next = ST_CHECK_CHANGE;  // expired, check any change to the input;   
                    debug_db_tick  = 1'b1;  // flag it
                end
                // else has been convered in the default above;
            end
            default: state_next = ST_CHECK_CHANGE; 
       endcase
    end
    
    
    
endmodule
