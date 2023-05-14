`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2023 16:09:28
// Design Name: 
// Module Name: pixel_Y2RGB565_pass
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

/*
purpose: to massage the converted Y-to-RGB565 for lcd display
*/

module pixel_Y2RGB565_pass
    (
        // general;
        input logic clk_sys,    // 100Mhz;
        input logic reset,      // async;
        
        // interface with the upper stream;
        input logic src_valid,
        output logic src_ready,
        
        // interface with the upper conversion block;
        input logic [15:0] converted_rgb565_in,
        
        // interface with the down stream;
        input logic sink_ready,
        output logic sink_valid,
        output logic [7:0] rgb565_out        
    );
    
    // constants;
    localparam MOD_THRESHOLD = 2'b10;   // when should the bit counter wrap around;
    
    // signal declaration;
    logic [1:0] cnt_in_reg, cnt_in_next;    
    logic [7:0] unpacked_reg, unpacked_next;
    
    // fsm states;
    typedef  enum {ST_FIRST_IGNORE, ST_OUT_FIRST, ST_OUT_SECOND} state_type;
    state_type state_reg, state_next;
    
    // ff;
    always_ff @(posedge clk_sys, posedge reset) begin
        if(reset) begin
            cnt_in_reg <= 0;            
            state_reg <= ST_FIRST_IGNORE;
            unpacked_reg <= 0;
        end
        else begin
            cnt_in_reg <= cnt_in_next;                  
            state_reg <= state_next;
            unpacked_reg <= unpacked_next;
        end
    end
 
    // fsm;
    always_comb begin
        // default;
        state_next = state_reg;
        unpacked_next = unpacked_reg;
        
        src_ready = 1'b0;
        sink_valid = 1'b0;
        
        rgb565_out = unpacked_reg;
        
        case(state_reg)
            ST_FIRST_IGNORE: begin
                src_ready = 1'b1;
                sink_valid = 1'b0;
                if(cnt_in_reg == 2'b01) begin
                    state_next = ST_OUT_FIRST;
                    unpacked_next = converted_rgb565_in[7:0];                    
                end
            end
            
            ST_OUT_FIRST: begin
                src_ready = 1'b0;
                if(sink_ready) begin
                    sink_valid = 1'b1;                    
                    unpacked_next = converted_rgb565_in[15:8];
                    state_next = ST_OUT_SECOND;
                end
            end
            ST_OUT_SECOND: begin
                src_ready = 1'b0;
                if(sink_ready) begin
                    sink_valid  = 1'b0;                    
                    state_next = ST_FIRST_IGNORE;
                end                
            end
            
            default: ; // nop        
        endcase
    end
    
    // next state for the pixel input counter;    
    assign cnt_in_next = (cnt_in_reg == MOD_THRESHOLD) ? 0 : cnt_in_reg + 1;
        
    
endmodule
