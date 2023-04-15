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
    
    /* spi clock setting; */
    input logic [MAX_SPI_CLOCK_WIDTH-1:0] count_mod, // counter threshold for spi clock as discussed above;
    input logic cpol,
    input logic cpha,
    
    /*  miso arguments; */
    // assembled data from the slave after one SPI transaction is complete
    output logic [DATA_BIT-1:0] miso_assembled_data, 
    
    /* status */
    output logic spi_complete_flag, // spi transcation is done;
    output logic spi_ready,         // spi is idle, available for new transaction;
    
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
    
    
    // fsm;
    
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
