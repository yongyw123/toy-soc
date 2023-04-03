`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 21:59:32
// Design Name: 
// Module Name: programmable_sq_wave_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      1. this is execise 4.8.1 of the book reference below;
//      2. programmable squave wave generator;
//      3. control signal: two 4-bit signals, m and n in unsigned int;
//      4. where on is m*100ns and off is n*100 ns;
// Reference:
//      Pong P. Chu's book: "FPGA Prototyping by System Verilog Examples"
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module programmable_sq_wave_gen(
    input logic clk,        // 100MHz
    input logic reset,      // async reset;
    input logic [3:0] ctrl_on,    // control signal for ON;     // must be >= 1;
    input logic [3:0] ctrl_off,    // control signal for OFF;   // must be >= 1;
    output logic sq_wave,
    output logic debug_ns_tick,
    output logic debug_ns_count
    
    );
    
    // signal declaration;
    localparam UNIT_TICK = 10;                 // 10*10ns = 100ns uni
    //localparam N = $clog2(16*UNIT_TICK);    // #bits = max(4-bit)*UNIT_TICK
    localparam N = 16;
    
    logic [N-1:0] hundred_ns_curr;
    logic [N-1:0] hundred_ns_next;
    logic hundred_ns_tick;
    
    logic [N-1:0] high_curr;
    logic [N-1:0] high_next;
    logic high_tick;
        
    logic [N-1:0] low_curr;
    logic [N-1:0] low_next;
    logic low_tick;
    
    logic sw_high_curr;
    logic sw_high_next;
    
    // reg;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                hundred_ns_curr <= 0;
                low_curr <= 0;
                high_curr <= 0;
                sw_high_curr <= 0;
            end
        else
            begin
                hundred_ns_curr <= hundred_ns_next;
                low_curr <= low_next;
                high_curr <= high_next;
                sw_high_curr <= sw_high_next;
            end
    
    // next state logic;
    assign hundred_ns_next = (hundred_ns_curr == (UNIT_TICK - 1)) ? 0 : hundred_ns_curr + 1;
    assign hundred_ns_tick = (hundred_ns_curr == (UNIT_TICK - 1)) ? 1'b1: 1'b0;
    
    always_comb 
        begin
        //default;
        high_next = high_curr;
        low_next = low_curr;
        sw_high_next = sw_high_curr;
        if(hundred_ns_tick)
        begin
            // toggle to HIGH;
            if(sw_high_curr)    
                if(high_curr != (ctrl_on - 1))
                    high_next = high_curr + 1;
                else
                    begin
                        high_next = 0;          // reset;
                        sw_high_next = 1'b0;    // toggle;
                    end
            
            // toggle to LOW;
            else
               begin
                    if(low_curr != (ctrl_off - 1))
                        low_next = low_curr + 1; 
                    else
                        begin
                            low_next = 0;           // reset;
                            sw_high_next  = 1'b1;   // toggle;
                        end
               end
        end
    end
    
    // output logic;
    assign sq_wave = sw_high_curr;
    assign debug_ns_tick = hundred_ns_tick;
    assign debug_ns_count = hundred_ns_curr;
endmodule
