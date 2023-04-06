`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 22:51:25
// Design Name: 
// Module Name: reg_file
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Register File (default size: 4 x 8)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reg_file
    #(parameter DATA_WIDTH = 8, 
                ADDR_WIDTH = 2)
                
    (
        input logic clk,    // 100MHz
        input logic wr_en,  // synchronous write enable;
        input logic [ADDR_WIDTH-1:0] wr_addr,   // write address;
        input logic [ADDR_WIDTH-1:0] rd_addr,   // read addresses
        input logic [DATA_WIDTH-1:0] wr_data,   // write data;
        output logic [DATA_WIDTH-1:0] rd_data   // read data; 
    );
    
    // signals;
    localparam array_max_index = 2**ADDR_WIDTH -1;
    logic [DATA_WIDTH-1:0] array_reg [0:array_max_index];   // memory;
    
    always_ff  @(posedge clk) begin
        if(wr_en)
            array_reg[wr_addr] <= wr_data;
    end
    // read;
    assign rd_data = array_reg[rd_addr];
    
endmodule
