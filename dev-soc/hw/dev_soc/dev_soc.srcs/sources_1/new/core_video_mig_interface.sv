`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 19:59:09
// Design Name: 
// Module Name: core_video_mig_interface
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

`ifndef CORE_VIDEO_MIG_INTERFACE_SV
`define CORE_VIDEO_MIG_INTERFACE_SV

`include "IO_map.svh"

module core_video_mig_interface
    #(parameter
        
        /*------------------------------------------
        * parameter for the HW testing cicruit;
        ------------------------------------------*/
        // counter/timer;
        // N seconds led pause time; with 100MHz; 200MHz threshold is required;        
        TIMER_THRESHOLD = 50_000_000,  // 0.5 second;
        
        // traffic generator to issue the addr;
        // here we just simply use incremental basis;
        INDEX_THRESHOLD = 32 // wrap around; 2^{5};
    )
    (
        // general;        
        input logic clk_sys,    // 100MHz system;
        input logic clk_mem,    // 200MHz for MIG;       
        input logic reset_sys,  // system reset;        
        
        /* --------------------------------------------------------------------------
        BUS INTERFACE
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        ---------------------------------------------------------------------------*/
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,           
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
                
        /* ----------------------------
        * external pin;
        * 1. LED;
        * 2. DDR2 SDRAM
        ------------------------------*/
        // LEDs;
        output logic [15:0] LED,
        
        // LED also display the MMCM locked status;
        input logic MMCM_locked,
                
        // ddr2 sdram memory interface (defined by the imported ucf file);
        output logic [12:0] ddr2_addr,   // address; 
        output logic [2:0]  ddr2_ba,    
        output logic ddr2_cas_n,  // output                                       ddr2_cas_n
        output logic [0:0] ddr2_ck_n,  // output [0:0]                        ddr2_ck_n
        output logic [0:0] ddr2_ck_p,  // output [0:0]                        ddr2_ck_p
        output logic [0:0] ddr2_cke,  // output [0:0]                       ddr2_cke
        output logic ddr2_ras_n,  // output                                       ddr2_ras_n
        output logic ddr2_we_n,  // output                                       ddr2_we_n
        inout tri [15:0] ddr2_dq,  // inout [15:0]                         ddr2_dq
        inout tri [1:0] ddr2_dqs_n,  // inout [1:0]                        ddr2_dqs_n
        inout tri [1:0] ddr2_dqs_p,  // inout [1:0]                        ddr2_dqs_p      
        output logic [0:0] ddr2_cs_n,  // output [0:0]           ddr2_cs_n
        output logic [1:0] ddr2_dm,  // output [1:0]                        ddr2_dm
        output logic [0:0] ddr2_odt, // output [0:0]                       ddr2_odt        
        
        /*--------------------------
        * debugging interface
        --------------------------*/            
        output logic debug_mig_reset_n    // reset signal for MIG:
        
    );
    
    ///////////////////////////////////////
    // CONSTANTS
    ///////////////////////////////////////
    // address;
    localparam MIG_INTERFACE_REG_SEL       = 4'b0000;
    localparam MIG_INTERFACE_REG_STATUS    = 4'b0001;
    localparam MIG_INTERFACE_REG_ADDR      = 4'b0010;
    localparam MIG_INTERFACE_REG_WR_CTRL   = 4'b0011;
    localparam MIG_INTERFACE_REG_RD_CTRL   = 4'b0100;
    localparam MIG_INTERFACE_REG_RDDATA_01 = 4'b0101;
    localparam MIG_INTERFACE_REG_RDDATA_02 = 4'b0110;
    localparam MIG_INTERFACE_REG_RDDATA_03 = 4'b0111;
    localparam MIG_INTERFACE_REG_RDDATA_04 = 4'b1000;    
    
    // multiplexing;
    localparam MIG_INTERFACE_REG_SEL_NONE    = 3'b000;  // none;
    localparam MIG_INTERFACE_REG_SEL_CPU     = 3'b001;  // cpu;
    localparam MIG_INTERFACE_REG_SEL_MOTION  = 3'b010;  // motion detection video cores;
    localparam MIG_INTERFACE_REG_SEL_TEST    = 3'b100;  // hw testing circuit;

    ///////////////////////////////////////
    // SIGNAL DECLARATION
    ///////////////////////////////////////
    
    /*------------------------------------------------
    // bus interface 
    ------------------------------------------------*/       
    // general enabler signals;
    logic wr_en;
    logic rd_en;
    
    // register enabler signals;
    logic wr_mux_reg_en;
    logic rd_mux_reg_en;
    logic rd_status_reg_en;
    logic rd_addr_reg_en;
    logic rd_ddr2_rddata_01_reg_en;
    logic rd_ddr2_rddata_02_reg_en;
    logic rd_ddr2_rddata_03_reg_en;
    logic rd_ddr2_rddata_04_reg_en;
        
    // cpu register;
    logic [2:0] mux_reg, mux_next;    // multiplexing;
    logic [22:0] cpu_addr_reg, cpu_addr_next;
    logic [31:0] cpu_rddata_01_reg;
    logic [31:0] cpu_rddata_02_reg;
    logic [31:0] cpu_rddata_03_reg;
    logic [31:0] cpu_rddata_04_reg;
        
    /*------------------------------------------------
    // signals for module: user_mig_DDR2_sync_ctrl 
    ------------------------------------------------*/       
    logic rst_mem_n;
    //logic MMCM_locked;    // this is already declared as an output port;
    logic user_wr_strobe;
    logic user_rd_strobe;
    logic [22:0] user_addr;
    logic [127:0] user_wr_data;
    logic [127:0] user_rd_data;
    logic MIG_user_init_complete;
    logic MIG_user_ready;
    logic MIG_user_transaction_complete;
    // MIG controller FSM is in idle state (not busy) (implies user_transaction_complete);
    ///// IMPORTANT: there is a three system (100MHz) clock delay after write/read strobe is asserted;
    logic MIG_ctrl_status_idle;      
    
    logic [3:0] debug_ctrl_FSM;
    
    /*-------------------------------------------------------
    * MIG has its own dedicated reset;
    -------------------------------------------------------*/   
    logic rst_mig_async;       
    (* ASYNC_REG = "TRUE" *) logic rst_mig_01_reg, rst_mig_02_reg;  // synchronizer    
    logic rst_mig_sync;     // synchronizer;
    
    // to stretch the synchronized rst mig signal over some N MIG clock cycles;
    localparam  RST_MIG_CYCLE_NUM = 4096;
    logic [12:0] cnt_rst_mig_reg, cnt_rst_mig_next; // width should at least hold the parameter above;
    logic rst_mig_stretch;
    logic rst_mig_stretch_reg; // to filter for glicth
    
    
    /*-------------------------------------------------------
    * signals for HW test;
    -------------------------------------------------------*/   
    logic core_hw_test_enable_ready_reg, core_hw_test_enable_ready_next; 
    logic core_hw_test_wr_strobe;   // write request from the hw core test;
    logic core_hw_test_rd_strobe;   // read request from the hw core test;
    logic [22:0] core_hw_test_addr; // address;
    logic [127:0] core_hw_test_wr_data;
    logic [127:0] core_hw_test_rd_data;
    logic [15:0] core_hw_test_LED;
    
        
    /////////////////////////////////////////////////////////////////////////////////
    /* -------------------------------------------------------------------
    * Synchronize the MIG reset signals;
    * currently; it is asynchronous with respect to the system clock;
    * this should not be necessary since;
    * MIG will internally synchronize the asynchronous reset;
    * however, this does not work on the real HW testing;
    * MIG does not come out of a CPU reset;
    * but it works when synchronizer ...
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
    
    // filter for glitch;
    always_ff @(posedge clk_mem) begin
        // note that this reset signal has been synchronized;
        if(rst_mig_sync) begin
            rst_mem_n <= 1'b1;  // active low;
        end 
        else begin
            rst_mem_n <= ~rst_mig_stretch_reg;
        end    
    end
             
    /*-----------------
    * debugging;
    --------------------*/
    assign debug_mig_reset_n = rst_mem_n;
     
    ////////////////////////////////////////////////////////////////
    // INSTANTIATION
    ////////////////////////////////////////////////////////////////
    
    // mig synchronous interface controller;
    user_mig_DDR2_sync_ctrl user_mig_DDR2_sync_ctrl_unit
    (        
        // general, 
        .clk_sys(clk_sys),    // 100MHz,
        .rst_sys(reset_sys),    // asynchronous system reset,
        
        // memory system,
        .clk_mem(clk_mem),        // 200MHz to drive MIG memory clock,
        .rst_mem_n(rst_mem_n),      // active low to reset the mig interface,
        
        /* -----------------------------------------------------
        *  interface between the user system and the memory controller,
        ------------------------------------------------------*/
        .user_wr_strobe(user_wr_strobe),             // write request,
        .user_rd_strobe(user_rd_strobe),             // read request,
        .user_addr(user_addr),           // address,
        
        // data,
        .user_wr_data(user_wr_data),   
        .user_rd_data(user_rd_data),         
        
        // status
        .MIG_user_init_complete(MIG_user_init_complete),        // MIG done calibarating and initializing the DDR2,
        .MIG_user_ready(MIG_user_ready),                // this implies init_complete and also other status, see UG586, app_rdy,
        .MIG_user_transaction_complete(MIG_user_transaction_complete), // read/write transaction complete?
        // MIG controller FSM is in idle state (not busy) (implies user_transaction_complete);
        ///// IMPORTANT: there is a three system (100MHz) clock delay after write/read strobe is asserted;
        .MIG_ctrl_status_idle(MIG_ctrl_status_idle),     
        
        /* -----------------------------------------------------
        * External Pin: MIG interface with the actual DDR2  
        ------------------------------------------------------*/
        
        // ddr2 sdram memory interface (defined by the imported ucf file),
        .ddr2_addr(ddr2_addr),   // address, 
        .ddr2_ba(ddr2_ba),    
        .ddr2_cas_n(ddr2_cas_n),  // output                                       ddr2_cas_n
        .ddr2_ck_n(ddr2_ck_n),  // output [0:0]                        ddr2_ck_n
        .ddr2_ck_p(ddr2_ck_p),  // output [0:0]                        ddr2_ck_p
        .ddr2_cke(ddr2_cke),  // output [0:0]                       ddr2_cke
        .ddr2_ras_n(ddr2_ras_n),  // output                                       ddr2_ras_n
        .ddr2_we_n(ddr2_we_n),  // output                                       ddr2_we_n
        .ddr2_dq(ddr2_dq),  // inout [15:0]                         ddr2_dq
        .ddr2_dqs_n(ddr2_dqs_n),  // inout [1:0]                        ddr2_dqs_n
        .ddr2_dqs_p(ddr2_dqs_p),  // inout [1:0]                        ddr2_dqs_p        
        .ddr2_cs_n(ddr2_cs_n),  // output [0:0]           ddr2_cs_n
        .ddr2_dm(ddr2_dm),  // output [1:0]                        ddr2_dm
        .ddr2_odt(ddr2_odt),  // output [0:0]                       ddr2_odt
        
        // not used;
        .init_calib_complete(),  // output                                       init_calib_complete
        
        /* -----------------------------------------------------
        *  debugging interface 
        ------------------------------------------------------*/
        .debug_FSM(debug_ctrl_FSM),
        
        // not used;
        .debug_app_rd_data_valid(),
        .debug_app_rd_data_end(),
        .debug_ui_clk(),
        .debug_ui_clk_sync_rst(),
        .debug_app_rdy(),
        .debug_app_wdf_rdy(),
        .debug_app_en(),
        .debug_app_wdf_data(),
        .debug_app_wdf_end(),
        .debug_app_wdf_wren(),
        .debug_init_calib_complete(),
        .debug_transaction_complete_async(),
        .debug_app_cmd(),
        .debug_app_rd_data(),        
        .debug_user_wr_strobe_sync(),
        .debug_user_rd_strobe_sync()        
    );

    // HW testing circuit;
    user_mig_HW_test_sequential     
    #(
        .TIMER_THRESHOLD(TIMER_THRESHOLD),
        .INDEX_THRESHOLD(INDEX_THRESHOLD)
    )
    
    user_mig_HW_test_sequential_unit
    (
        // general;        
        .clk_sys_100M(clk_sys),   // user system;        
        
        // user system reset signal; active HIGH     
        .reset_sys(reset_sys),                                 
        
        // LEDs;
        .LED(core_hw_test_LED),        
        
        // for LED display;        
        .MMCM_locked(MMCM_locked),  // mmcm locked status; 
        
        /*-------------------------------------------------------
        * to communicate with the MIG synchronous interface
        -------------------------------------------------------*/
        // user signals;
        .user_wr_strobe(core_hw_test_wr_strobe),            // write request;
        .user_rd_strobe(core_hw_test_rd_strobe),             // read request;
        .user_addr(core_hw_test_addr),           // address;
        
        // data;
        .user_wr_data(core_hw_test_wr_data),       
        .user_rd_data(core_hw_test_rd_data),  
        
        // status
        .MIG_user_init_complete(MIG_user_init_complete),        // MIG done calibarating and initializing the DDR2;
        //.MIG_user_ready(MIG_user_ready),                // this implies init_complete and also other status; see UG586; app_rdy;
        
        // only ready if enabled by the user;
        // core_hw_test_enable_reg == MIG_user_ready && user_choice; 
        .MIG_user_ready(core_hw_test_enable_ready_reg),
        .MIG_user_transaction_complete(MIG_user_transaction_complete), // read/write transaction complete?
        //.MIG_ctrl_status_idle(MIG_ctrl_status_idle),
        
        // debugging port;
        .debug_ctrl_FSM(debug_ctrl_FSM) // FSM of user_mig_DDR2_sync_ctrl module;
    );
    
    
    
    ////////////////////////////////////////////////////////////////
    /// BUS INTERFACING    
    ////////////////////////////////////////////////////////////////       
    // ff;
    //logic core_hw_test_enable_reg, core_hw_test_enable_next;
    
    always_ff @(posedge clk_sys, posedge reset_sys) begin
        if(reset_sys) begin
            mux_reg <= MIG_INTERFACE_REG_SEL_NONE;
            core_hw_test_enable_ready_reg <= 1'b0;
            
            cpu_addr_reg <= 0;        
            cpu_rddata_01_reg <= 0;
            cpu_rddata_02_reg <= 0;
            cpu_rddata_03_reg <= 0;
            cpu_rddata_04_reg <= 0;
                
        end
        else begin
            if(wr_mux_reg_en) begin
                mux_reg <= mux_next;
                core_hw_test_enable_ready_reg <= core_hw_test_enable_ready_next;
                cpu_addr_reg <= cpu_addr_next;
            end;
            
            // keep on reading after init is complete;
            // should be fine since the read data validity is ...
            // asserted by the transaction complete flag;
            if(MIG_user_init_complete) begin
                cpu_rddata_01_reg <= user_rd_data[31:0];
                cpu_rddata_02_reg <= user_rd_data[63:32];
                cpu_rddata_03_reg <= user_rd_data[95:64];
                cpu_rddata_04_reg <= user_rd_data[127:96];
            end
        end
    end  
    
    // addres decoding;
    assign wr_en = cs && write;
    assign rd_en = cs && read;
    
    // register 0; selector;    
    assign wr_mux_reg_en = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_SEL);
    assign mux_next = wr_data[2:0];
    
    // register 1: status;
    assign rd_mux_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_SEL);
    assign rd_status_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_STATUS);
    assign rd_addr_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_ADDR);
    
    // registers 5 - 8; ddr2 data 128-bit into four 32-bit cpu registers;
    assign rd_ddr2_rddata_01_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_RDDATA_01);
    assign rd_ddr2_rddata_02_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_RDDATA_02);
    assign rd_ddr2_rddata_03_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_RDDATA_03);
    assign rd_ddr2_rddata_04_reg_en = rd_en && (addr[3:0] == MIG_INTERFACE_REG_RDDATA_04);     
    
   // multiplexing;
   always_comb begin
   
        ////////// default; ////////////
        // common for mig ddr2 sync interface (controller);
        user_wr_data = 0;
        user_addr = 0;
        user_wr_strobe = 0;
        user_rd_strobe = 0;
        LED = 0;
        
        // hw test core;
        core_hw_test_enable_ready_next = 1'b0;
        core_hw_test_rd_data = 0;
        
        // cpu;
        cpu_addr_next = 0;
        
        // bus interface;
        rd_data = 0;
        
        ////////// start the machinery; /////////////
        /*
        localparam MIG_INTERFACE_REG_SEL_NONE    = 3'b000;  // none;
        localparam MIG_INTERFACE_REG_SEL_CPU     = 3'b001;  // cpu;
        localparam MIG_INTERFACE_REG_SEL_MOTION  = 3'b010;  // motion detection video cores;
        localparam MIG_INTERFACE_REG_SEL_TEST    = 3'b100;  // hw testing circuit;
        */
        case(mux_reg)
            MIG_INTERFACE_REG_SEL_CPU: begin
                // read multiplexing for the cpu;
                if(rd_mux_reg_en) begin
                    rd_data = {29'b0, mux_reg};
                end
                // status of the mig ddr2;
                else if(rd_status_reg_en) begin
                    rd_data = {28'b0, MIG_ctrl_status_idle, MIG_user_transaction_complete, MIG_user_ready, MIG_user_init_complete};                
                end
                // current address pointer;
                else if(rd_addr_reg_en) begin
                    rd_data = {9'b0, cpu_addr_reg};
                end
                
                // the reset of the 128-bit data read from the mig ddr2;
                // 128-bit is "divided" into four 32-bit cpu registers;
                
                // first batch;
                else if(rd_ddr2_rddata_01_reg_en) begin
                    rd_data = cpu_rddata_01_reg;                                    
                end
                
                // second batch;
                else if(rd_ddr2_rddata_02_reg_en) begin
                    rd_data = cpu_rddata_02_reg;                                    
                end
                
                // third batch;
                else if(rd_ddr2_rddata_03_reg_en) begin
                    rd_data = cpu_rddata_03_reg;                                    
                end
                
                // last batch;
                else if(rd_ddr2_rddata_04_reg_en) begin
                    rd_data = cpu_rddata_04_reg;                                    
                end
            end
            
            MIG_INTERFACE_REG_SEL_TEST: begin                
                core_hw_test_enable_ready_next = MIG_user_ready && 1'b1;
                user_wr_strobe = core_hw_test_wr_strobe;
                user_rd_strobe = core_hw_test_rd_strobe;
                user_addr = core_hw_test_addr;
                user_wr_data = core_hw_test_wr_data;
                core_hw_test_rd_data = user_rd_data;
                LED = core_hw_test_LED;
            end
            
        
            
            // MIG_INTERFACE_REG_SEL_NONE
            default:     ;                
        endcase
   
   end 
   
     
    
endmodule


`endif //CORE_VIDEO_MIG_INTERFACE_SV