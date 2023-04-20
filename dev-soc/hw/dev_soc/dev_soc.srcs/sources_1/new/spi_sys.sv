`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 01:08:28
// Design Name: 
// Module Name: spi_sys
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Serial Peripheral Interface Circuit 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


/* ---- Construction;

Background:
1. this module is created based on the following HW signals;
2. other SPI signals such as chip select, Data-or-command are emulated on the software end;

Necessary HW Signals:
1. SCL; clock to drive both master and slave;
2. MOSI: master out slave in
3. MISO: master in slave out;

SPI other Control: 
1. CPOL; clock polarity
2. CPHA: clock phase;

Important Idea (FSDM main states):
1. Sampling (reading slave) and Shifting (writing to slave) are always
conducted in the same clock period BUT on the different edge of the clock;
depending on CPOL and CPHA;
(Reference: https://onlinedocs.microchip.com/pr/GUID-835917AF-E521-4046-AD59-DCB458EB8466-en-US-1/index.html?GUID-E4682943-46B9-4A20-A62C-33E8FD3343A3)

2. By above, the FSMD has two main States:
    State A: is where the sampling occurs (happening on the first half of the SPI clock period);
    State B: is where the shifting occurs (happening on the second half of the SPI clock period);
3. Other states are there depending on the combination of {CPHA, CPOL};
    
SPI Clock Construction:
1. The clock, although is derived by the system clock; is implicitly
    based on the state of the FSDM, as discussed above;
2. By the Idea above, we spend the first half of the clock period in State A;
    and the second half in State B;
3. So, the change in the clock is driven by the current states as above;
4. We divide system clock to obtain the SPI clock, formulated as follows:

Formula: Either State (A/B) should stay for this many counts: (sys_clock/(2*spi_clock)-1)

Assumption:
1. Data bit is always in 8-bit;
2. MOSI is always in MSB order;
3. Other signals, as discussed above could be emulated in SW;
*/

module spi_sys
    #(parameter 
    // this is usually fixed;
    DATA_BIT = 8,   
    // to determine the SPI counter width, this is variable;
    // not sure what is the minimum SPI clock supported since
    // this depends on the slave as well ...
    MAX_SPI_CLOCK_WIDTH = 16   
    )
    (
    /* general; */
    input logic clk,        // 100 MHz;
    input logic reset,      // async;
    
    /* mosi arguments; */
    input logic [DATA_BIT-1:0] mosi_data_write,   // data to send to the slave;
    
    /* user control inputs and spi clock setting; */
    input logic [MAX_SPI_CLOCK_WIDTH-1:0] count_mod, // counter threshold for spi clock as discussed above;
    input logic cpol,
    input logic cpha,
    input logic start,        // start spi transaction;
    
    /*  miso arguments; */
    // assembled data from the slave after one SPI transaction is complete
    output logic [DATA_BIT-1:0] miso_assembled_data, 
    
    /* status */
    output logic spi_complete_flag, // spi transcation is done;
    output logic spi_ready_flag,   // spi is idle, available for new transaction;
    
    /* actual SPI pins drive */
    output logic sclk,  // spi clock;
    input logic miso,   // slave input bit to sample;
    output logic mosi   // master output bit to shift out (write0;
    );
    
    // number 8 only needs three bits ti represent;
    localparam DATA_BIT_LOG = $clog2(DATA_BIT); 
    
    // state;
    // as discussed in the comment note above.
    // ST_FHALF is where the MISO sampling occurs (the first half of the SPI clock period);
    // ST_SHALF (second half) is where the MOSI write occurs;
    typedef enum{ST_IDLE, ST_FHALF, ST_SHALF} state_type;
    state_type state_reg, state_next;
    
    // as discussed above;
    // the SPI clock could be generated depending where the current FSMD state is;
    // so this pclk is either HIGH or LOW depending on the state;
    // but because we also have to consider cpol and cpha;
    // pclk serves as temporary variable; maybe inverted depdning on the cpol etc. 
    logic pclk; // temporary clock
    logic spi_clk_reg, spi_clk_next;    // to hold pclk;
    
    // registers for tracking and counting;
    logic[MAX_SPI_CLOCK_WIDTH-1:0] clk_cnt_reg, clk_cnt_next; // for spi counter mod;
    logic[DATA_BIT_LOG-1:0] data_cnt_reg, data_cnt_next; // spi data bits;
    logic[DATA_BIT-1:0] miso_reg, miso_next;    // to hold miso input for reassembling;
    logic[DATA_BIT-1:0] mosi_reg, mosi_next;    // to hold mosi output for shifting;
    
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset)
        begin
            state_reg <= ST_IDLE;
            clk_cnt_reg <= 0;
            spi_clk_reg <= 0;
            data_cnt_reg <= 0;
            miso_reg <= 0;
            mosi_reg <= 0;        
        end
        else
        begin
            state_reg <= state_next;
            clk_cnt_reg <= clk_cnt_next;
            spi_clk_reg <= spi_clk_next;
            data_cnt_reg <= data_cnt_next;
            miso_reg <= miso_next;
            mosi_reg <= mosi_next;
        end    
    
    // fsm;
    always_comb
    begin
        // remain as it is until told otherwise;
        state_next = state_reg;
        clk_cnt_next = clk_cnt_reg;
        data_cnt_next = data_cnt_reg;
        miso_next = miso_reg;
        mosi_next = mosi_reg;
        
        spi_ready_flag = 1'b0;   // not ready except in idle state;
        spi_complete_flag = 1'b0;  // not ready until told otherwise;
        
        case(state_reg)
            ST_IDLE: 
            begin
                spi_ready_flag = 1'b1;
                if(start)
                begin
                    state_next = ST_FHALF;
                    mosi_next = mosi_data_write;
                    // start the clk count;
                    clk_cnt_next = 0;
                    // shoudl start counting the data;
                    data_cnt_next = 0;
               end
                
            end
            
           
            ST_FHALF:
            begin
                // first half of the spi clock has elapsed;
                if(clk_cnt_reg == count_mod) 
                begin
                    // sample the miso data by shifting in at LSB;
                    miso_next = {miso_reg[DATA_BIT-2:0], miso};
                    // first half is done; second half;
                    state_next = ST_SHALF;
                    // reset the counters;
                    clk_cnt_next = 0;
                      
                   /* important: do not reset the data counter here;
                   because one complete data-bit is "processed in a single
                   spi clock period: first half and second half 
                   
                   DO NOT DO THIS HERE; otherwise 
                   this FSM will forever loop between ST_FHALF and
                   ST_SHALF;
                   // data_cnt_next = 0;
                   */
                end
                else 
                begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            
            ST_SHALF:
            begin
                // second half of the spi clock has elapsed;
                if(clk_cnt_reg == count_mod) 
                begin
                    // all data bits have been transmitted?
                    // spi transaction is complete then;
                    if(data_cnt_reg == (DATA_BIT-1))
                    begin
                        state_next = ST_IDLE;
                        spi_complete_flag = 1'b1;
                    end
                    else
                    begin
                        // shift for the next mosi bit;
                        mosi_next = {mosi_reg[DATA_BIT-2:0], 1'b0};
                        // one bit is done; back to next bit transaction;
                        state_next = ST_FHALF;
                        data_cnt_next = data_cnt_reg + 1;
                        // reset the clk;
                        clk_cnt_next = 0;
                    end
                end
                else 
                begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
        endcase
    end
    /* spi clock generator;
    // reference: https://onlinedocs.microchip.com/pr/GUID-835917AF-E521-4046-AD59-DCB458EB8466-en-US-1/index.html?GUID-E4682943-46B9-4A20-A62C-33E8FD3343A3
    example;
    suppose cpha is 0 and cpol is 0;
    the MISO sampling should happen on the first LOW-to-HIGH spi clock transition;
    
    because the sampling has to happen on the clock transition;
    we need to look ahead;
    hence state_next rather state_reg is used;
    */
    assign pclk = (state_next == ST_SHALF && ~cpha) || (state_next == ST_FHALF && cpha);
    
    // cpol just inverts the polority;
    assign spi_clk_next = (cpol)? ~pclk : pclk;
    
    // output;
    assign mosi = mosi_reg[DATA_BIT-1]; // shift the MSB by the assumption;
    assign miso_assembled_data = miso_reg;
    assign sclk = spi_clk_reg;
    
endmodule
