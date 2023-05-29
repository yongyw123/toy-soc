`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 16:55:47
// Design Name: 
// Module Name: user_mig_HW_test_sequential_top_tb
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


module user_mig_HW_test_sequential_top_tb();

    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_in_100M;         // common system clock;
    logic reset_sys;        // user system reset;
    
    // mmcm signals;
    logic clkout_100M;
    logic clkout_200M;
    logic locked;
                  
    /*-------------------------------------------------------
    * MIG reset;
    * synchronize the MIG reset with respect to its own clock;
    * MIG clock: ?? TBA ??
    -------------------------------------------------------*/   
    logic rst_mig_async;    // assigned to rst_sys_sync;
    (* ASYNC_REG = "TRUE" *) logic rst_mig_01_reg, rst_mig_02_reg;  // synchronizer    
    logic rst_mig_sync;     // synchronizer;
    
    // to stretch the synchronized rst mig signal over some N MIG clock cycles;
    localparam  RST_MIG_CYCLE_NUM = 4096;
    logic [12:0] cnt_rst_mig_reg, cnt_rst_mig_next; // width should at least hold the parameter above;
    logic rst_mig_stretch;
    logic rst_mig_stretch_reg; // to filter for glicth
    
    /*-------------------------------
    // uut signals;
    -------------------------------*/    
    logic clk_sys_100M;
    //logic reset_sys;
    logic [15:0] LED;
    logic MMCM_locked;
    logic user_wr_strobe;
    logic user_rd_strobe;
    logic [22:0] user_addr;
    logic [127:0] user_wr_data;
    logic [127:0] user_rd_data;
    logic MIG_user_init_complete;
    logic MIG_user_ready;
    logic MIG_user_transaction_complete;
    logic [3:0] debug_ctrl_FSM;
    
     
    // uut signal mapping;
    assign clk_sys_100M = clkout_100M;
    assign MMCM_locked = locked;
    
    /*-------------------------------------
    // mig synchronous interface signals;
    -------------------------------------*/
    logic clk_sys;  
    logic rst_sys;
    //logic user_wr_strobe;
    //logic user_rd_strobe;
    //logic [22:0] user_addr;
    //logic [127:0] user_wr_data;   
    //logic [127:0] user_rd_data;         
    //logic MIG_user_init_complete;
    //logic MIG_user_ready;
    //logic MIG_user_transaction_complete;
    
    logic clk_mem;
    logic rst_mem_n;

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
    logic init_calib_complete;      
    logic [0:0] ddr2_cs_n; //   [0:0]           ddr2_cs_n
    tri [1:0] ddr2_dm; //   [1:0]                        ddr2_dm
    logic [0:0] ddr2_odt;  //   [0:0]                       ddr2_odt
        
    // debugging interface
    logic debug_app_rd_data_valid;
    logic debug_app_rd_data_end;
    logic debug_ui_clk;
    logic debug_ui_clk_sync_rst;
    logic debug_app_rdy;
    logic debug_app_wdf_rdy;
    logic debug_app_en;
    logic [63:0] debug_app_wdf_data;
    logic debug_app_wdf_end;
    logic debug_app_wdf_wren;
    logic debug_init_calib_complete;
    logic debug_transaction_complete_async;
    logic [2:0] debug_app_cmd;
    logic [63:0] debug_app_rd_data;
    logic debug_user_wr_strobe_sync;
    logic debug_user_rd_strobe_sync;
    logic [3:0] debug_FSM;
        
    // mapping;
    assign clk_sys = clkout_100M;
    assign rst_sys = reset_sys;
    assign clk_mem = clkout_200M;
    assign rst_mem_n = ~rst_mig_stretch_reg;
    
    // for the uut;
    assign debug_ctrl_FSM = debug_FSM;
    
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
    
    /* -------------------------------------------------------------------
    * Synchronize the MIG reset signals;
    * currently; it is asynchronous with respect to the system clock;
    * this should not be necessary since;
    * MIG will internally synchronize the asynchronous reset;
    * however, this does not work on the real HW testing;
    * MIG does not come out of a CPU reset;
    * so trying to do something different here;
    -------------------------------------------------------------------*/    
    // use the synchronized system rst as the input;
    assign rst_mig_async = reset_sys;
    always_ff @(posedge clk_mem) begin    
        rst_mig_01_reg <= rst_mig_async;
        rst_mig_02_reg <= rst_mig_01_reg;        
    end
    assign rst_mig_sync = rst_mig_02_reg;
    
    /*--------------------------------------------------
    * To stretch the synchronized mig reset sys over N memory clock periods;
    * where the memory clock is 200MHz driving the MIG;
    --------------------------------------------------*/
       
    always_ff @(posedge clk_mem) begin    
        // note that this reset signal has been synchronized;
        if(rst_mig_sync) begin
            cnt_rst_mig_reg <= 0;
        end 
        else begin
            cnt_rst_mig_reg <= cnt_rst_mig_next;
        end    
    end
    
    // next state logic;
    // stop the count if the threshold has been met;
    assign cnt_rst_mig_next = (cnt_rst_mig_reg == RST_MIG_CYCLE_NUM) ? cnt_rst_mig_reg : cnt_rst_mig_reg + 1;    
    assign rst_mig_stretch = (cnt_rst_mig_reg != RST_MIG_CYCLE_NUM);
    
    // filter the mig rst_sys_stretch to avoid glitch since it comes from a combinational block;
    always_ff @(posedge clk_mem) begin
        // note that this reset signal has been synchronized;
        if(rst_mig_sync) begin
            rst_mig_stretch_reg <= 0;
        end 
        else begin
            rst_mig_stretch_reg <= rst_mig_stretch;
        end    
    end
    
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

    // mig synchronous interface;
    user_mig_DDR2_sync_ctrl mig_ctrl_unit (.*);
    
    // uut;
    user_mig_HW_test_sequential 
    #(
        // 100 ns second pause time for simulation instead 2.0 second for real testing;
        .TIMER_THRESHOLD(10),
    
        // the range of address is resticted to integer 10 for simulation;   
        .INDEX_THRESHOLD(10)
    )
    uut 
    (.*);
    
    // test stimulus;
    user_mig_HW_test_sequential_tb tb (.*);
    
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
           $monitor("USER MONITORING - time: %0t, uut.state_reg: %s, uut.state_next: %s, init_complete: %0b, mmcm_locked: %0b, mig_ready: %0b, fsm_reg: %0d, ctrl_FSM: %0d, LED: %0d",
            $time,
            uut.state_reg.name,
            uut.state_next.name,
            
            mon_MIG_init,
            mon_MMCM_locked,
            mon_MIG_user_ready,
            mon_FSM,
            mon_ctrl_FSM,
            mon_rd_data
            
            /*                    
            uut.LED[15],            
            uut.LED[14],
            uut.LED[13],
            uut.LED[12:9],
            uut.LED[8:5],
            uut.LED[8:0]
            */
            );           
    end                               

endmodule
