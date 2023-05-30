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
                
        // user system reset signal; active HIGH     
        input logic reset_sys,                                 
            
        // LEDs;
        output logic [15:0] LED,        
        
        // for LED display;        
        input logic MMCM_locked,  // mmcm locked status; 
                 
                
        /*-------------------------------------------------------
        * to communicate with the MIG synchronous interface
        -------------------------------------------------------*/
        // user signals;
        output logic user_wr_strobe,            // write request;
        output logic user_rd_strobe,             // read request;
        output logic [22:0] user_addr,           // address;
        
        // data;
        output logic [127:0] user_wr_data,       
        input logic [127:0] user_rd_data,  
        
        // status
        input logic MIG_user_init_complete,        // MIG done calibarating and initializing the DDR2;
        input logic MIG_user_ready,                // this implies init_complete and also other status; see UG586; app_rdy;
        input logic MIG_user_transaction_complete, // read/write transaction complete?
        
        // MIG controller FSM is in idle state (not busy) (implies user_transaction_complete);
        ///// IMPORTANT: there is a three system (100MHz) clock delay after write/read strobe is asserted;
        //input logic MIG_ctrl_status_idle,          
        
        // debugging port;
        input logic [3:0] debug_ctrl_FSM // FSM of user_mig_DDR2_sync_ctrl module;
                   
    );
            
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
    
    // register to filter the glitch when writing the write data;
    // there is a register within the uut for read data; so not necessary;    
    logic [127:0] wr_data_reg, wr_data_next;
    
    // register to filter addr glitch when issuing;
    logic [22:0] user_addr_reg, user_addr_next;
        
    // counter/timer;
    // N seconds led pause time; with 100MHz; 200MHz threshold is required;
    logic [27:0] timer_reg, timer_next;
    
    // traffic generator to issue the addr;
    // here we just simply use incremental basis;
    logic [16:0] index_reg, index_next;
    
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

