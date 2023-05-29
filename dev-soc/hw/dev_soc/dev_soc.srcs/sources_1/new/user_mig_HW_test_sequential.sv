`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 01:08:05
// Design Name: 
// Module Name: user_mig_HW_test_sequential
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

Purpose: 
This is a hw testing circuit for user_mig_DDR2_sync_ctrl module
by testing with the actual DDR2 external memory
on the fpga dev board;

Test:
1. Sequentially write to the DDR2 followed by a read from the DDR2 and display the value as the LED;
2. for simplicity, we shall restrict the data range to 2^{5};
3. for visual inspection; we shall have a timer for each LED change;

Note:
1. by above, this test is not exhaustive;
2. merely to test the communication with the real DDR2 external memory;

*/    

module user_mig_HW_test_sequential    
    #(parameter
        // counter/timer;
        // 2 seconds led pause time; with 100MHz; 200MHz threshold is required;
        //TIMER_THRESHOLD = 200_000_000,
        TIMER_THRESHOLD = 50_000_000,  // 0.5 second;
        
        // traffic generator to issue the addr;
        // here we just simply use incremental basis;
        INDEX_THRESHOLD = 32 // wrap around; 2^{5};
    )     
    (
        // general;        
        input logic clk_sys_100M,   // user system;
        input logic clk_mem_200M,   // MIG;        
        input logic MMCM_locked,  // mmcm locked status; 
                 
        // user system reset signal; active HIGH     
        input logic reset_sys,         
        
        // mig has its own dedicated reset signal; active HIGH
        input logic reset_mig,  
        
        // LEDs;
        output logic [15:0] LED,
                
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
        output logic [0:0] ddr2_odt // output [0:0]                       ddr2_odt
        
        /*-----------------------------------
        * debugging interface
        * to remove for synthesis;
        *-----------------------------------*/                   
        /*
        output logic debug_wr_strobe,
        output logic debug_rd_strobe,
        output logic debug_rst_sys,
        output logic debug_clk_sys,
        output logic debug_rst_sys_stretch,
        output logic debug_ui_clk_sync_rst,
        output logic debug_init_calib_complete,
        output logic debug_rst_mig_stretch_reg,
        output logic debug_ui_clk,
        output logic debug_rst_sys_raw,
        output logic debug_locked,
        output logic debug_MIG_user_transaction_complete,
        output logic debug_transaction_complete_async
        */           
    );
        
            
    /*-------------------------------------------------------
    * ddr2 MIG
    -------------------------------------------------------*/
    // user signals for the uut;
    logic user_wr_strobe;             // write request;
    logic user_rd_strobe;             // read request;
    logic [22:0] user_addr;           // address;
    
    // data;
    logic [127:0] user_wr_data;       
    logic [127:0] user_rd_data;   
    
    // status
    logic MIG_user_init_complete;        // MIG done calibarating and initializing the DDR2;
    logic MIG_user_ready;                // this implies init_complete and also other status; see UG586; app_rdy;
    logic MIG_user_transaction_complete; // read/write transaction complete?
            
    /*--------------------------------------
    * application test signals 
    --------------------------------------*/    
    ///////////     
    /* 
    state:
    1. ST_CHECK_INIT    : wait for the memory initialization to complete before starting everything else;
    2. ST_WRITE_SETUP   : prepare the write data and the addr;
    3. ST_WRITE         : write to the ddr2;     
    4. ST_WRITE_EXTEND  : To extend the write request by another clock cycle; read README;
    5. ST_WRITE_WAIT    : wait for the write transaction to complete;
    6. ST_READ_SETUP    : prepare the addr;
    7. ST_READ          : read from the ddr2;
    8. ST_READ_EXTEND   : To extend the read request by another clock cycle; read README;
    9. ST_READ_WAIT     : wait for the read data to be valid;
    10. ST_LED_WAIT      : timer wait for led display;    
    11. ST_GEN           : to generate the next test data;
    */    
    typedef enum{ST_CHECK_INIT, ST_WRITE_SETUP, ST_WRITE, ST_WRITE_EXTEND, ST_WRITE_WAIT, ST_READ_SETUP, ST_READ, ST_READ_EXTEND, ST_READ_WAIT, ST_LED_WAIT, ST_GEN} state_type;
    state_type state_reg, state_next;    
    
    ///// debugging state;
    // to display which state the FSM is in on the led
    // to debug whether the FSM stuck at some point ...
    // enumerate the FSM from 1 to 8;
    logic [3:0] debug_FSM_reg;
    logic [3:0] debug_ctrl_FSM; // FSM of user_mem_ctrl module;
    
    // register to filter the glitch when writing the write data;
    // there is a register within the uut for read data; so not necessary;    
    logic [127:0] wr_data_reg, wr_data_next;
    
    // register to filter addr glitch when issuing;
    logic [22:0] user_addr_reg, user_addr_next;
        
    // counter/timer;
    // 2 seconds led pause time; with 100MHz; 200MHz threshold is required;
    //localparam TIMER_THRESHOLD = 200_000_000;
    //localparam TIMER_THRESHOLD = 100_000_000; // one second;
    //localparam TIMER_THRESHOLD = 10;
    logic [27:0] timer_reg, timer_next;
    
    // traffic generator to issue the addr;
    // here we just simply use incremental basis;
    //localparam INDEX_THRESHOLD = 65536; // wrap around; 2^{16};
    //localparam INDEX_THRESHOLD = 2; // wrap around; 2^{16};
    logic [16:0] index_reg, index_next;
         
    /*-----------------------------------
    * debugging interface
    * to remove for synthesis;
    *-----------------------------------*/        
    /*
    assign debug_wr_strobe = user_wr_strobe;    
    assign debug_rd_strobe = user_rd_strobe; 
    assign debug_rst_sys = rst_sys_sync;
    assign debug_clk_sys = clk_sys;
    //assign debug_rst_sys_stretch = rst_sys_stretch;
    assign debug_rst_sys_stretch = rst_sys_stretch_reg;
    assign debug_rst_mig_stretch_reg = rst_mig_stretch_reg;
    assign debug_rst_sys_raw = rst_sys_raw;
    assign debug_locked = locked;
    assign debug_MIG_user_transaction_complete = MIG_user_transaction_complete;
    */
         
    /*--------------------------------------
    * instantiation 
    --------------------------------------*/
   
    user_mig_DDR2_sync_ctrl uut
    (
        //  from the user system
        // general, 
        .clk_sys(clk_sys_100M),    // 100MHz,        
        .rst_sys(reset_sys),
        
        //  MIG interface 
        // memory system,
        .clk_mem(clk_mem_200M),        // 200MHz to drive MIG memory clock,
        //.rst_mem_n(~rst_sys_stretch_reg),      // active low to reset the mig interface,
                
        .rst_mem_n(~reset_mig),      // active low to reset the mig interface,
        //.rst_mem_n(),      // active low to reset the mig interface,
        
        //interface between the user system and the memory controller,
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
        
        // not used;
        .init_calib_complete(),  // output                                       init_calib_complete
        
        .ddr2_cs_n(ddr2_cs_n),  // output [0:0]           ddr2_cs_n
        .ddr2_dm(ddr2_dm),  // output [1:0]                        ddr2_dm
        .ddr2_odt(ddr2_odt),  // output [0:0]                       ddr2_odt
       
        //  debugging interface (not used)            
        .debug_app_rd_data_valid(),
        .debug_app_rd_data_end(),
        .debug_ui_clk(debug_ui_clk),
        .debug_ui_clk_sync_rst(debug_ui_clk_sync_rst),
        .debug_app_rdy(),
        .debug_app_wdf_rdy(),
        .debug_app_en(),
        .debug_app_wdf_data(),
        .debug_app_wdf_end(),
        .debug_app_wdf_wren(),
        .debug_init_calib_complete(debug_init_calib_complete),
        .debug_transaction_complete_async(debug_transaction_complete_async),
        .debug_app_cmd(),
        .debug_app_rd_data(),        
        .debug_user_wr_strobe_sync(),
        .debug_user_rd_strobe_sync(),
        .debug_FSM(debug_ctrl_FSM)
    );
    
    
    ////////////////////////////////////////////////////////////////////////////////////
    
    
    // ff;
    always_ff @(posedge clk_sys_100M, posedge reset_sys) begin        
        if(reset_sys) begin        
            wr_data_reg <= 0;
            timer_reg <= 0;
            index_reg <= 0;
            state_reg <= ST_CHECK_INIT;
            user_addr_reg <= 0;                                                         
             
        end
        else begin
            wr_data_reg <= wr_data_next;
            timer_reg <= timer_next;
            index_reg <= index_next;
            state_reg <= state_next;
            user_addr_reg <= user_addr_next;                                    
        end
    end
    
    
    // fsm;
    always_comb begin
       // default;
        wr_data_next = wr_data_reg;
        timer_next = timer_reg;
        index_next = index_reg;
        state_next = state_reg;
        user_addr_next = user_addr_reg;
                
        user_wr_strobe = 1'b0;
        user_rd_strobe = 1'b0;
        
        user_addr = user_addr_reg;
        user_wr_data = wr_data_reg;
        
        debug_FSM_reg = 0;
        
        /* 
        state:
        1. ST_CHECK_INIT    : wait for the memory initialization to complete before starting everything else;
        2. ST_WRITE_SETUP   : prepare the write data and the addr;
        3. ST_WRITE         : write to the ddr2;     
        4. ST_WRITE_EXTEND  : To extend the write request by another clock cycle; read README;
        5. ST_WRITE_WAIT    : wait for the write transaction to complete;
        6. ST_READ_SETUP    : prepare the addr;
        7. ST_READ          : read from the ddr2;
        8. ST_READ_EXTEND   : To extend the read request by another clock cycle; read README;
        9. ST_READ_WAIT     : wait for the read data to be valid;
        10. ST_LED_WAIT      : timer wait for led display;    
        11. ST_GEN           : to generate the next test data;
        */        
        
        /* NOTE
        Some states defined above are redundant;
        In fact, the states could be combined to reduce the 
        number of states;...        
        */
            
        case(state_reg)
            ST_CHECK_INIT: begin
                // debugging;
                debug_FSM_reg = 1;
                    
                // important to wait for the memory to be initialized/calibrated;
                // block until it finishes;
                if(MIG_user_init_complete) begin
                    state_next = ST_WRITE_SETUP;
                end
            end      
            
            ST_WRITE_SETUP: begin
                // debugging;
                debug_FSM_reg = 2;
                
                if(MIG_user_ready) begin 
                    // prepare the write data and address and hold them
                    // stable for the upcoming write request;
                    wr_data_next = index_reg;
                    user_addr_next = index_reg;
                    state_next = ST_WRITE; 
               end      
            end
            
            ST_WRITE: begin
                // debugging;
                debug_FSM_reg = 3;

                // MIG is ready to accept new request?
                if(MIG_user_ready) begin                
                    user_wr_strobe = 1'b1;                                    
                    state_next = ST_WRITE_EXTEND;                    
                end
            end
                        
            // add one more clock cycle length to the wr strobe;
            ST_WRITE_EXTEND: begin            
                user_wr_strobe = 1'b1;
                state_next = ST_WRITE_WAIT;
            end
            
            
            ST_WRITE_WAIT: begin
                // debugging;
                debug_FSM_reg = 4;
                
                /* IMPORTANT to NOTE;
                this might a malicious blocking practice;
                if the complete flag is missed ...
                need to figure out some safeguard;
                
                the complete flag is one-system-clock cycle long;
                which is synchronous to this FSM;
                
                so what went wrong ...?
                */
                if(MIG_user_transaction_complete) begin 
                    state_next = ST_READ_SETUP;
                end                                
            end
            
            ST_READ_SETUP: begin
                // debugging;
                debug_FSM_reg = 5;
                if(MIG_user_ready) begin
                    // note that the the address line is already
                    // stable in the default section above; for the upcoming read request;
                    state_next = ST_READ;
                end
            end
            
            ST_READ: begin
                // debugging;
                debug_FSM_reg = 6;
                
                // MIG is ready to accept new request?
                if(MIG_user_ready) begin
                    user_rd_strobe = 1'b1;                    
                    state_next = ST_READ_EXTEND;
                end
            end
                        
            // add one more clock cycle length to the rd strobe;
            ST_READ_EXTEND: begin
                user_rd_strobe = 1'b1;
                state_next = ST_READ_WAIT;            
            end
            
            
            
            ST_READ_WAIT: begin  
                // debugging;
                debug_FSM_reg = 7;
                             
                /* IMPORTANT to NOTE;
                this might a malicious blocking practice;
                if the complete flag is missed ...
                need to figure out some safeguard;
                
                the complete flag is one-system-clock cycle long;
                which is synchronous to this FSM;
                
                so what went wrong ...?
                */
                if(MIG_user_transaction_complete) begin
                    timer_next = 0; // load the timer;
                    state_next = ST_LED_WAIT;
                end                                                
            end 
            
            ST_LED_WAIT: begin
                // debugging;
                debug_FSM_reg = 8;
                
                // do not move on after the timer has expired;
                if(timer_reg == (TIMER_THRESHOLD-1)) begin
                    state_next = ST_GEN;
                end 
                else begin
                    timer_next = timer_reg + 1;
                end           
            end
        
            ST_GEN: begin
                // debugging;
                debug_FSM_reg = 9;
                
                // for now; incremental based;
                index_next = index_reg + 1;
                
                // free running;
                state_next = ST_WRITE_SETUP;
                
                // wraps around after certain threshold;                
                if(index_reg == (INDEX_THRESHOLD-1)) begin
                    index_next = 0;
                end                                            
            end
            
            // should not reach this state;
            default: begin
                state_next = ST_CHECK_INIT;
            end 
        endcase
    end     
    
        
    // led output;   
    // LED[15]; MSB stores the MIG init calibration status;    
    // LED[14] stores the MMCM locked status;
    // LED[13] stores MIG app readiness;
    // LED[12:9] stores the FSM integer representation of the current state of test_top.sv
    // LED[8:5] stores the FSM integer representation of the current state of user_mem_ctrl.sv
    // LED[4:0] stores the read data; 
    assign LED =  {MIG_user_init_complete, MMCM_locked, MIG_user_ready, debug_FSM_reg, debug_ctrl_FSM, user_rd_data[4:0]};
endmodule

