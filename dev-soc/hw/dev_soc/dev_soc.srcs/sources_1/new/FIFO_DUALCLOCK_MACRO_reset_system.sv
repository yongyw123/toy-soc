`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 19:20:07
// Design Name: 
// Module Name: FIFO_DUALCLOCK_MACRO_reset_system
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
Purpose: this is a reset system for FIFO_DUALCLOCK_MACRO;
Why? This macro has various conditions to satisfy in order to use; See below;
Construction: 
    1. this is a FSM;
    2. it uses the system_reset to create the reset for FIFO;
    3. instead of keeping track for write and read requirements separately;
    4. we shall use whichever side that has a slower clock;
    
    
Assumption:
1. this module shall only ensure the clock cycles are satisfied;
2. it does NOT assume other signals such as RDEN adn WREN;
3. these other signals shall be handled by other modules that generate them;

Condition: 
    A reset synchronizer circuit has been introduced to 7 series FPGAs. RST must be asserted
    for five cycles to reset all read and write address counters and initialize flags after
    power-up. RST does not clear the memory, nor does it clear the output register. When RST
    is asserted High, EMPTY and ALMOSTEMPTY are set to 1, FULL and ALMOSTFULL are
    reset to 0. The RST signal must be High for at least five read clock and write clock cycles to
    ensure all internal states are reset to correct values. During Reset, both RDEN and WREN
    must be deasserted (held Low).
    
        Summary: 
            // read;
            1. RESET must be asserted for at least five read clock cycles;
            2. RDEN must be low before RESET is active HIGH;
            3. RDEN must remain low during this reset cycle
            4. RDEN must be low for at least two RDCLK clock cycles after RST deasserted
            
            // write;
            1. RST must be held high for at least five WRCLK clock cycles,
            2. WREN must be low before RST becomes active high, 
            3. WREN remains low during this reset cycle.
            4. WREN must be low for at least two WRCLK clock cycles after RST deasserted;
    
Reference: "7 Series FPGAs Memory Resources User Guide (UG473);
*/

module FIFO_DUALCLOCK_MACRO_reset_system
    (
        
        input logic clk_sys,    // 100MHz;
        input logic reset_sys,  // system reset; async;        
        
        input logic slower_clk, // in time unit: max(wr_clk, rd_clk);
                
        // output;
        output logic RST_FIFO,       // the reset signal for FIFO;
        output logic FIFO_rst_ready, // status;
        
        // debugging;
        output logic debug_detected_rst_sys_falling,
        output logic debug_detected_slow_clk_rising
    );
    
    /* constants; */
    localparam CNT_WIDTH = 4;   // for the counter; 4-bit is more than enough;
    
    // instead of 5 wr/rd clk cycles during HIGH RST; add some buffer;
    localparam TARGET_HIGH = 10;    
    
    // instead of 2 wr/rd clk cycles after RST goes LOW; add some buffer;
    localparam TARGET_LOW = 2;    
    
    /* signals */
    logic detected_rst_sys_falling; // to detect the falling edge of the system reset;
    logic detected_slow_clk_rising; // to detect the rising edge of the slower clock;
    
    assign debug_detected_rst_sys_falling = detected_rst_sys_falling;
    assign debug_detected_slow_clk_rising = detected_slow_clk_rising;
    
    /* state
    ST_IDLE             : wait for the system reset to go LOW from HIGH;                 
    ST_CHECK_RST_HIGH   : count the clock cycle requirement during HIGH RST;
    ST_CHECK_RST_LOW    : count the clock cycle requirement after RST goes LOW;
    ST_DONE             : for flagging; 
    */
    
    typedef enum {ST_IDLE, ST_CHECK_RST_HIGH, ST_CHECK_RST_LOW} state_type;
            
    state_type state_reg, state_next;
        
    // registers;
    logic [CNT_WIDTH-1:0] count_high_reg, count_high_next;
    logic [CNT_WIDTH-1:0] count_low_reg, count_low_next; 
    logic reset_fifo_reg, reset_fifo_next;  // to filter out glitches;
    logic ready_reg, ready_next;    // to filer out the status flag glitch;
    
    // ff;
    always_ff @(posedge clk_sys, posedge reset_sys) begin
        if(reset_sys) begin
            state_reg       <= ST_IDLE;
            count_high_reg  <= 0;
            count_low_reg   <= 0;
            reset_fifo_reg  <= 1'b1;
            ready_reg       <= 1'b0;
        end
        else begin
            state_reg       <= state_next;
            count_high_reg  <= count_high_next;
            count_low_reg   <= count_low_next;
            reset_fifo_reg  <= reset_fifo_next;
            ready_reg       <= ready_next;
        end
    end
    
    /* ------------- helper units */
    // to detect the falling edge of the system reset signal;
    /*
    rising_edge_detector
    edge_detector_reset_unit
    (
        .clk(clk_sys),
        .reset(reset_sys),
        .level(!(reset_sys)),
        .detected(detected_rst_sys_falling)
    );
    
    */
    assign detected_rst_sys_falling = 1'b0;
    
    // helper unit to detect the slower clk; use a rising/falling edge detector;
    rising_edge_detector
    edge_detector_clk_unit
    (
        .clk(clk_sys),
        .reset(reset_sys),
        .level(slower_clk),
        .detected(detected_slow_clk_rising)
    );
    
    // outputs;
    assign RST_FIFO = reset_fifo_reg;
    assign FIFO_rst_ready = ready_reg;
            
    // fsm;
    always_comb begin
        // default;
        state_next      = state_reg;
        count_high_next = count_high_reg;
        count_low_next  = count_low_reg;
        reset_fifo_next = reset_fifo_reg;
        ready_next      = ready_reg;
        
        case(state_reg) 
            ST_IDLE: begin
                reset_fifo_next = 1'b1;
                ready_next = 1'b0;
                
                if(detected_rst_sys_falling) begin
                    state_next = ST_CHECK_RST_HIGH;
                    // load the counter;
                    count_high_next = 0;
                end
            end
        
            ST_CHECK_RST_HIGH: begin
                reset_fifo_next = 1'b1;
                ready_next = 1'b0;
                
                // satsfy the FIFO req?
                if(count_high_reg == TARGET_HIGH) begin
                    state_next = ST_CHECK_RST_LOW;
                    // load the counter;
                    count_low_next = 0;
                end
                else begin
                    // only increment if a change in the fifo clock is detected;
                    if(detected_slow_clk_rising) 
                        count_high_next = count_high_reg + 1;
                end
            end 
           
            ST_CHECK_RST_LOW: begin
                reset_fifo_next = 1'b0;
                /// satisfy the fifo req?
                if(count_low_reg == TARGET_LOW) begin
                    state_next = ST_IDLE;
                    ready_next = 1'b1;
                end 
                else begin
                    // only increment if a change in the fifo clock is detected;
                    if(detected_slow_clk_rising) 
                        count_low_next = count_low_reg + 1;
                end
            end 
         
            default: ;  // nop;
        endcase    
    end            
endmodule
