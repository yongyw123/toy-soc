`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2023 16:19:45
// Design Name: 
// Module Name: FIFO
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
Purpose: FIFO;
Construction: this is a wrapper of the FIFO controller module
            and a register file;
*/
module FIFO
    #(parameter
    DATA_WIDTH = 8,
    ADDR_WIDTH = 4  
    )
    (
        // general;
        input logic clk,    // 100MHz;
        input logic reset,  // async;
        
        // specific;
        input logic ctrl_rd,     // read request;
        input logic ctrl_wr,     // write request;
        output logic flag_empty, // fifo status;
        output logic flag_full,  // fifo status;
        // data;
        output logic [DATA_WIDTH-1:0] rd_data, 
        input logic [DATA_WIDTH-1:0] wr_data
    );
    
    // read address;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;
    
    // status;
    logic wr_en;
    logic full_status; 
   
   // only enable write if fifo is not full;
   assign wr_en = ctrl_wr & ~flag_full;
   
   // instantiation;
   FIFO_ctrl #(.ADDR_WIDTH(ADDR_WIDTH)) controller(.*);
   
   reg_file 
   #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
   register_file(.*);  
endmodule
