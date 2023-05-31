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

/*****************************************************************
V5_MIG_INTERFACE
-----------------
Purpose: to select which source to interface with the DDR2 SDRAM via MIG;
It is either interfacing with:
1. CPU;
2. other video core: motion detection?
3. a HW testing circuit;

Construction:
1. DDR2 read/write transaction is 128-bit.
2. So this complicates stuffs since ublaze register is 32-bit wide only;
3. to facilitate the read/write operation, we use multiple registers;

3.1 note that each address (bit) covers one 128-bit;

4. For write:
    1. we shall have multiple write control register bits:
    2. before submitting write request, we need to shift in the ublaze 32-bit into 128-bit;
    3. each bit is to push a 32-bit from ublaze to the 128-bit DDR2 register;
    4. some bits to setup the write address;
    5. one bit to submit the write request;

5. For read;
    1. similarly, we need multiple read control register bits;
    2. after submitting the read request along with the read address, we check and wait for transaction complete status;
    3. this completion status indicates the data on the bus is ready to be read;
    4. it takes "4 times" to shift in the 128-bit into four registers of 32-bit each;
      

-----
Register Map
1. Register 0 (Offset 0): select register;
2. Register 1 (Offset 1): status register;
3. Register 2 (Offset 2): address, common for read and write;
3. Register 3 (Offset 3): write control register;
4. Register 4 (Offset 4): read control register;
5. Register 5 (Offset 5): read data batch 01;
6. Register 6 (Offset 6): read data batch 02;
7. Register 7 (Offset 7): read data batch 03;
8. Register 8 (Offset 8): read data batch 04;

Register Definition:
1. Register 0 (Offset 0): select register;
    bit[2:0] for multiplexing
        3'b000: NONE
        3'b001: CPU
        3'b010: Motion Detection Core
        3'b100: HW Testing Circuit;
        
2. Register 1 (Offset 1): Status Register
        bit[0]: MIG DDR2 initialization complete status; active high;
        bit[1]: MIG DDR2 app ready status (implies init complete status); active high;
        bit[2]: transaction completion status, common for both read and write; ONLY LAST ONE CLOCK CYCLE;     
        bit[3]: MIG controller idle status; active high;
            
3. Register 2 (Offset 2): address common for read and write;
        bit[22:0] address;

4. Register 3 (Offset 3): Control Register;
        bit[0]: submit the write request; (Need to clear once submitting for a single write operation);
        bit[1]: submit the read request; (Need to clear once submitting for a single write operation);        
      
5. Register 4 (Offset 4): DDR2 Write Register - push the first 32-bit batch of the write_data[31:0]; active HIGH;
6. Register 5 (Offset 5): DDR2 Write Register - push the second 32-bit batch of the write_data[63:32]; active HIGH;
7. Register 6 (Offset 6): DDR2 Write Register - push the third 32-bit batch of the write_data[95:64]; active HIGH;
8. Register 7 (Offset 7): DDR2 Write Register -  push the forth 32-bit batch of the write_data[127:96]; active HIGH;
       
9. Register 8-11: to store the 128-bit read data as noted in the construction;

Register IO:
1. Register 0: read and write;
2. Register 1: read only;
3. Register 2: read and write;
4. Register 3: write only;
5. Register 4: write only;
6. Register 5: write only;
7. Register 6: write only;
8. Register 7: write only;
9. Register 8: read only;
10. Register 9: read only;
11. Register 10: read only;
12. Register 11: read only;
 
*****************************************************************/


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
                
        /* --------------------------------------------------------------------------
        * (Multiplexed) Input Interface with this video core: motion detection 
        ---------------------------------------------------------------------------*/
        input logic core_motion_wrstrobe,
        input logic core_motion_rdstrobe,
        input logic [22:0] core_motion_addr,
        input logic [127:0] core_motion_wrdata,
        output logic [127:0] core_motion_rddata,
        
        /* --------------------------------------------------------------------------
        * MIG DDR2 status; 
        ---------------------------------------------------------------------------*/
         output logic core_MIG_init_complete,   // MIG DDR2 initialization complete;
         output logic core_MIG_ready,           // MIG DDR2 ready to accept any request;
         output logic core_MIG_transaction_complete, // a pulse indicating the read/write request has been serviced;
         output logic core_MIG_ctrl_status_idle,    // MIG synchronous interface controller idle status;
                
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
        output logic debug_mig_reset_n,    // reset signal for MIG:
        output logic debug_MIG_init_complete_status,
        output logic debug_MIG_transaction_complete_status,
        output logic debug_MIG_ctrl_status_idle,
        output logic [2:0] debug_mux_reg
        
    );
    
    ///////////////////////////////////////
    // CONSTANTS
    ///////////////////////////////////////
    // address;
    localparam MIG_INTERFACE_REG_SEL       = `V5_MIG_INTERFACE_REG_SEL;
    localparam MIG_INTERFACE_REG_STATUS    = `V5_MIG_INTERFACE_REG_STATUS;
    localparam MIG_INTERFACE_REG_ADDR      = `V5_MIG_INTERFACE_REG_ADDR;
    localparam MIG_INTERFACE_REG_CTRL      = `V5_MIG_INTERFACE_REG_CTRL;
    
    localparam MIG_INTERFACE_REG_WRDATA_01 = `V5_MIG_INTERFACE_REG_WRDATA_01;
    localparam MIG_INTERFACE_REG_WRDATA_02 = `V5_MIG_INTERFACE_REG_WRDATA_02;
    localparam MIG_INTERFACE_REG_WRDATA_03 = `V5_MIG_INTERFACE_REG_WRDATA_03;
    localparam MIG_INTERFACE_REG_WRDATA_04 = `V5_MIG_INTERFACE_REG_WRDATA_04;
    
    localparam MIG_INTERFACE_REG_RDDATA_01 = `V5_MIG_INTERFACE_REG_RDDATA_01;
    localparam MIG_INTERFACE_REG_RDDATA_02 = `V5_MIG_INTERFACE_REG_RDDATA_02;
    localparam MIG_INTERFACE_REG_RDDATA_03 = `V5_MIG_INTERFACE_REG_RDDATA_03;
    localparam MIG_INTERFACE_REG_RDDATA_04 = `V5_MIG_INTERFACE_REG_RDDATA_04;
    
    // multiplexing;
    localparam MIG_INTERFACE_REG_SEL_NONE    = 3'b000;  // none;
    localparam MIG_INTERFACE_REG_SEL_CPU     = 3'b001;  // cpu;
    localparam MIG_INTERFACE_REG_SEL_MOTION  = 3'b010;  // motion detection video cores;
    localparam MIG_INTERFACE_REG_SEL_TEST    = 3'b100;  // hw testing circuit;
    
    
    //bit position;
    localparam MIG_INTERFACE_REG_CTRL_BIT_POS_WRSTROBE = 0;
    localparam MIG_INTERFACE_REG_CTRL_BIT_POS_RDSTROBE = 1;
    
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
    logic wr_en_reg_mux;
    logic wr_en_reg_addr;
    logic wr_en_reg_ctrl;
    
    // mig ddr2 write is 128-bit; so need to shift in the four 32-bit cpu registers; 
    logic wr_en_reg_cpu_ddr2_wrdata_01;
    logic wr_en_reg_cpu_ddr2_wrdata_02;
    logic wr_en_reg_cpu_ddr2_wrdata_03;
    logic wr_en_reg_cpu_ddr2_wrdata_04;
    
    // register to hold wr_data from the cpu for ddr2 writing operation;
    // ddr2 wr is 128-bit data; but cu register is 32-bit; need four cpu registers;
    logic [31:0] cpu_ddr2_wrdata_01_reg;
    logic [31:0] cpu_ddr2_wrdata_02_reg;
    logic [31:0] cpu_ddr2_wrdata_03_reg;
    logic [31:0] cpu_ddr2_wrdata_04_reg;
           
    ////// cpu register;
    logic [2:0] mux_reg, mux_next;    // multiplexing;
    logic [3:0] status_reg, status_next;    // aggregating status from various parts;
    logic [22:0] cpu_addr_reg;
    logic [31:0] cpu_ctrl_reg;
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
    assign debug_MIG_init_complete_status = MIG_user_init_complete;
    assign debug_MIG_transaction_complete_status = MIG_user_transaction_complete;
    assign debug_MIG_ctrl_status_idle = MIG_ctrl_status_idle; 
    assign debug_mux_reg = mux_reg;
    
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
        //.rst_mem_n(rst_mem_n),      // active low to reset the mig interface,
        .rst_mem_n(~rst_mig_stretch_reg),      // active low to reset the mig interface,
        
        //  interface between the user system and the memory controller,
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
        
        ////// External Pin: MIG interface with the actual DDR2  
        
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
        
        
        /////  debugging interface 
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
            status_reg <= 0;
            cpu_ctrl_reg <= 0;
            core_hw_test_enable_ready_reg <= 1'b0;                            
            cpu_addr_reg <= 0;        
            
            cpu_rddata_01_reg <= 0;
            cpu_rddata_02_reg <= 0;
            cpu_rddata_03_reg <= 0;
            cpu_rddata_04_reg <= 0;

            cpu_ddr2_wrdata_01_reg <= 0;
            cpu_ddr2_wrdata_02_reg <= 0;
            cpu_ddr2_wrdata_03_reg <= 0;
            cpu_ddr2_wrdata_04_reg <= 0;                           
        end
        
        else begin
            //////// no conditionals needed;
            // to disable/enable the hw testing; 
            core_hw_test_enable_ready_reg <= core_hw_test_enable_ready_next;
            status_reg <= status_next;
            
            // selecting which core/source to interface with the ddr2;
            if(wr_en_reg_mux) begin
                mux_reg <= mux_next;                                                
            end;
            
            // ddr2 address specified by the cpu;
            if(wr_en_reg_addr) begin
                cpu_addr_reg <= wr_data[22:0];
            end
            
            // control register;
            if(wr_en_reg_ctrl) begin
                cpu_ctrl_reg <= wr_data;
            end
            
            // keep on reading after init is complete;
            // should be fine since the read data validity is ...
            // asserted by the transaction complete flag;
            if(MIG_user_init_complete) begin
                cpu_rddata_01_reg <= user_rd_data[31:0];
                cpu_rddata_02_reg <= user_rd_data[63:32];
                cpu_rddata_03_reg <= user_rd_data[95:64];
                cpu_rddata_04_reg <= user_rd_data[127:96];
            end
            
            // ddr2 write data;
            if(wr_en_reg_cpu_ddr2_wrdata_01) begin
                cpu_ddr2_wrdata_01_reg <= wr_data;
            end
            
            if(wr_en_reg_cpu_ddr2_wrdata_02) begin
                cpu_ddr2_wrdata_02_reg <= wr_data;
            end
            
            if(wr_en_reg_cpu_ddr2_wrdata_03) begin
                cpu_ddr2_wrdata_03_reg <= wr_data;
            end
            
            if(wr_en_reg_cpu_ddr2_wrdata_04) begin
                cpu_ddr2_wrdata_04_reg <= wr_data;
            end
        end
    end  
    
    // addres decoding;
    assign wr_en = cs && write;
    assign rd_en = cs && read;
    
    // register 0; selector;    
    assign wr_en_reg_mux = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_SEL);
    assign mux_next = wr_data[2:0];
        
    // register 1: status;        
    assign status_next = {MIG_ctrl_status_idle, MIG_user_transaction_complete, MIG_user_ready, MIG_user_init_complete};
    
    // register 2: addr;   
    assign wr_en_reg_addr = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_ADDR);
    
    // register 3: control register;
    assign wr_en_reg_ctrl = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_CTRL);
    
    // registers to push the cpu 32-bit data to the ddr2 128-bit write data;
    assign wr_en_reg_cpu_ddr2_wrdata_01 = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_WRDATA_01);
    assign wr_en_reg_cpu_ddr2_wrdata_02 = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_WRDATA_02);
    assign wr_en_reg_cpu_ddr2_wrdata_03 = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_WRDATA_03);
    assign wr_en_reg_cpu_ddr2_wrdata_04 = (wr_en) && (addr[3:0] == MIG_INTERFACE_REG_WRDATA_04);
        
   // write decoding;
   always_comb begin   
        ////////// default; ////////////
        // common for mig ddr2 sync interface (controller);
        user_wr_data = 0;
        user_addr = 0;
        user_wr_strobe = 0;
        user_rd_strobe = 0;
        
        ///// display the state of the mig/ddr2 for debugging convenience;
        // led[15] - mmcm locked status;
        // led[14] - mig user init/calib completion flag;
        // led[13] - mig app ready signal;
        // led[12] - mig user controller transaction complete;
        // led[11] - mig user controller idle state;
        LED = {MMCM_locked, MIG_user_init_complete, MIG_user_ready, MIG_user_transaction_complete, MIG_ctrl_status_idle, 11'b0};
        //LED = 16'b0;
        
        // hw test core;
        core_hw_test_enable_ready_next = 1'b0;
        core_hw_test_rd_data = 0;
                
        // motion detection core;
        core_motion_rddata = 0;         
        core_MIG_init_complete = 0;
        core_MIG_ready = 0;
        core_MIG_transaction_complete = 0;
        core_MIG_ctrl_status_idle = 0;
        
        ////////// start the machinery; /////////////
        /*
        localparam MIG_INTERFACE_REG_SEL_NONE    = 3'b000;  // none;
        localparam MIG_INTERFACE_REG_SEL_CPU     = 3'b001;  // cpu;
        localparam MIG_INTERFACE_REG_SEL_MOTION  = 3'b010;  // motion detection video cores;
        localparam MIG_INTERFACE_REG_SEL_TEST    = 3'b100;  // hw testing circuit;
        */
        case(mux_reg)
            MIG_INTERFACE_REG_SEL_CPU: begin                
                // signal assignment to the ddr2 mig interface;               
                user_addr = cpu_addr_reg;
                user_wr_data = {cpu_ddr2_wrdata_04_reg, cpu_ddr2_wrdata_03_reg, cpu_ddr2_wrdata_02_reg, cpu_ddr2_wrdata_01_reg};
                user_wr_strobe = cpu_ctrl_reg[MIG_INTERFACE_REG_CTRL_BIT_POS_WRSTROBE];
                user_rd_strobe = cpu_ctrl_reg[MIG_INTERFACE_REG_CTRL_BIT_POS_RDSTROBE];                                
            end
            
            MIG_INTERFACE_REG_SEL_MOTION: begin
                // control;
                user_wr_strobe = core_motion_wrstrobe;
                user_rd_strobe = core_motion_rdstrobe;
                user_addr = core_motion_addr;
                
                // data;
                user_wr_data = core_motion_wrdata;                
                core_motion_rddata = user_rd_data;
                
                // status;
                core_MIG_init_complete = MIG_user_init_complete;  // MIG DDR2 initialization complete;
                core_MIG_ready = MIG_user_ready;          // MIG DDR2 ready to accept any request;
                core_MIG_transaction_complete = MIG_user_transaction_complete;// a pulse indicating the read/write request has been serviced;
                core_MIG_ctrl_status_idle = MIG_ctrl_status_idle;   // MIG synchronous interface controller idle status;                      
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
   
   // read multiplexing for the cpu;
   always_comb begin
        // default;
        rd_data = 32'b0;
        case({rd_en, addr[3:0]})
            // mux register;
            {1'b1, MIG_INTERFACE_REG_SEL}   : rd_data = {29'b0, mux_reg};
            
            // status register
            {1'b1, MIG_INTERFACE_REG_STATUS}: rd_data = {28'b0, status_reg};
            
            // address register;
            {1'b1, MIG_INTERFACE_REG_ADDR}  : rd_data = {9'b0, cpu_addr_reg};
            
            ////////// to shift in (unpack) the 128-bit ddr2 data into four 32-bit batches;
            // first batch;
            {1'b1, MIG_INTERFACE_REG_RDDATA_01}: rd_data = cpu_rddata_01_reg;
            {1'b1, MIG_INTERFACE_REG_RDDATA_02}: rd_data = cpu_rddata_02_reg;
            {1'b1, MIG_INTERFACE_REG_RDDATA_03}: rd_data = cpu_rddata_03_reg;
            {1'b1, MIG_INTERFACE_REG_RDDATA_04}: rd_data = cpu_rddata_04_reg;
            
            default: ; // nop;
        endcase 
   end          
       
endmodule


`endif //CORE_VIDEO_MIG_INTERFACE_SV