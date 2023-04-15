`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 01:58:14
// Design Name: 
// Module Name: core_gpi
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: IO core, general purpose input for MCS; 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef _CORE_GPI_SV
`define _CORE_GPI_SV

`include "IO_map.svh"

module core_gpi
    /*
    * Purpose: General Purpose Input Core for MicroBlaze MCS IO Module (Core);
    * Construction:  input port will be sampled by the hw register;
    * 
    * Structure:
    *   1. core_gpi is primariliy for switches;
    *   2. by specs, each core is allocated 32 internal registers;
    *   3. each register is 32-bit wide;
    *   4. by above, sw does not need more than one register;
    *       also, the board does not have 32 switches;
    * 
    * Register Map:
    *   1. only one register is used to store the input; as explained above;
    *
    *
    * Extra Material on the Construction: 
    * https://www.intel.com/content/www/us/en/docs/programmable/683375/current/input-registers.html
    */
    #(parameter W = 8)  // input port width; 
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,                 // chip select; not needed?
        input logic write,              // not needed;
        input logic read,               // still contemplating whether to use this ...?
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         // only one is used;
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    // MCS uses 32-bit;
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,   // sampled din
        
        // the external signal at the input port to sample;
        input logic [W-1:0] din
    );
    
    // signal declaration;
    logic [W-1:0] rd_curr;  // to hold din; 
    always_ff @(posedge clk, posedge reset)
        if(reset)
            rd_curr <= 0;
        else
            rd_curr <= din;
   
   // output: only W bit wide;
   assign rd_data[W-1:0] = rd_curr; // sampled;
   assign rd_data[`REG_DATA_WIDTH_G-1:W] = 0;        // zero padded; physical input does not have signed concept;
endmodule

`endif // _CORE_GPI_SV