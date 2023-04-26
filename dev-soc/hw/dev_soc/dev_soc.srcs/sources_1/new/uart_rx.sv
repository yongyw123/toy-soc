`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.04.2023 16:09:05
// Design Name: 
// Module Name: uart_rx
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


module uart_rx
    #(parameter
        // number of data bits from rx;
        DATA_BIT = 8,   
        // number of oversampling ticks for stop bits; (16 ticks means one stop bit;)
        SAMPLING_STOP_BIT = 16   
     )
    (
        /* general */
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        /* specific argument */
        input logic rx,     // uart rx data to process;
        input logic baud_rate_tick, // oversampling tick inidication by the baud rate gen;
        output logic rx_complete_tick,  // finish processing a complete rx data;
        output logic [DATA_BIT-1:0] dout    // reassembled uart rx data;
    );
    
    
    /* fsm state;
    *   IDLE_ST:  self-explanatory;
    *   START_ST: start bit detected;
    *   DATA_ST: move on from start bit to actual data bits;
    *   STOP_ST: finish processing all data bits; move on to process stop bits; 
    */
    typedef enum {IDLE_ST, START_ST, DATA_ST, STOP_ST} state_type;
    
    /* constants */
    localparam OVERSAMPLING_NUM = 16;   // max number of oversampling tick;
    localparam OVERSAMPLING_BIT_WIDTH = $clog2(OVERSAMPLING_NUM);
    localparam DATA_BIT_WIDTH = $clog2(DATA_BIT);
    
     // this is the standard; 
     // start bit requires half of the 16 sampling;
     // so that the next data bit will be sampled at its middle (by 16-ticks interval);
    localparam START_BIT_SAMPLING_THRESHOLD = 7;    // 8-1;      
    localparam DATA_BIT_SAMPLING_THRESHOLD = 15;    // 16-1
    
    /* signal; */
    state_type state_reg, state_next;
    
    // number of data bits that has been processed;
    logic [DATA_BIT_WIDTH-1:0] ndata_reg, ndata_next;
    
    // number of oversampling tick signals from the baud rate generator;
    logic [OVERSAMPLING_BIT_WIDTH-1:0] nsample_reg, nsample_next;
    
    // serial to parallel shift out the rx data for output;
    logic [DATA_BIT-1:0] shift_out_reg, shift_out_next;
    
    
    /* double FF synchronizer for the rx signal since this is asynchr 
    to reduce metastability prob; */
    logic rx_meta_reg;
    logic rx_stable_reg;
    
    always_ff @(posedge clk, posedge reset)
        if(reset)
            rx_meta_reg <= 0;
        else
            rx_meta_reg <= rx;
    
    always_ff @(posedge clk, posedge reset)
        if(reset)
            rx_stable_reg <= 0;
        else
            rx_stable_reg <= rx_meta_reg;
         
    
    // fsmd;
    always_ff @(posedge clk, posedge reset)
        if(reset) 
            begin
                state_reg <= IDLE_ST;
                ndata_reg <= 0;
                nsample_reg <= 0;
                shift_out_reg <= 0;
            end
        else 
            begin
                state_reg <= state_next;
                ndata_reg <= ndata_next;
                nsample_reg <= nsample_next;
                shift_out_reg <= shift_out_next;
            end
         
    // fsm;
    always_comb 
    begin
        // important default; remain as it is until told otherwise;
        state_next = state_reg;
        ndata_next = ndata_reg;
        nsample_next = nsample_reg;
        shift_out_next = shift_out_reg;
        rx_complete_tick = 1'b0;        // not done yet;
        
        // start the machinery;
        case(state_reg)
            IDLE_ST:
                begin
                    // start bit detected;
                    if(~rx_stable_reg) begin
                        state_next = START_ST;
                        // reload the sampling couner;
                        nsample_next = 0;
                    end 
                end
            START_ST:
                begin
                    // wait for the oversampling tick from the baud rate gen
                    // by standard, only need to process half of the 16 ticks;
                    // so that the next data bit will be sampled at its middle;
                    if(baud_rate_tick) begin
                        // reach the threshold; start processing the data bit;
                        if(nsample_reg == START_BIT_SAMPLING_THRESHOLD) begin
                            state_next = DATA_ST;
                            // reload the relevant counter;
                            nsample_next = 0;   // reset to count for the data section;
                            ndata_next = 0;
                        end
                        else begin
                            // keep counting the ticks if threshold has not been met;
                            nsample_next = nsample_reg + 1;
                        end
                    end
                end
            DATA_ST:
                begin
                    // similar to how start bit is processed;
                    // except for the number of sampling ticks is different;
                    // and requires the counting of the number of data bits;
                    // and requires shift the data;
                    if(baud_rate_tick) begin 
                        if(nsample_reg == DATA_BIT_SAMPLING_THRESHOLD) begin
                            // one data bit is done;
                            // reset the counter for the next data;
                            nsample_next = 0;
                            
                            // shift in the current processed data for output;
                            shift_out_next = {rx_stable_reg, shift_out_reg[DATA_BIT-1:1]};
                            
                            // check if all data bits have been processed;
                            // if so, go to stop;
                            if(ndata_reg == DATA_BIT - 1) begin
                                state_next = STOP_ST;
                            end
                            else begin
                                ndata_next = ndata_reg + 1;
                            end
                        end
                        else begin
                            nsample_next = nsample_reg + 1;
                        end                        
                    end
                end
            STOP_ST:
                begin
                    // similar to the above;
                    // count the number of stop bits based on the sampling tick;
                    if(baud_rate_tick) begin
                        if(nsample_reg == (SAMPLING_STOP_BIT - 1)) begin
                            // done;
                            state_next = IDLE_ST; 
                            rx_complete_tick = 1'b1;
                        end
                        else begin
                            nsample_next = nsample_reg + 1;
                        end
                    end
                end
            default: ; // nop;
        endcase
    end
    
    // output;
    assign dout = shift_out_reg;   
    
endmodule
