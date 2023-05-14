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
        cnt_in_next = cnt_in_reg;
        
        src_ready = 1'b0;
        sink_valid = 1'b0;
        
        rgb565_out = unpacked_reg;
        
        case(state_reg)
            // the input pixel represents first byte of the 16-bit pixel from the camera;
            // no Y component; ignored;
            ST_FIRST_IGNORE: begin
                src_ready = 1'b1;
                sink_valid = 1'b0;
                // seoncd "byte" fron the camera;
                if(cnt_in_reg == 2'b10) begin
                    state_next = ST_OUT_FIRST;
                    // start shifting for the output;
                    unpacked_next = converted_rgb565_in[7:0];
                    // reset;
                    cnt_in_next = 0;                        
                end
                else begin
                    // only increment when we manage to read a data from the source;
                    if(src_valid && src_ready) 
                        cnt_in_next = cnt_in_reg + 1;
                end
            end
            /*
                ST_OUT_FIRST, ST_OUT_SECOND;    
                unpacked the 16-bit converted rgb565 from Y into two 8-bits;
             */
             
            ST_OUT_FIRST: begin
                if(sink_ready) begin
                    sink_valid = 1'b1;                    
                    unpacked_next = converted_rgb565_in[15:8];
                    state_next = ST_OUT_SECOND;
                end
            end
            ST_OUT_SECOND: begin
                if(sink_ready) begin
                    sink_valid  = 1'b1;                    
                    state_next = ST_FIRST_IGNORE;
                end                
            end
            
            default: ; // nop        
        endcase
    end  
        
    
endmodule
