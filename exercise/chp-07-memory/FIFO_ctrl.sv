`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 22:49:22
// Design Name: 
// Module Name: FIFO_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      1. fifo controller;
// Acknowledgement;
//      1. this is adapted from the book referenced below;
//      2. book: "FPGA Prototyping by SystemVerilog Examples"
//      3. author: Pong P. Chu
//      4. code listing:  7.7
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO_ctrl
    #(parameter ADDR_WIDTH = 4) // total number of address = 2^{4};
    (
    input logic clk,                        // 100MHz;
    input logic reset,                      // async reset;
    input logic ctrl_rd, ctrl_wr,           // control signal fo read and write;
    output logic flag_empty, flag_full,     // flag signals: empty/full fifo;
    output logic [ADDR_WIDTH-1:0] wr_addr,  // write address; pointing at the next available FIFO space;
    output logic [ADDR_WIDTH-1:0] rd_addr  // read address; pointing at the top non-empty content;
    );
    
    // signal;
    logic  [ADDR_WIDTH-1:0] wr_ptr_curr, wr_ptr_next;   // write pointer;
    logic  [ADDR_WIDTH-1:0] rd_ptr_curr, rd_ptr_next;   // read pointer;
    logic full_curr, full_next; // flag for full fifo;
    logic empty_curr, empty_next; // flag for empty fifo;
    
    // reg;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                wr_ptr_curr <= 0;
                rd_ptr_curr <= 0;
                full_curr <= 1'b0;
                empty_curr <= 1'b1;
            end
        else
            begin
                wr_ptr_curr <= wr_ptr_next ;
                rd_ptr_curr <= rd_ptr_next ;
                full_curr <= full_next ;
                empty_curr <= empty_next;
            end
    
    // fsm;
    always_comb 
    begin
        // default;
        wr_ptr_next = wr_ptr_curr;
        rd_ptr_next = rd_ptr_curr;
        full_next = full_curr;
        empty_next = empty_curr;
        
        // start the machinery;
        unique case({ctrl_wr, ctrl_rd})
            // read only;
            2'b01: begin
                if(~empty_curr) begin 
                        // advance to the next non-empty content;
                        rd_ptr_next  = rd_ptr_curr + 1; 
                        full_next = 1'b0;   // no longer hold after a read;
                        
                        // to detrmine whether the next fifo state is empty;
                        // if the next read pointer coincides with the current
                        // write pointer; then it must be empty;
                        if(rd_ptr_next == wr_ptr_curr)
                            empty_next = 1'b1;
                    end
            end
            
            // write only;
            2'b10: begin
                if(~full_curr) begin
                    // advance the write pointer to next available slot;
                    wr_ptr_next = wr_ptr_curr + 1;
                    empty_next = 1'b0;  // no longer hold after a write;
                    
                    // to determine whether the next fifo state is full'
                    // if the next write pointer coincides with 
                    // the current read pointer, then it must be full;
                    if(wr_ptr_next == rd_ptr_curr)
                        full_next = 1'b1;
                end
            end
            
            // write and read;
           2'b11: begin
                // no need to worry about full or empty;
                // compensated by each other action;
                wr_ptr_next  = wr_ptr_curr + 1;
                rd_ptr_next  = rd_ptr_curr + 1;
           end
           
           default : ;  // 2'b00; no operation
        endcase
    end
    
    // output logic;
    assign flag_full = full_curr;
    assign flag_empty = empty_curr;
    assign wr_addr = wr_ptr_curr;
    assign rd_addr = rd_ptr_curr;
endmodule
