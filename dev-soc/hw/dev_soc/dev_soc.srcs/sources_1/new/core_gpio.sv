`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2023 00:44:07
// Design Name: 
// Module Name: core_gpio
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: IO core, general purpose input output for MCS;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef CORE_GPIO_SV
`define CORE_GPIO_SV

`include "IO_map.svh"


module core_gpio
    /*
    * Purpose: General Purpose Input Output (Bidirectional) Core for MicroBlaze MCS IO Module (Core);
    * Construction: use tri-state data type, and the direction is controlled;
    * 
    * Register Map: this core has three registers;
    *       1. offset 0 - to store output data;
    *                       access - write only;
    *                    
    *       2. offset 1 - to store input data;
    *                       access - read only;
    *
    *       3. offset 2 - to control the (individual) direction of each bit;
    *                       access - read and write; 
    *  
    * Direction:
    *   OUTPUT if the direction bit is HIGH;
    *   INPUT if the direction bit is LOW;
    *
    */
    #(parameter PORT_WIDTH = 16)    // gpio candidate; board pmod jumpers;
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,                 
        input logic write,             
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,        // three addresses to use;
        input logic [`REG_DATA_WIDTH_G-1:0] wr_data,    // 32-bit;
        output logic [`REG_DATA_WIDTH_G-1:0] rd_data,   // 32-bit
        
        // external pin mapping;
        inout tri [PORT_WIDTH-1:0] dinout // ** important; must be declared as tri for input and output;
    );
    
    // signal declarations;
    logic wr_data_en;     // for writing;
    logic ctrl_dir_en;    // for direction control;
    logic rd_en;     // for reading;
    //logic rd_data_en;     // for reading;
    //logic rd_dir_en;     // for reading;
    
    // registers;
    logic [PORT_WIDTH - 1:0] wr_data_reg;
    logic [PORT_WIDTH - 1:0] rd_data_reg;
    logic [PORT_WIDTH - 1:0] dir_data_reg;
    
    // register map as noted above;
    localparam REG_DATA_OUT_OFFSET = 2'b00;
    localparam REG_DATA_IN_OFFSET = 2'b01;
    localparam REG_CTRL_DIRECTION_OFFSET = 2'b10;
    
    // body;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin        
            wr_data_reg <= 0;
            rd_data_reg <= 0;
            dir_data_reg <= 0;  // by default; input direction;
        end
        else begin
            // sample the port;
            rd_data_reg <= dinout;
            
            // sample the cpu-write-data depending on the decoded addr instruction;
            if(wr_data_en)
                wr_data_reg <= wr_data[PORT_WIDTH-1:0];
            
            if(ctrl_dir_en) 
                dir_data_reg <= wr_data[PORT_WIDTH-1:0];     
        end
            
    /* 
     decode the addr instruction;
     read and write are mutually exclusive;
    */
    // for writing;
    assign wr_data_en = write && cs && (addr[1:0] == REG_DATA_OUT_OFFSET);
    // for direction control;
    assign ctrl_dir_en = write && cs && (addr[1:0] == REG_CTRL_DIRECTION_OFFSET);
    // for reading;
    assign rd_en = read && cs;
    //assign rd_data_en = rd_en && (addr[1:0] == REG_DATA_IN_OFFSET);
    
    // determine the direction of each bit (port) individually;
    generate
        genvar i;
        for(i = 0; i < PORT_WIDTH; i++) begin
            // set high impedance: z if the port is set as input port;
            assign dinout[i] = dir_data_reg[i] ? wr_data_reg[i] : 1'bz;       
        end    
    endgenerate
        
    /* 
    read;
    there are two things to read depending on the decoded address;
    1) to read the direction register OR
    2) to read the data sampled on the input port;
    */
    always_comb 
    begin
        // default;
        rd_data = 0;
        case({rd_en, addr[1:0]})
            {1'b1, REG_DATA_IN_OFFSET}          : rd_data[PORT_WIDTH-1:0] = rd_data_reg;
            {1'b1, REG_CTRL_DIRECTION_OFFSET}   : rd_data[PORT_WIDTH-1:0] = dir_data_reg; 
            default                             : ; // nop;      
        endcase
    end     
    
endmodule

`endif // CORE_GPIO_SV