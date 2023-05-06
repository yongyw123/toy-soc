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
        HREF_TOTAL          = 240, // expected to have 240 href for a line;
        FRAME_COUNTER_WIDTH = 32    // count the number of frames;        
     )
    (
        // general;
        input logic reset_sys,    // async from the system (not camera);
        
        // cpu command;
        input logic cmd_start,
        input logic sync_clr_frame_cnt, // clear the frame counter, synchronously;
        
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
        output logic [DATA_BITS-1:0] dout,   // sampled pixel data from the cam;
        
        // debugging;
        output logic debug_detect_vsync_edge,
        
        // status
        output logic decoder_ready_flag,    // is the decoder idle?
        output logic [FRAME_COUNTER_WIDTH-1:0] decoder_frame_counter, // this will overflow;
        output logic decoder_complete_tick, // when the entire frame has been decoded;
        output logic decoder_start_tick     // when a new frame is detected;               
    );
    
    /* signal declaration */
    //logic [DATA_BITS-1:0] sampled_reg;          // to sample din for dout;        
    logic detect_vsync_edge;                    // to detect rising edge of the vsync;    
    assign debug_detect_vsync_edge = detect_vsync_edge;
     
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
            //sampled_reg     <= 0;       // dummy;
        end
        else if(sync_clr_frame_cnt) begin
            cnt_frame_reg   <= 0;
        end
        else begin
            state_reg       <= state_next;
            cnt_href_reg    <= cnt_href_next;
            
            // this will forever add up until overflow or reset;
            cnt_frame_reg   <= cnt_frame_next;
            //sampled_reg     <= din;            
        end    
    end
    
    /*  output; */    
    /* when is the data valid for the sinking fifo to accept new pixel data? */
    // this is only asserted when the frame start is detected and href is asserted;
    // it is unlikely to have the sink not ready since the sink (consuming)
    // rate is 100Mhz; higher than the camera output rate (24MHz)?
    assign data_valid   = (sample_en && href && data_ready);  
    //assign dout         = sampled_reg;
    
    /* just pass it through the data from the camera directly;
    this is ok since the sinking fifo will only 
    accept at the assertion of data valid */
    assign dout = din;
    
    /* other helper unit: edge detector */
    rising_edge_detector 
    edge_unit
    (
        .clk(pclk),
        .reset(reset_sys),
        .level(vsync),
        .detected(detect_vsync_edge)
    );

    /*  fsm; */    
    always_comb begin
        // default;
        state_next = state_reg;
        cnt_frame_next = cnt_frame_reg;
        cnt_href_next = cnt_href_reg;
        
        sample_en = 1'b0;
       
        decoder_ready_flag      = 1'b0;   
        decoder_complete_tick   = 1'b0;
        decoder_start_tick      = 1'b0;
        
        case(state_reg)
            ST_IDLE: begin
                decoder_ready_flag = 1'b1;
                if(cmd_start) begin
                    state_next = ST_WAIT_VSYNC;                    
                end            
            end
            
            ST_WAIT_VSYNC: begin
                if(detect_vsync_edge) begin
                    // reload the counter for href;
                    cnt_href_next = 0;
                    state_next = ST_WAIT_HREF;
                    // flag it;
                    decoder_start_tick = 1'b1;
                end
            end
        
            ST_WAIT_HREF: begin
                if(href) begin
                    // need to assert here the moment href is asserted;
                    // otherwise it will only change at the next
                    // rising edge of pclk;
                    // which is undesirable since it could
                    // mean that other input is clocked to the sink
                    // register at this edge, if not becareful;
                    sample_en = 1'b1;
                    
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
                    if(cnt_href_reg == (HREF_TOTAL-1)) begin
                        cnt_frame_next = cnt_frame_reg + 1;
                        // done;
                        state_next = ST_IDLE;
                        
                        // flag it;
                        decoder_complete_tick = 1'b1;
                        
                    end
                end                
            end
        default: ; // nop
        endcase    
    end
    
    // output;
    assign decoder_frame_counter = cnt_frame_reg;
     
endmodule
