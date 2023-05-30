`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 20:34:40
// Design Name: 
// Module Name: core_video_mig_interface_top_tb
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

`ifndef CORE_VIDEO_MIG_INTERFACE_TOP_TB_SV
`define CORE_VIDEO_MIG_INTERFACE_TOP_TB_SV

`include "IO_map.svh"


module core_video_mig_interface_top_tb();

    // for simulation;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_in_100M;  // input to MMCM;
    
    // mmcm signals;
    logic clkout_100M;
    logic clkout_200M;
    logic locked;
    
    /*---------------------------------------------
    * uut signals;
    *--------------------------------------------*/
    // general;
    logic clk_sys;          // 100MHz system clock;
    logic clk_mem;          // 200MHz for MIG;
    logic reset_sys;        // user system reset;
    
    // bus interface;
    logic cs;    
    logic write;              
    logic read;               
    logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr;           
    logic [`REG_DATA_WIDTH_G-1:0]  wr_data;    
    logic [`REG_DATA_WIDTH_G-1:0]  rd_data;
    
    // (multiplexed) placeholder for motion detection video core;
    logic core_motion_wrstrobe;
    logic core_motion_rdstrobe;
    logic [22:0] core_motion_addr;
    logic [127:0] core_motion_wrdata;
    logic [127:0] core_motion_rddata;
    
    // MIG DDR2 status 
    logic core_MIG_init_complete;   // MIG DDR2 initialization complete
    logic core_MIG_ready;           // MIG DDR2 ready to accept any request
    logic core_MIG_transaction_complete; // a pulse indicating the read/write request has been serviced
    logic core_MIG_ctrl_status_idle;    // MIG synchronous interface controller idle status
    
    
    // external signals;
    logic [15:0] LED;
    logic MMCM_locked;
    
    // ddr2 sdram memory interface (defined by the imported ucf file);
    logic [12:0] ddr2_addr;  // address; 
    logic [2:0]  ddr2_ba;   
    logic ddr2_cas_n; //                                         ddr2_cas_n
    logic [0:0] ddr2_ck_n; //   [0:0]                        ddr2_ck_n
    logic [0:0] ddr2_ck_p; //   [0:0]                        ddr2_ck_p
    logic [0:0] ddr2_cke; //   [0:0]                       ddr2_cke
    logic ddr2_ras_n; //                                         ddr2_ras_n
    logic ddr2_we_n; //                                         ddr2_we_n
    tri [15:0] ddr2_dq; // [15:0]                         ddr2_dq
    tri [1:0] ddr2_dqs_n; // [1:0]                        ddr2_dqs_n
    tri [1:0] ddr2_dqs_p; // [1:0]                        ddr2_dqs_p
    logic [0:0] ddr2_cs_n; //   [0:0]           ddr2_cs_n
    tri [1:0] ddr2_dm; //   [1:0]                        ddr2_dm
    logic [0:0] ddr2_odt;  //   [0:0]                       ddr2_odt
        
    // debugging;
    logic debug_mig_reset_n;
    logic debug_MIG_init_complete_status;
     
    // mapping;
    assign clk_sys = clkout_100M;
    assign clk_mem = clkout_200M;
    assign MMCM_locked = locked;
    
    /*---------------------------------------------------
    // monitoring;
    ---------------------------------------------------*/
    logic mon_MIG_init;
    logic mon_MMCM_locked;
    logic mon_MIG_user_ready;
    logic [3:0] mon_FSM;
    logic [3:0] mon_ctrl_FSM;
    logic [4:0] mon_rd_data;
     
    assign mon_MIG_init = LED[15];
    assign mon_MMCM_locked = LED[14];
    assign mon_MIG_user_ready = LED[13];
    assign mon_FSM = LED[12:9];
    assign mon_ctrl_FSM = LED[8:5];
    assign mon_rd_data = LED[4:0];
    
    /*------------------------------------
    * instantiation 
    ------------------------------------*/
    /* ddr2 model;
    fake model to simulate the mig interface with;
    otherwise, what will the mig interface be interfacing with;
    ie without the model; the mig interface will not
    receive any simulated ddr2 memory feedback;
    
    note:
    1. this ddr2 model is copied directly from th ip-example;
    
    reference: 
    https://support.xilinx.com/s/question/0D52E00006hpsNVSAY/mig-simulation-initcalibcomplete-stays-low?language=en_US
    
    */
    
    ddr2_model ddr2_model_unit
    (
        .ck(ddr2_ck_p),
        .ck_n(ddr2_ck_n),
        .cke(ddr2_cke),
        .cs_n(ddr2_cs_n),
        .ras_n(ddr2_ras_n),
        .cas_n(ddr2_cas_n),
        .we_n(ddr2_we_n),
        .dm_rdqs(ddr2_dm),
        .ba(ddr2_ba),
        .addr(ddr2_addr),
        .dq(ddr2_dq),
        .dqs(ddr2_dqs_p),
        .dqs_n(ddr2_dqs_n),
        .rdqs_n(),
        .odt(ddr2_odt)
    );
    
    // mmcm;
    clk_wiz_0 mmcm_unit
   (
    // Clock out ports
    .clkout_24M(),     // output clkout_24M
    .clkout_100M(clkout_100M),     // output clkout_100M
    .clkout_200M(clkout_200M),     // output clkout_200M
    .clkout_250M(),     // output clkout_250M
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_in_100M)
    );      // input clk_in1

    // uut;
    core_video_mig_interface 
    #(
        // 100 ns second pause time for simulation 
        .TIMER_THRESHOLD(10),
    
        // the range of address is resticted to integer 10 for simulation;   
        .INDEX_THRESHOLD(10)
    )
    uut (.*);
    
    // test stimulus;
    core_video_mig_interface_tb tb (.*);
    
    /* simulate clk */
     always
        begin 
           clk_in_100M = 1'b1;  
           #(T/2); 
           clk_in_100M = 1'b0;  
           #(T/2);
        end
             
    /* monitoring */
    initial begin
           $monitor("USER MONITORING - time: %0t, init_complete: %0b, mmcm_locked: %0b, mig_ready: %0b, fsm_reg: %0d, ctrl_FSM: %0d, LED: %0d",
            $time,            
            mon_MIG_init,
            mon_MMCM_locked,
            mon_MIG_user_ready,
            mon_FSM,
            mon_ctrl_FSM,
            mon_rd_data
            );           
    end                               

endmodule

`endif //CORE_VIDEO_MIG_INTERFACE_TOP_TB_SV