`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 00:09:09
// Design Name: 
// Module Name: FF_synchronizer_fast_to_slow
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
* purpose: synchronizer from fast clock domain to slow clock domain;
*
* assumption;
* 1. fast clock domain: 150MHz; // this is the UI clock generated by the MIG interface;
* 2. slow clock domain: 100MHz; // this is the board system clock;
* 3. fast = 1.5 slow;
* 4. input data value to synchronize must be stable for three destination (slow) clock edges
*       (to avoid missed events);
*  
* Note;
* with the assumptions above; a simple double ff is sufficient (or safe?)
* if any of the assumptions is violated, then this module shall be revised again;
* 
*
* Reference:
* 1. https://www.verilogpro.com/clock-domain-crossing-part-1/#:~:text=The%20easy%20case%20is%20passing%20signals%20from%20a,these%20cases%2C%20a%20simple%20two-flip-flop%20synchronizer%20may%20suffice.
* 2. http://www.verilab.com/files/sva_cdc_paper_dvcon2006.pdf
*/


module FF_synchronizer_fast_to_slow
    #(parameter WIDTH=1)
    (
        // destination; slow domain;
        input logic clk_dest,  
        input logic rst_dest,  
        
        // source; from fast domain
        input logic [WIDTH-1:0] in_async,
        
        // to slow domain
        output logic [WIDTH-1:0] out_sync
    );
        
    /*
    NOTE on ASYNC_REG;
    1. This is reported in the route design;
    2. Encountered Error: "TIMING-10#1 Warning
        Missing property on synchronizer  
        One or more logic synchronizer has been detected between 2 clock domains 
        but the synchronizer does not have the property ASYNC_REG defined on one 
        or both registers.
        It is recommended to run report_cdc for a complete and detailed CDC coverage
    "
    3. See Xilinx UG901 (https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/ASYNC_REG)
    The ASYNC_REG is an attribute that affects many processes in the Vivado tools flow. 
    The purpose of this attribute is to inform the tool that a register is capable of receiving 
    asynchronous data in the D input pin relative to the source clock, 
    or that the register is a synchronizing register within a synchronization chain.
    */
    
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_reg_01, sync_reg_02;
    always_ff @(posedge clk_dest, posedge rst_dest) begin
        if(rst_dest) begin
            sync_reg_01 <= 0;
            sync_reg_02 <= 0;
        end else begin
            sync_reg_01 <= in_async;
            sync_reg_02 <= sync_reg_01;            
        end
    end
    assign out_sync = sync_reg_02;
endmodule
