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


construction/documenation;
?? tba ??

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
        input logic [31:0] set_wr_mod,     // set the write cycle time;
        input logic [31:0] set_rd_mod,     // set the read cycle time;
        
        // user argument;      
        input logic user_start,            
        input logic user_cmd,       // read or write;
        
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
    
    // states;
    typedef enum{
        ST_IDLE,    // no activity;
        ST_FHALF,   // the amount of time wrx is low;
        ST_SHALF    // the amount of time wrx is high;
    }state_type;
    
    // registers;
    state_type state_reg, state_next;
    logic [31:0] clk_cnt_reg, clk_cnt_next; // to track the wr/rd clock cycle;
    //logic [PARALLEL_DATA_BITS-1:0] data_reg, data_next; // buffer dinout;
    
    // ff;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            state_reg <= ST_IDLE;
            clk_cnt_reg <= 0;
            //data_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            clk_cnt_reg <= clk_cnt_next;                     
        end          
    
    // fsm;
    always_comb
    begin
        // flag; default to low; 
        ready_flag = 1'b0;
        done_flag = 1'b0;
        
        // remain high if there is no activity;
        drive_wrx = 1'b1;   
        
        // default;
        state_next = state_reg;
        clk_cnt_next = clk_cnt_reg;
        
        case(state_reg)
            ST_IDLE:
            begin
                ready_flag = 1'b1;
                done_flag = 1'b1;
                if(user_start) begin
                    clk_cnt_next = 0;
                    state_next = ST_FHALF;
                end
            end
            
            ST_FHALF:
            begin
                drive_wrx = 1'b0;
                if(clk_cnt_reg == set_wr_mod) begin
                    state_next = ST_SHALF;
                    clk_cnt_next = 0;
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            end
            
            ST_SHALF:
            begin
                drive_wrx = 1'b1;
                if(clk_cnt_reg == set_wr_mod) begin
                   state_next = ST_IDLE;
                   clk_cnt_next = 0;
                   done_flag = 1'b1;
                end
                else
                    clk_cnt_next = clk_cnt_reg + 1;
            end
            default: ; // nop;
        endcase        
    end
endmodule