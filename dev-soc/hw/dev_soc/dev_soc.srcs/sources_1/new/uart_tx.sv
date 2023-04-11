`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2023 01:26:42
// Design Name: 
// Module Name: uart_tx
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
Purpose: UART transmitter;
Construction: 
1. similar to UART Rx;
2. it is driven by a baud rate generator which outputs oversampling ticks;
3. recall that uart uses oversampling mechanism;
4. each data to transmit must hold for 16 ticks;
*/
 

module uart_tx
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
        input logic tx_start,           // start tx;
        input logic [DATA_BIT-1:0] din, // input data to serialize out for tx;
        input logic baud_rate_tick,     // oversampling tick inidication by the baud rate gen;
        output logic tx_complete_tick,  // finish processing a complete rx data;
        output logic tx                 // serialized output;
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
    logic [DATA_BIT_WIDTH - 1:0] ndata_reg, ndata_next;
    
    // number of oversampling tick signals from the baud rate generator;
    logic [OVERSAMPLING_BIT_WIDTH-1:0] nsample_reg, nsample_next;
    
    // parallel to serial shift out the tx data;
    logic [DATA_BIT-1:0] shift_out_reg, shift_out_next;
    
    // actual bit to transmit;
    // to hold the LSB of shift_out_reg, next;
    logic tx_reg, tx_next;  
    
    // fsmd;
    always_ff @(posedge clk, posedge reset)
        if(reset) 
            begin
                state_reg <= IDLE_ST;
                ndata_reg <= 0;
                nsample_reg <= 0;
                shift_out_reg <= 0;
                
                // HIGH to indicate idle otherwise; start-bit starts with HIGH TO LOW;
                tx_reg <= 1'b1; 
            end
        else 
            begin
                state_reg <= state_next;
                ndata_reg <= ndata_next;
                nsample_reg <= nsample_next;
                shift_out_reg <= shift_out_next;
                tx_reg <= tx_next;
            end
         
    // fsm;
    always_comb
    begin
        // important default; remain as it is until told otherwise;
        state_next = state_reg;
        ndata_next = ndata_reg;
        nsample_next = nsample_reg;
        shift_out_next = shift_out_reg;
        tx_complete_tick = 1'b0;        // not done yet;
        tx_next = tx_reg;
        
        // start the machinery;
        case (state_reg)
            IDLE_ST: 
                begin
                    // make sure the tx line is HIGH to indicate idle line;
                    tx_next = 1'b1;
                    // wait for the tx request;
                    if(tx_start) 
                    begin
                        state_next = START_ST;
                        // reload the counter;
                        nsample_next = 0;
                        // load the parallel input;
                        shift_out_next = din;
                    end
                end
                
            START_ST:
                begin
                    // deassert the tx line to generate the start bit
                    tx_next = 1'b0;
                    // check if the tx bit has lasted for 16 sampling ticks?
                    if(baud_rate_tick) 
                    begin
                        if(nsample_reg == (OVERSAMPLING_NUM-1)) 
                        begin
                            state_next = DATA_ST;
                            // reload the relevant counters;
                            nsample_next = 0;
                            ndata_next = 0;
                        end
                        else
                        begin
                            nsample_next = nsample_reg + 1;
                        end
                    end   
                end
            
            DATA_ST:
                begin
                    // start shifting out the data;
                    tx_next = shift_out_reg[0]; // LSB always;
                    // same, each data must last for 16 ticksl
                    if(baud_rate_tick)
                    begin
                        if(nsample_reg == (OVERSAMPLING_NUM - 1))
                        begin
                            nsample_next = 0;
                            // shifting the next LSB for the next tx;
                            shift_out_next = shift_out_reg >> 1;
                            // check if all data bits have been transmitted;
                            if(ndata_reg == (DATA_BIT - 1))
                            begin                             
                                state_next = STOP_ST;
                            end
                            else
                            begin
                                ndata_next = ndata_reg + 1;
                            end
                        end
                        else
                        begin
                            nsample_next = nsample_reg + 1;
                        
                        end
                    end
                end
            
            STOP_ST:
                begin
                    // assert the stop bit;
                    tx_next = 1'b1;
                    // slightly different;
                    // the validity of the stop bit also depends
                    // on a different parameter: how many stop bits set?
                    if(baud_rate_tick)
                    begin
                        if(nsample_reg == (SAMPLING_STOP_BIT-1))
                        begin
                            state_next = IDLE_ST;
                            tx_complete_tick = 1'b1;
                        end
                        else
                        begin
                            nsample_next = nsample_reg + 1;
                        end
                    end
                end            
        endcase
    end    
    // output;
    assign tx = tx_reg;
    
endmodule
