`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.04.2023 15:48:35
// Design Name: 
// Module Name: i2c_controller
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
purpose: i2c master controller;
assumption;
1. only one master (so no arbitration);
2. no clock stretching;

construction;
1. please see this doc linked below
https://docs.google.com/document/d/1ry1kXqD7P2slyMiV86lYMIhMr_kSJ_o6/edit?usp=share_link&ouid=109361905057067991130&rtpof=true&sd=true

*/
module i2c_master_controller
    #(parameter
        I2C_CLK_WIDTH = 32,       // for i2c clock counter;
        I2C_TOTAL_CMD_NUM = 3,   // number of i2c command: start, stop, repeat_start etc..?
        I2C_DATA_BIT = 8
     )
    (
        /* general; */
        input logic clk,    // 100 Mhz;
        input logic reset,  // async;
        
        /* i2c specific */
        // user input;
        input logic [I2C_CLK_WIDTH-1:0] cnt_mod,    // counter modulus;
        input logic [I2C_TOTAL_CMD_NUM-1:0] user_cmd,    // what command: stop, start,?
        input logic wr_i2c_start,                   // initiate the i2c master;
        input logic [I2C_DATA_BIT-1:0] din,             // i2c write data;
        
        // user output;
        output logic ready_flag,    // idle;
        output logic done_flag,     // just finish i2c communications;
        output logic ack_flag,      // from slave for processing to determine if slave has ack;
        output logic [I2C_DATA_BIT-1:0] dout,   // slave data;
        
        // i2c actual hw pins;
        // must be tristate by i2c construction/specs;
        output tri scl, // clock is always initiated by the master;
        inout tri sda   // this line is shared between master and slaves;
    );
    
    // misc constants;
    localparam DATA_BIT_W = $clog2(I2C_DATA_BIT);
    
    // command constants;
    localparam CMD_START    = 3'b000;   // generate start condition;
    localparam CMD_WR       = 3'b001;   // master write to slave;
    localparam CMD_RD       = 3'b010;   // master reads from slave;
    localparam CMD_STOP     = 3'b011;   // generate stop condition;
    localparam CMD_REPEAT   = 3'b100;   // generate repeated_start condition;
        
    /* state;
    the state definitions are
    defined in the linked doc above;
    */
    typedef enum{
        // i2c is free;
        ST_IDLE,    
        
        // roughly when SCL and SDA must hold low after start, and prior to stop;
        ST_HOLD,
        
        // start phases 
        ST_START_01,
        ST_START_02,
        
        // actual data phases;
        ST_DATA_01,
        ST_DATA_02,
        ST_DATA_03,
        ST_DATA_04,
        
        // stop phases;
        ST_STOP_01,
        ST_STOP_02,
        
        // end condition;
        ST_DATA_END,
        
        // repeat start condition
        ST_REPEAT
    }state_type;
    
    /* signals; */
    state_type state_reg, state_next;
    logic [I2C_CLK_WIDTH-1:0] clk_cnt_reg, clk_cnt_next;    // scl clock counter;

    // scl clock period divided to the four (quarter) phases of the data; 
    logic [I2C_CLK_WIDTH-1:0] phase_quarter;     
    
    // scl clock period divided to the two (half) phases of the start, end; 
    logic [I2C_CLK_WIDTH-1:0] phase_half;
    
    // registers;
    logic [I2C_TOTAL_CMD_NUM-1:0] cmd_reg, cmd_next;    // to store the user command;
    logic [I2C_DATA_BIT-1:0] tx_reg, tx_next;   // master write to slave;
    logic [I2C_DATA_BIT-1:0] rx_reg, rx_next;  // slave to master;
    logic [DATA_BIT_W-1:0]  data_cnt_reg, data_cnt_next;   // track the number of data bits
    logic sda_reg, sda_next;    // to control sda line;
    logic scl_reg, scl_next;    // to control scl line;
    
    // indication and status;
    logic phase_data;   // to track which data phase we are in to determine wr, rx actions;
    logic sda_hiz;      // when to set sda line high impedance;
    logic nack;         // to stop reading;
    
    // ff;
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            state_reg <= ST_IDLE;   
            clk_cnt_reg <= 0;
            cmd_reg <= CMD_START;
            tx_reg <= 0;
            rx_reg <= 0;
            data_cnt_reg <= 0;
            sda_reg <= 0;
            scl_reg <= 0;
        end
        
        else
        begin
            state_reg <= state_next;   
            clk_cnt_reg <= clk_cnt_next;
            cmd_reg <= cmd_next;
            tx_reg <= tx_next;
            rx_reg <= rx_next;
            data_cnt_reg <= data_cnt_next;
            sda_reg <= sda_next;
            scl_reg <= scl_next;
        end
    end 
    
    // fsm;
    always_comb
    begin
        // in all states followed clock counter will be incremented;
        // so might as well do it here;
        clk_cnt_next = clk_cnt_reg + 1;
        
        // remain as it is until told otherwise;
        state_next = state_reg;
        cmd_next = cmd_reg;
        tx_next = tx_reg;
        rx_next = rx_reg;
        data_cnt_next = data_cnt_reg;
        sda_next = sda_reg;
        scl_next = scl_reg;
    
        /* i2c lines;
        recall that i2c lines must have pull resistor;
        so, in the case where we set them to hiz;
        it will be pull up to high, seen by both master and
        slave;
        
        also recall, if both lines are high, then i2c is idle;
        so, make this explicit
        */
        scl_next = 1'b1;
        sda_next = 1'b1;
        
        // output status;
        ready_flag = 1'b0;   // unless told otherwise;
        done_flag = 1'b0;
        
        // start the main machinery;
        case (state_reg)
            ST_IDLE:
            begin
                ready_flag = 1'b1;
                if(wr_i2c_start && user_cmd == CMD_START) 
                begin
                    state_next = ST_START_01;
                end
            end
            
            ST_START_01:
            begin
                // note there, scl is high;
                // so a low sda means a start condition;
                scl_next = 1'b1;
                sda_next = 1'b0;    
                // by the doc, start has two phases;
                // each phase spends half of the scl clk period;
                if(clk_cnt_reg == phase_half)
                begin
                    state_next = ST_START_02;
                    // reset the counter;
                    clk_cnt_next = 0;
                end
            end
            
            ST_START_02:
            begin
               // second phase of the start;
               // in this phase, both lines are low;
                scl_next = 1'b0;
                sda_next = 1'b0;
                // check if the start phase expires;
                if(clk_cnt_reg == phase_half)
                begin
                    // by i2c spec;
                    // there is a hold period
                    // before processing the data, repeat or stop;
                    state_next = ST_HOLD;
                    clk_cnt_next = 0;
                end
            end
            
            ST_HOLD:
            begin
                // hold state is defined when both signals
                // to be low just after start state OR
                // just prior to entering stop state;
                ready_flag = 1'b1;  // hold state is not doing any meaningful stuff;
                sda_next = 1'b0;
                scl_next = 1'b0;
                // check whether the user wants to start a i2c communication;
                if(wr_i2c_start)
                begin
                    // store the command
                    // so that mainly, write or read could be distinguished;
                    cmd_next = user_cmd;
                    
                    // reset for the next phase;                    
                    clk_cnt_next = 0;
                    
                    // determine what the user wnats;
                    case(user_cmd)
                        // read and write are processed simultaneously in the data phases;
                        CMD_WR:
                        begin
                            state_next = ST_DATA_01;
                            data_cnt_next = 0;  // prepare to start counting;
                            tx_next = {din, nack};
                        end
                        CMD_RD:
                        begin
                            state_next = ST_DATA_01;
                            data_cnt_next = 0;  // prepare to start counting;
                            tx_next = {din, nack};
                        end
                        
                        CMD_REPEAT:
                            state_next = ST_REPEAT;
                        CMD_START:
                            state_next = ST_REPEAT;
                        
                        CMD_STOP:
                            state_next = ST_STOP_01;
                        
                        default: state_next = ST_DATA_01;
                    endcase 
                end
            end
            
            ST_DATA_01:
            begin
                // master should set up the tx data by now;
                // when the scl is still low;
                sda_next = tx_reg[8];
                scl_next = 1'b0;
                // indicate
                phase_data = 1'b1;
                // each data phase spends a quarter of the scl clock period;
                
            
            end 
        endcase
    end
    
    // output;
        
    
     
    
     
         
    
endmodule

