`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2023 01:46:01
// Design Name: 
// Module Name: lcd_8080_interface_controller
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
purpose             : LCD interface controller
device              : LCD-TFT ILI9341
interface protol    : MCU 8080-I series 
datasheet           : https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf

device pin;
1. hw reset;    not included here; could be emulated using gpo/gpio pin;
2. chip select; not included here; same reason as above;
3. write; driven by the host to the lcd;           
4. read;  driven by the host to the lcd;
5. data-or-command (DC); low for command; not included here, emulated;
6. output data-parallel bit;    this is bidirectional (shared between the host and the lcd); 
                        so should be tristate;
                                               
write operation;
1. at the falling edge, output data should be ready;
2. at the rising edge, lcd will sample this data;
3. specs say low and high time are 15 ns;
4. so, here, we shall support minimum 20 ns;

read operation;
1. similar to the write operation;
2. however, it is the host that drives the read signal;
2. at falling edge, the lcd prepares its output and put it on the data line;
4. at the rising edge, the host should sample the data on the data line;
5. specs say the reading time is not uniform depending on the data to read;
6. as such, for now, the module shall not implement the read operation for the time being;

construction;
1. by above, this is a parallel interface, relatively easier than serial interface;
2. for both write and read op, one needs to make sure the WRX/RDX respect the setup and hold time;
3. tricky bit, for reading, the timing are different (longer), and different for LOW part and HIGH part of
    of the read clock cycle;

assumption;
1. by above, write minimum time is 60ns for one write clock cycle;
2. read minimum is 100 ns for LOW and 400 ns for HIGH within one read clock cycle;

*/


module lcd_8080_interface_controller
    #(parameter
        PARALLEL_DATA_BITS = 8  // how many data bit to drive in parallel?
     )
    (
        /* general */
        input logic clk,    // system clock; 100 MHz;
        input logic reset,  // async;
        
        /* lcd interface */
        
        /* note;
        as in the construction;
        there is some constraint imposed on this mod setting;
        but shall leave it to the SW to handle;
        */
        
        // set the write cycle time;
        input logic [15:0] set_wr_mod_fhalf,    // first half of the write clock;     
        input logic [15:0] set_wr_mod_shalf,    // second half of the write clockl
        
        // set the read cycle time;
        input logic [15:0] set_rd_mod_fhalf,    // first halfl;
        input logic [15:0] set_rd_mod_shalf,    // first halfl;

        // user argument;      
        input logic user_start,     // start communicating with the lcd;        
        input logic [1:0] user_cmd,       // read or write?
        
        input logic [PARALLEL_DATA_BITS-1:0] wr_data,   
        output logic [PARALLEL_DATA_BITS-1:0] rd_data,

        // status;
        output logic ready_flag,    // idle;
        output logic done_flag,     // just finish the rd/wr operation;
        
        /* hw pins 
        note that there are other hw pins not listed here;
        dcx, rst, and cs;
        these pins could be configured as general pins;
        not necessary to integrate here;       
        */
        output logic drive_wrx,   //  to drive the lcd for write op;
        output logic drive_rdx,   // to drive the lcd for read op;          
        inout tri[PARALLEL_DATA_BITS-1:0] dinout // this is shared between the host and the lcd;
    );
    
    // command constanst;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
    
    /* states;
    write and read could share the same states;
    but for clarity, shall separate;
    */
    typedef enum{
        ST_IDLE,    // no activity;
        
        // the first half time of the write clock cycle wrx spends on;
        // this is where the host should have already update the data for
        // the lcd to sample during the second half;
        ST_FHALF_W,   
        // the second half time of the write clock cycle wrx spends on;
        // lcd sampling;
        ST_SHALF_W,
        
        // similar to those is write;
        // except the role is reversed;
        // the host samples the lcd data on the second half;
        ST_FHALF_R,
        ST_SHALF_R
            
    }state_type;
    
    // registers;
    state_type state_reg, state_next;
    logic [31:0] clk_cnt_reg, clk_cnt_next; // to track the wr/rd clock cycle;
    logic [PARALLEL_DATA_BITS-1:0] wr_data_reg, wr_data_next; // to buffer to wr_data;
    logic [PARALLEL_DATA_BITS-1:0] rd_data_reg, rd_data_next; // to sample lcd data;
    logic [1:0] cmd_reg, cmd_next; // to store the user commands;
    
    // enabler signals;
    logic set_hiz;      // to determine when will the bidirec line is hiZ or not;

    // ff;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            state_reg <= ST_IDLE;
            clk_cnt_reg <= 0;
            wr_data_reg <= {PARALLEL_DATA_BITS{1'b1}};       // the data means nothing without wrx siignals'
            rd_data_reg <= {PARALLEL_DATA_BITS{1'b1}};       // again, means nothing without the rdx  signal;
            cmd_reg <= CMD_NOP;    // nop;
        end
        else begin
            state_reg <= state_next;
            clk_cnt_reg <= clk_cnt_next;
            //if(user_start) begin
            //wr_data_reg <= wr_data_next;
            wr_data_reg <= wr_data_next;
            rd_data_reg <= rd_data_next;
            cmd_reg <= cmd_next;
            
        //end                   
        end          
    
    // fsm;
    always_comb
    begin
        // flag; default to low; 
        ready_flag = 1'b0;
        done_flag = 1'b0;
        
        // remain high if there is no activity;
        drive_wrx = 1'b1;   
        drive_rdx = 1'b1;
           
        // default;
        state_next = state_reg;
        clk_cnt_next = clk_cnt_reg;
        wr_data_next = wr_data_reg;
        rd_data_next = rd_data_reg;
        cmd_next = cmd_reg;
        
        
        case(state_reg)
            ST_IDLE:
            begin
                ready_flag = 1'b1;
                done_flag = 1'b1;
                cmd_next = user_cmd;
                if(user_start && (user_cmd != CMD_NOP)) begin
                    // load the counter for the next state;
                    clk_cnt_next = 0;
                    // determine which command
                    case(user_cmd)
                        CMD_WR: begin
                            state_next = ST_FHALF_W;
                            wr_data_next = wr_data;
                        end
                        CMD_RD: 
                            state_next = ST_FHALF_R;
                        default: 
                            state_next = ST_IDLE;
                    endcase
                   
                end
            end
            
            ST_FHALF_W:
            begin
                drive_wrx = 1'b0;
                if(clk_cnt_reg == set_wr_mod_fhalf) begin
                    state_next = ST_SHALF_W;
                    clk_cnt_next = 0;   // reset for the next statel
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            end
            
            ST_SHALF_W:
            begin
                // the lcd will start sampling here at low to high transition here;
                // hold it;
                drive_wrx = 1'b1;
                if(clk_cnt_reg == set_wr_mod_shalf) begin
                   state_next = ST_IDLE;
                   clk_cnt_next = 0;
                   done_flag = 1'b1;
                   
                   /* signal ahead so that
                    that the host could start setting up
                    its data before the state here transits
                    to ST_IDLE
                    
                    is this a good idea?
                    */
                    //ready_flag = 1'b1;
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            end
                 
            ST_FHALF_R:
            begin
            /* 
            pull down the rdx line to allow the lcd to prepare;
            expect the lcd to output its data in the seonc half
            */
                drive_rdx = 1'b0;
                if(clk_cnt_reg == set_rd_mod_fhalf) begin
                    state_next = ST_SHALF_R;
                    clk_cnt_next = 0;   // reset for the next statel
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            
            end
            
            ST_SHALF_R:
            begin
                /*
                    expect the lcd data to be ready;
                    sample it;
                */
                drive_rdx = 1'b1;
                rd_data_next = dinout;
                if(clk_cnt_reg == set_rd_mod_shalf) begin
                    state_next = ST_IDLE;
                    clk_cnt_next = 0;   // reset for the next statel
                    done_flag = 1'b1;
                    
                    /* signal ahead so that
                    that the host could start setting up
                    its data before the state here transits
                    to ST_IDLE
                    
                    is this a good idea?
                    */
                    //ready_flag = 1'b1;
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            
            end

            default: ; // nop;
        endcase        
    end
  
    // logic;
    assign set_hiz = (cmd_reg == CMD_RD);   
    assign dinout = (set_hiz) ? {PARALLEL_DATA_BITS{1'bz}} : wr_data_reg;
    
    // output;
    assign rd_data = rd_data_reg; 
        
    
endmodule
