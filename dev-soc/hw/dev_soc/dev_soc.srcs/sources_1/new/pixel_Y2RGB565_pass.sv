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
    logic [15:0] pixel_in_reg;  // to register the pixel from the upstream to process;
    
    // fsm states;
    typedef  enum {ST_FIRST_IGNORE, ST_OUT_FIRST, ST_OUT_SECOND} state_type;
    state_type state_reg, state_next;
    
    // ff;
    always_ff @(posedge clk_sys, posedge reset) begin
        if(reset) begin
            cnt_in_reg <= 0;            
            state_reg <= ST_FIRST_IGNORE;
            pixel_in_reg <= 0;
           
        end
        else begin
            cnt_in_reg <= cnt_in_next;                  
            state_reg <= state_next;
            if(src_ready)
                pixel_in_reg <= converted_rgb565_in;
        end
    end
 
    // fsm;
    always_comb begin
        // default;
        state_next = state_reg;
        
        cnt_in_next = cnt_in_reg;
        
        src_ready = 1'b0;
        sink_valid = 1'b0;
        
        //rgb565_out = unpacked_reg;
        rgb565_out = pixel_in_reg[7:0];
        case(state_reg)
            // the input pixel represents first byte of the 16-bit pixel from the camera;
            // no Y component; ignored;
            ST_FIRST_IGNORE: begin
                sink_valid = 1'b0;        
                // only when the upstream and downstream are ok;       
                if(sink_ready && src_valid) begin
                    src_ready = 1'b1; 
                    cnt_in_next = cnt_in_reg + 1;
                end
                //src_ready = sink_ready;                
                // seoncd "byte" fron the camera;
                if(cnt_in_reg == 2'b10) begin
                    src_ready = 1'b0;
                    state_next = ST_OUT_FIRST;
                    // reset;
                    cnt_in_next = 0;                        
                end
                /*
                else begin
                    // only increment when upstream and downstream are OK;                    
                    //if(src_valid && sink_ready)
                    //if(src_valid && src_ready)
                    if(src_ready) 
                        cnt_in_next = cnt_in_reg + 1;
                end
                */
            end
            /*
                ST_OUT_FIRST, ST_OUT_SECOND;    
                unpacked the 16-bit converted rgb565 from Y into two 8-bits;
             */
             
            ST_OUT_FIRST: begin
                if(sink_ready) begin
                    sink_valid = 1'b1;    
                    // shift next;                    
                    rgb565_out = pixel_in_reg[7:0];
                    state_next = ST_OUT_SECOND;
                end
            end
            ST_OUT_SECOND: begin
                if(sink_ready) begin
                    sink_valid  = 1'b1;                    
                    state_next = ST_FIRST_IGNORE;
                    rgb565_out = pixel_in_reg[15:8];
                end                
            end
            
            default: ; // nop        
        endcase
    end  
        
    
endmodule
