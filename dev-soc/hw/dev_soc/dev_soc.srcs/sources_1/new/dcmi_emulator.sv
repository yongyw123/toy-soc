`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 15:35:30
// Design Name: 
// Module Name: dcmi_emulator
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
purpose : this emulates the OV7670 synchronization drivers;
why     : this is to simulate the signals for the dcmi_decoder module;

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

/* assumption;
1. 24MHz pclk cannot be emulated using 100Mhz system clock;
2. instead, we shall emulate 25Mhz;
3. also, the timing parameters above will not be emulated exactly;
    instead, dummy values are replaced;
    for example; instead of having vlow as 2496*pclk; we have 10*pclk;
    nonetheless; we shall respect the relative difference among
    different timing parameters;
*/

module dcmi_emulator
    #(parameter 
    DATA_BITS = 8, // camera could only transmit 8-bit in parallel at at time;
    
    // dcmi sync;
    PCLK_MOD            = 4,    // 100/4 = 25;
    VSYNC_LOW           = 10,   //vlow;
    HREF_LOW            = 5,    // hlow; 
    BUFFER_PERIOD       = 7,    // between vsync assertion and href assertion;
    HREF_TOTAL          = 240,  // total href assertion to generate;
    PIXEL_BYTE_TOTAL    = 640   // 320 pixels per href with bp = 16-bit; 
    
    )
    (
        input logic clk_sys,    // 100 MHz;
        input logic reset_sys,  // async;
        
        // user command;
        input logic start,
        
        // output; sycnhronization signals + dummy pixel data byte;
        output logic pclk,  // fixed at 25 MHz (cannot emulate 24MHz using 100MHz clock);
        output logic vsync, 
        output logic href,
        output logic [DATA_BITS-1:0] dout        
    );
    
    // state;
    typedef enum{ST_IDLE, ST_VSYNC, ST_BUFFER, ST_HREF_ACTIVE, ST_HREF_REST, ST_BUFFER_END} state_type;
    state_type state_reg, state_next;
      
    // registers;
    logic [3:0] cnt_pclk_reg, cnt_pclk_next;        // simulate 25 pclk from 100Mhz system clock;    
    logic [31:0] vsync_low_reg, vsync_low_next;             // simulate vsync low period before becoming active;
    logic [31:0] href_cnt_reg, href_cnt_next;       // count how many href asserted so far; should match with HREF_TOTAL;
    logic [31:0] href_low_reg, href_low_next;       // simulate href low period in between data valid;
    logic [31:0] buffer_reg, buffer_next;           // simulate buffer zone after vsync is asserted but before href asserted;
    logic [31:0] pixel_byte_reg, pixel_byte_next;   // simulate pixel out in 8-bit;
    
    // simulate the pclk;
    always_ff @(posedge clk_sys, posedge reset_sys) begin
        if(reset_sys) begin
            cnt_pclk_reg <= 0;        
        end
        else begin
             cnt_pclk_reg <= cnt_pclk_next;        
        end    
    end
    
    assign cnt_pclk_next = (cnt_pclk_reg == PCLK_MOD-1) ? 0 : (cnt_pclk_reg + 1);
    always_comb begin
        pclk = 1'b0;
        if(cnt_pclk_reg < 2)
            pclk = 1'b1;
        else
            pclk = 1'b0;
    end
    
    // simulate other synchronization signals based on the pclk;
    // prepare all signals at the falling edge of the pclk;
    
    always_ff @(negedge pclk, posedge reset_sys) begin
        if(reset_sys) begin
            vsync_low_reg   <= 0;
            href_cnt_reg    <= 0;
            href_low_reg    <= 0;        
            buffer_reg      <= 0;
            pixel_byte_reg  <= 0;
            state_reg       <= ST_IDLE;
        end
        else begin
            vsync_low_reg   <= vsync_low_next;
            href_cnt_reg    <= href_cnt_next;
            href_low_reg    <= href_low_next;
            buffer_reg      <= buffer_next;
            pixel_byte_reg  <= pixel_byte_next;
            state_reg       <= state_next;                    
        end
    
    end
    
    always_comb begin
        // default;
        vsync   = 1'b1;    
        href    = 1'b0;    // active high;
        
        vsync_low_next  = vsync_low_reg;
        href_cnt_next   = href_cnt_reg;
        href_low_next   = href_low_reg;
        buffer_next     = buffer_reg;
        pixel_byte_next = pixel_byte_reg;
        state_next      = state_reg;
        
        case(state_reg)
            ST_IDLE: begin
                if(start) begin
                    state_next = ST_VSYNC;
                    vsync_low_next = 0;     // reload the counter;
                end
           end
                
            ST_VSYNC: begin
                vsync = 1'b0;
                if(vsync_low_reg == VSYNC_LOW) begin
                    state_next      = ST_BUFFER;
                    vsync_low_next  = 0; // reset;
                    buffer_next     = 0;    // reload;
                end    
                else begin
                    vsync_low_next = vsync_low_reg + 1;
                end            
            end
            
            ST_BUFFER: begin
                // this state is the buffer zone between the vsync de/assertion and href de/assertion;
                if(buffer_reg == BUFFER_PERIOD) begin
                    state_next       = ST_HREF_ACTIVE;
                    buffer_next      = 0; // reset;
                    pixel_byte_next  = 0;
                    href_cnt_next    = 0;
                end
                else begin
                    buffer_next = buffer_reg + 1;                
                end
            end
            
            ST_HREF_ACTIVE: begin
                href = 1'b1;
                if(pixel_byte_reg == PIXEL_BYTE_TOTAL) begin
                    state_next      = ST_HREF_REST;
                    href_low_next   = 0;
                end
                else begin
                    pixel_byte_next = pixel_byte_reg + 1;
                end
            end
            
            ST_HREF_REST: begin
                href = 1'b0;
                if(href_low_reg == HREF_LOW) begin
                   state_next       = ST_HREF_ACTIVE;
                   pixel_byte_next  = 0;     
                   
                   // check if all href has been processed;
                   /// if so, the frame is comoplete;
                   if(href_cnt_reg == HREF_TOTAL) begin
                        state_next  = ST_BUFFER_END;
                        buffer_next = 0;
                   end   
                   else begin
                        href_cnt_next = href_cnt_reg + 1;
                   end               
                end
                else begin
                    href_low_next = href_low_reg + 1;                
                end            
            end
            
            ST_BUFFER_END: begin
                if(buffer_reg == BUFFER_PERIOD) begin
                    // done;
                    state_next = ST_IDLE;
                end
                else begin
                    buffer_next = buffer_reg + 1;
                end
            end
            
        default: ;  // nop;
        endcase
    end
    
endmodule
