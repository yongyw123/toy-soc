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
    tline   : a constant: tline = 784*tp;

4. we have:
    tpclk   : 41.67 ns
    vlow    : 3*tline = 4704*tpclk;
    hlow    : at least >= 2*144*tp = 244*tpclk;  
*/

module dcmi_decoder
    #(parameter 
        DATA_BITS = 8,          // camera ov7670 drives 8-bit parallel data;
        COUNTER_WIDTH = 10,     // for debugging;
        HREF_NUM = 240          // expected to have 240 href for a line;        
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
        output logic [DATA_BITS-1:0] dout,   // sampled pixel data from the cam;
        
        // for debugging;
        output logic [COUNTER_WIDTH:0] cnt_vsync,
        output logic [COUNTER_WIDTH:0] cnt_href,
        output logic [COUNTER_WIDTH:0] cnt_frame
    );
    
    /* signal declaration */
    logic [DATA_BITS-1:0] sampled_reg;          // to sample din for dout;
    logic href_en;                              // to AND with user command;    
    logic detect_vsync_edge;                    // to detect rising edge of the vsync;
    logic detect_href_edge;                     // to detect the rising edge of href;
    
    // counters;
    logic [COUNTER_WIDTH:0] cnt_href_reg, cnt_href_next;
    logic [COUNTER_WIDTH:0] cnt_vsync_reg, cnt_vsync_next;
    
    always_ff @(posedge pclk, posedge reset_sys)       
    begin 
        if(reset_sys) begin
            sampled_reg <= {DATA_BITS{1'b1}}; // dummy;
            
            // counters;
            cnt_href_reg <= 0;
            cnt_vsync_reg <= 0;
        end
        else begin
            // counters;
            
            if(detect_vsync_edge) begin
                cnt_vsync_reg <= cnt_vsync_next;    
            end
            
            // only start counting when start of frame (vsyncs) is asserted;
            if((detect_href_edge) && (cnt_vsync_reg > 0)) begin
                cnt_href_reg <= cnt_href_next;
            end 
            
            // only start sampling when start of frame is detected;
            // then, sample as long as href is active high;
            // this always holds since href == data valid by the datasheet;
            if((cnt_vsync_reg > 0) && (href_en)) begin
                sampled_reg <= din;    
            end        
        end
    end
    
   /* instantiation of rising edge detector for the relevant signals */
   // rising edge detector for vsync;
   rising_edge_detector vsync_unit
   (
    .clk(pclk),
    .reset(reset),
    .level(vsync),
    .detected(detect_vsync_edge)
   );
   
   // rising edge detector for href;
   rising_edge_detector href_unit
   (
    .clk(pclk),
    .reset(reset),
    .level(vsync),
    .detected(detect_href_edge)
   );
   
   
   /* next state for the counter */
   // for vsync; the second vsync is the end of frame; wrap around;
   assign cnt_vsync_next    = (cnt_vsync_reg == 1) ? 0 : cnt_vsync_reg + 1;
   // for href; it is mod 240 since the camera will output 240 href per line; 
   assign cnt_href_next     = (cnt_href_reg == HREF_NUM) ? 0 : cnt_href_reg + 1;
   
    // do not start sampling even if href is high 
    // unless user instructs to do so and the start of frame is detected;
   assign href_en = (href && cmd_start && (cnt_vsync_reg > 0));
   assign data_valid = (href_en) ? 1'b1 : 1'b0;
   
   // outputs;
   assign dout = sampled_reg;
   
endmodule
