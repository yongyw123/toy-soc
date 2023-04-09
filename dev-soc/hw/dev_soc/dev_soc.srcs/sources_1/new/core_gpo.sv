`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2023 23:59:51
// Design Name: 
// Module Name: core_gpo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: IO core, general purpose output for MCS; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef _CORE_GPO_SV
`define _CORE_GPO_SV

`include "IO_map.svh"

module core_gpo
    /*
    * Purpose: General Purpose Output Core for MicroBlaze MCS IO Module (Core);
    * Construction: Output data at the output port is maintained by a HW register;
    * 
    * Structure:
    *   1. core_gpo is primariliy serves for LED;
    *   2. by specs, each core is allocated 32 internal registers;
    *   3. by above, LED only needs only internal register;
    * 
    * Register Map:
    *   1. only one register is used to store the output data, as explained above;
    *
    * Extra Material on the Construction: 
    * https://www.intel.com/content/www/us/en/docs/programmable/683375/current/output-registers.html
    */
    #(parameter W = 8)  // primarily for led, the board does not have 32 leds;
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,     // chip select;
        input logic write,
        input logic read,   
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // external signals;
        output logic [W-1:0] dout
    );
    
    
    // signal declaration
    logic [W-1:0] data_curr;    // not all 32-bit is used;
    logic wr_en;
    
    // register;
    always_ff @(posedge clk, posedge reset)
        if(reset)
            data_curr <= 0;
        else
            if(wr_en)
                data_curr <= wr_data[W-1:0]; // not all 32-bit is used;
    
    //> decoding logic;
    assign wr_en = cs && write; // only write when both flags set;
    assign rd_data = 0;         // not used for output port;
    assign dout = data_curr;
endmodule

`endif // _CORE_GPO_SV;
