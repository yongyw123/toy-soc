`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 01:33:15
// Design Name: 
// Module Name: dcmi_decoder
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
purpose         : decoding logic for OV7670 camera;
what to decode  : OV7670 synchronization signals;
caution         : this interface is driven by the OV7670 camera clock (PCLK);
                so, this is asynchronous; need a dual-clock fifo
                for cross-clock domain;
                
assumption      : assume camera synchronization signal settings are fixed; 
               
OV7670 setting:
1. Resolution: QVGA (320 x 240);
2. Format: RGB565 or YUV422                           
3. Bits per pixel: 16-bit;

OV7670 Synchronization Setting;
1. PCLK     : 24 MHz;
2. HREF     : changes at the falling edge of PCLK;
   HREF     : active high (low during idle);
3. VSYNC    : chnages at the falling edge of PCLK;
   VSYNC    : active high (low during idle);
4. DATA     : updated by OV7670 at the falling edge of PCLK;
   DATA     : changes simultaneously with HREF (no delay after HREF changes);
   
Rough Construction:
1. By above, we use VSYNC to detect the start and the end of a frame;
2. Use HREF signal to start the Data sampling;
3. Data sampling occurs at the rising edge of PCLK;

Frame Timing;
1. Refer to the Datasheet;
2. define:
    vlow    : the time period when the VSYNC is LOW (during idle);
    hlow    : the time period when the HREF is low during idle;
2. define;
    tpclk   : the time period of PCLK;
    tp      : if YUV/RGB, tp = 2*tpclk; 
    tline   : a constant: tline = 624*tp (approx.)

4. we have:
    tpclk   : 41.67 ns
    vlow    : at least, 3*tline = 2496*tpclk;
    hlow    : at least, 2*144*tp = 244*tpclk;  
*/

module dcmi_decoder
    #(parameter 
        DATA_BITS           = 8, // camera ov7670 drives 8-bit parallel data;
        HREF_COUNTER_WIDTH  = 8,  // to count href;
        HREF_NUM            = 240, // expected to have 240 href for a line;
        FRAME_COUNTER_WIDTH = 32    // count the number of frames;        
     )
    (
        // general;
        input logic reset_sys,    // async from the system (not camera);
        
        // cpu command;
        input logic cmd_start,
        
        // driving inputs from the camera ov7670;
        input logic pclk,  // fixed at 24MHz;
        input logic href,
        input logic vsync,
        input logic [DATA_BITS-1:0] din,
        
        // interface the dual-clock fifo;
        /* note;
        expect that consuming (fpga) rate is higher than the supplying (camera) rate;
        underrun yes; but should not overrun the fifo; 
        */
        output logic data_valid,             // to the fifo;
        input logic data_ready,              // from the fifo; (not used by above)
        output logic [DATA_BITS-1:0] dout   // sampled pixel data from the cam;               
    );
    
    /* signal declaration */
    logic [DATA_BITS-1:0] sampled_reg;          // to sample din for dout;        
    logic detect_vsync_edge;                    // to detect rising edge of the vsync;    
    
    // enable signales;
    logic sample_en;
        
    // registers;
    logic [HREF_COUNTER_WIDTH-1:0] cnt_href_reg, cnt_href_next;     // count #href;
    logic [FRAME_COUNTER_WIDTH-1:0] cnt_frame_reg, cnt_frame_next;  // count #frame;
    
    // states;
    /*
    ST_IDLE         : doing nothing; waiting for user command to start the dcmi decoder;
    ST_WAIT_VSYNC   : waiting for the rising edge of vsync;
    ST_WAIT_HREF    : waiting for the HREF to assert;
    ST_CHECK_HREF   : check for HREF to deassert;
    */ 
    typedef enum{ST_IDLE, ST_WAIT_VSYNC, ST_WAIT_HREF, ST_CHECK_HREF} state_type;
    state_type state_reg, state_next;
    
    // ff;
    always_ff  @(posedge pclk, posedge reset_sys) begin
        if(reset_sys) begin
            state_reg       <= ST_IDLE;            
            cnt_href_reg    <= 0;
            cnt_frame_reg   <= 0;
            sampled_reg     <= 0;       // dummy;
        end
        else begin
            state_reg       <= state_next;
            cnt_href_reg    <= cnt_href_next;
            cnt_frame_reg   <= cnt_frame_next;
            sampled_reg     <= din;            
        end    
    end
    
    /*  output; */    
    // this is only asserted when the frame start is detected and href is asserted;
    assign data_valid   = sample_en;  
    assign dout         = sampled_reg;
    
    /* other helper unit: edge detector */
    rising_edge_detector 
    edge_unit
    (
        .clk(pclk),
        .reset(reset_sys),
        .level(vsync),
        .detected(detec_vsync_edge)
    );

    /*  fsm; */    
    always_comb begin
        // default;
        state_next = state_reg;                
        sample_en = 1'b0;
        
        case(state_reg)
            ST_IDLE: begin
                if(cmd_start) begin
                    state_next = ST_WAIT_VSYNC;
                    // reset the frame counter;
                    cnt_frame_next = 0;
                end            
            end
            
            ST_WAIT_VSYNC: begin
                if(detect_vsync_edge) begin
                    // reload the counter for href;
                    cnt_href_next = 0;
                    state_next = ST_WAIT_HREF;
                end
            end
        
            ST_WAIT_HREF: begin
                if(href) begin
                    state_next = ST_CHECK_HREF;
                end            
            end
          
            ST_CHECK_HREF: begin
                sample_en = 1'b1;
                // href deasserted == data not valid;
                if(!href) begin
                    state_next = ST_WAIT_HREF;
                    // one href is done;
                    cnt_href_next = cnt_href_reg + 1;
                    // check if a frame is completed;
                    if(cnt_href_reg == HREF_NUM) begin
                        cnt_frame_next = cnt_frame_reg + 1;
                    end
                end                
            end
        default: ; // nop
        endcase    
    end
endmodule