`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2023 21:15:57
// Design Name: 
// Module Name: pixel_Y2RGB565_pass_v2
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


module pixel_Y2RGB565_pass_v2(
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
    logic cnt_in_reg, cnt_in_next;    
    logic [15:0] pixel_in_reg;  // to register the pixel from the upstream to process;
    logic read_in;
    
    // fsm states;
    typedef  enum {ST_IN_FIRST, ST_OUT_FIRST, ST_OUT_SECOND} state_type;
    state_type state_reg, state_next;
    
    // ff;
    always_ff @(posedge clk_sys, posedge reset) begin
        if(reset) begin
            cnt_in_reg <= 1'b0;            
            state_reg <= ST_IN_FIRST;
            pixel_in_reg <= 0;
           
        end
        else begin
            cnt_in_reg <= cnt_in_next;                  
            state_reg <= state_next;
            if(src_ready)
                pixel_in_reg <= converted_rgb565_in;
        end
    end
    
    
    // fsm
    always_comb begin
        // default;
        state_next = state_reg;
        cnt_in_next = cnt_in_reg;
        
        read_in = 1'b0;
        src_ready = 1'b0;
        sink_valid = 1'b0;
        
        rgb565_out = pixel_in_reg[7:0];
        
        // start the machinery;
        case(state_reg)
            ST_IN_FIRST: begin
                // first byte? contains Y component; 
                // read it;
                if(cnt_in_reg == 1'b0) begin
                    if(src_valid) begin
                        // read from the upstream fifo;
                        src_ready = 1'b1;
                        // valid data to process;
                        read_in = 1'b1;
                        cnt_in_next = cnt_in_reg + 1;
                        state_next = ST_OUT_FIRST;
                    end
                end
                
                // second byte;
                // ignored but remove it from the upstream fifo by reading it;                
                else begin
                    if(src_valid) begin
                        // read from the upstream fifo;
                        src_ready = 1'b1;
                        cnt_in_next = cnt_in_reg + 1;
                    end
                
                end                   
            end
            
            ST_OUT_FIRST: begin
                if(sink_ready) begin
                    // write it to the downstream fifo;
                    sink_valid = 1'b1;    
                    // shift next;                    
                    rgb565_out = pixel_in_reg[7:0];
                    state_next = ST_OUT_SECOND;
                end
            end
            
            ST_OUT_SECOND: begin
                if(sink_ready) begin
                    // write it to the downstream fifo;
                    sink_valid  = 1'b1;
                    // shift in;
                    rgb565_out = pixel_in_reg[15:8];
                    // done                    
                    state_next = ST_IN_FIRST;
                    
                end                
            end
                     
            default: ; // nop
        endcase
    end
        
    
endmodule

