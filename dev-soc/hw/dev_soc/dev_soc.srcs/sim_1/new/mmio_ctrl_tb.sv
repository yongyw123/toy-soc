`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2023 22:06:05
// Design Name: 
// Module Name: mmio_ctrl_tb
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

`ifndef _MIMO_CTRL_TB_SV
`define _MIMO_CTRL_TB_SV

`include "IO_map.svh"


module mmio_ctrl_tb();
    /*
    // Purpose: Test Bench for mmio_ctrl() module
    // 
    // mmio_ctrl() Construction:
    //      1. this controller acts as an interface between
    //            the microblaze mcs and the memory-map io cores via a bus;
    //      2. 64 IO cores are allocated in the address map;
    //      3. each IO core has 32 internal registers;
    //
    // by construction, the controller will broadcast 
    // everything to all module;
    //  
    // only the specific IO core will respond to the controller 
    // after the address is decoded;
    //
    // since there is no actual IO core, we use dummy values
    //
    // to test the mmio controller is working;
    // we just need to test whether the controller decodes
    // and multiplexes correctly
    // 
    */
    
    localparam T = 10;  // clock period: 10ns;
    
    /* ------- module IO interface;*/
    logic clk;                    // 100 MHz;
    logic reset;                  // async;
    
    // control signals;
    logic mmio_cs;                // to select the mimo system (map);
    logic mmio_wr;                // to write;
    logic mmio_rd;                // to read;
    
    // address;
    logic [`BUS_USER_SIZE_G-1:0] mmio_addr;       // addr to decode;
    // data;
    logic [`REG_DATA_WIDTH_G-1:0] mmio_wr_data;  // 32 bit;
    logic [`REG_DATA_WIDTH_G-1:0] mmio_rd_data; // 32-bit;
     
    /* core interface; */
    // individual control signals for each core;
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_cs_array; // chip select;
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_wr_array; // write enable; 
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_rd_array; // read enable;
    
    // input, output, and register data for each core;
    logic [`REG_ADDR_SIZE_G-1:0] core_addr_reg_array[`MIMO_CORE_TOTAL_G-1:0]; // register of each core;
    logic [`REG_DATA_WIDTH_G-1:0] core_data_rd_array[`MIMO_CORE_TOTAL_G-1:0]; // read data from each core;
    logic [`REG_DATA_WIDTH_G-1:0] core_data_wr_array[`MIMO_CORE_TOTAL_G-1:0]; // write data from each core;
    
    // module instantiation;
    mmio_ctrl uut(.*);
    
    /* note that the uut is purely combinational */
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // sim var;
    logic [4:0] sim_reg_addr;
    logic [5:0] sim_core_addr;
    
    // set up read data for the mmio controller;
    initial 
    begin
        for(int i = 0; i < 64; i++) begin
            core_data_rd_array[i] = 32'($random);
            //$display("index: %0d, read datad: %0d, read datab: %0B", i, core_data_rd_array[i], core_data_rd_array[i]); 
        end
        
    end
    
    initial 
    begin
        $display("---- test start ----");
        for(int i = 0; i < 64; i++) begin
            /*
            // mmio controller only decodes core address;
            // the rest is of no concern;
            // core address is 6-bit;
            */
            sim_reg_addr = 5'($random);
            sim_core_addr = 6'(i);
            mmio_addr = {10'($random), sim_core_addr, sim_reg_addr}; 
            
            // info to be broadcasted;
             mmio_wr = 1'($random);    
             mmio_rd = 1'($random);    
             mmio_cs = 1'b1;    
             mmio_wr_data = 32'($random);         
            
            // expect the read data corresponds to the content at core with address i;
            #5 assert(mmio_rd_data == core_data_rd_array[i]);
            //#5 $display("mmio read: %0d, set read: %0d",  mmio_rd_data, core_data_rd_array[i]);
            
            /* 
            $display("index: %0d, wr: %0b, rd: %0b, cs: %0b, wr_data: %0d, core_addr: %0d, reg_addr: %0d", 
                    i,  mmio_wr, mmio_rd, mmio_cs, 
                     mmio_wr_data, sim_core_addr, sim_reg_addr);

            $display("----------");
            */
            
            #5; //wait for the combinational delay;
            
            // expect all info is broadcasted, thus to be the same;
            // except for the read data and cs;  
            for(int j = 0; j < 64; j++) begin
                
                /*$display("index: %0d, wr: %0b, rd: %0b, cs: %b,  wr_data: %0d, reg_addr: %0d", 
                    j,  core_ctrl_wr_array[j], core_ctrl_rd_array[j],
                    core_ctrl_cs_array[j],
                     core_data_wr_array[j], core_addr_reg_array[j]);
                */
                
                assert(core_ctrl_wr_array[j] == 64'(mmio_wr));           
                assert(core_ctrl_rd_array[j] == 64'(mmio_rd));
                assert(core_data_wr_array[j] == mmio_wr_data);
                assert(core_addr_reg_array[j] == sim_reg_addr);
                
                if(i == j) 
                    assert(core_ctrl_cs_array[i] == 64'(mmio_cs))
                else
                    assert(core_ctrl_cs_array[i] == 1'b0);                        
            end
       end
       $display("---- test end ----"); 
        
        
    $stop;
    end
    
    
endmodule

`endif // _MIMO_CTRL_TB_SV


