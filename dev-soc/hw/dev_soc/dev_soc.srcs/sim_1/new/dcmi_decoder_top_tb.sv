`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2023 21:17:16
// Design Name: 
// Module Name: dcmi_decoder_top_tb
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


module dcmi_decoder_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk_sys;          // common system clock;
    logic reset_sys;        // async system clock;
    
    // constants;
    localparam DATA_BITS = 8;
    
    
    // signals for dcmi emulator to test the dcmi decoder;
    logic pclk;
    logic emulator_start;
    logic vsync;
    logic href;
    logic [DATA_BITS-1:0] emulator_dout;
    logic decoder_ready_flag;
    logic frame_start_tick;
    logic frame_complete_tick;
    
    localparam PCLK_MOD            = 4;   // 100/4 = 25;
    localparam VSYNC_LOW           = 10;   //vlow;
    localparam HREF_LOW            = 3;    // hlow; 
    localparam BUFFER_START_PERIOD = 7;    // between vsync assertion and href assertion;
	localparam BUFFER_END_PERIOD   = 1;	// between the frame end and the frame start;
    localparam HREF_TOTAL          = 3;  // total href assertion to generate;
    localparam PIXEL_BYTE_TOTAL    = 5;   // 320 pixels per href with bp = 16-bit;
    
    // signals for uut: dcmi decoder;
    localparam FRAME_COUNTER_WIDTH = 32;
    logic decoder_start;
    logic decoder_sync_clr_frame_cnt;
    logic decoder_data_valid;
    logic decoder_data_ready;
    logic [DATA_BITS-1:0] decoder_dout;
    logic debug_detect_vsync_edge;
    logic decoder_complete_tick; // when the entire frame has been decoded;
    logic decoder_start_tick;     // when a new frame is detected;
    logic [FRAME_COUNTER_WIDTH-1:0] decoded_frame_counter; // this will overflow;
    
    // signals for the fifo sinking the pixel data from the dcmi decoder;
    logic reset_FIFO;
    localparam FIFO_DEPTH_WIDTH = 11;
    logic FIFO_ALMOSTEMPTY; // 1-bit output almost empty
    logic FIFO_ALMOSTFULL;   // 1-bit output almost full
    logic [DATA_BITS-1:0] FIFO_DOUT;                   // Output data, width defined by DATA_WIDTH parameter
    logic FIFO_EMPTY;             // 1-bit output empty
    logic FIFO_FULL;               // 1-bit output full
    logic [FIFO_DEPTH_WIDTH-1:0] FIFO_RDCOUNT;         // Output read count, width determined by FIFO depth
    logic FIFO_RDERR;             // 1-bit output read error
    logic [FIFO_DEPTH_WIDTH-1:0] FIFO_WRCOUNT;         // Output write count, width determined by FIFO depth
    logic FIFO_WRERR;             // 1-bit output write error
    logic FIFO_RDEN;               // 1-bit input read enable
    
    
    // signals for the test stimulus;
    // this is required because the conditions imposed
    // by the bram fifo, which mainly requires
    // the relevant signals to be LOW prior to/after # read/write cycles;
    logic start_stimulus;   
    
    /* instantiation */
    // dcmi emulator;
    dcmi_emulator
    #(
        .PCLK_MOD(PCLK_MOD), 
        .VSYNC_LOW(VSYNC_LOW),
        .HREF_LOW(HREF_LOW),  
        .BUFFER_START_PERIOD(BUFFER_START_PERIOD),
        .BUFFER_END_PERIOD(BUFFER_END_PERIOD), 	
        .HREF_TOTAL(HREF_TOTAL),          
        .PIXEL_BYTE_TOTAL(PIXEL_BYTE_TOTAL)     
    )
    emulator_unit
    (
        .clk_sys(clk_sys),
        .reset_sys(reset_sys),
        .start(emulator_start),
        .pclk(pclk),
        .vsync(vsync),
        .href(href),
        .dout(emulator_dout),
        .frame_start_tick(frame_start_tick),
        .frame_complete_tick(frame_complete_tick)        
    );
    
    // uut;
    dcmi_decoder
    #(
        .DATA_BITS(DATA_BITS),
        .HREF_COUNTER_WIDTH(8),
        .HREF_TOTAL(HREF_TOTAL),
        .FRAME_COUNTER_WIDTH(FRAME_COUNTER_WIDTH) 
    )
    uut
    (
        .reset_sys(reset_sys),
        .cmd_start(decoder_start),
        .sync_clr_frame_cnt(decoder_sync_clr_frame_cnt),
        .pclk(pclk),
        .href(href),
        .vsync(vsync),
        .din(emulator_dout),
        .data_valid(decoder_data_valid),
        .data_ready(decoder_data_ready),
        .dout(decoder_dout),
        .debug_detect_vsync_edge(debug_detect_vsync_edge),
        .decoder_ready_flag(decoder_ready_flag),
        .decoder_complete_tick(decoder_complete_tick), // when the entire frame has been decoded;
        .decoder_start_tick(decoder_start_tick),     // when a new frame is detected;
        .decoded_frame_counter(decoded_frame_counter)   
    );
    // mapping fifo signal with the dcm decoder;
    assign decoder_data_ready = !FIFO_ALMOSTFULL;   // this is a stricter condition than fully full;
        
      // test stimulus;
     dcmi_decoder_tb tb(.*);
     
    /* fifo sinking the pixel decoded from the dcmi_decoder */
    // FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
    //                       Artix-7
    // Xilinx HDL Language Template, version 2021.2
    
    /////////////////////////////////////////////////////////////////
    // DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
    // ===========|===========|============|=======================//
    //   37-72    |  "36Kb"   |     512    |         9-bit         //
    //   19-36    |  "36Kb"   |    1024    |        10-bit         //
    //   19-36    |  "18Kb"   |     512    |         9-bit         //
    //   10-18    |  "36Kb"   |    2048    |        11-bit         //
    //   10-18    |  "18Kb"   |    1024    |        10-bit         //
    //    5-9     |  "36Kb"   |    4096    |        12-bit         //
    //    5-9     |  "18Kb"   |    2048    |        11-bit         //
    //    1-4     |  "36Kb"   |    8192    |        13-bit         //
    //    1-4     |  "18Kb"   |    4096    |        12-bit         //
    /////////////////////////////////////////////////////////////////
        
    FIFO_DUALCLOCK_MACRO  #(
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(DATA_BITS),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DEVICE("7SERIES"),  // Target device: "7SERIES" 
      .FIFO_SIZE ("18Kb"), // Target BRAM: "18Kb" or "36Kb" 
      .FIRST_WORD_FALL_THROUGH ("TRUE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
    ) bram_fifo_dual_clock_unit (
      .ALMOSTEMPTY(FIFO_ALMOSTEMPTY), // 1-bit output almost empty
      .ALMOSTFULL(FIFO_ALMOSTFULL),   // 1-bit output almost full
      .DO(FIFO_DOUT),                   // Output data, width defined by DATA_WIDTH parameter
      .EMPTY(FIFO_EMPTY),             // 1-bit output empty
      .FULL(FIFO_FULL),               // 1-bit output full
      .RDCOUNT(FIFO_RDCOUNT),         // Output read count, width determined by FIFO depth
      .RDERR(FIFO_RDERR),             // 1-bit output read error
      .WRCOUNT(FIFO_WRCOUNT),         // Output write count, width determined by FIFO depth
      .WRERR(FIFO_WRERR),             // 1-bit output write error
      .DI(decoder_dout),                   // Input data, width defined by DATA_WIDTH parameter
      .RDCLK(clk_sys),             // 1-bit input read clock
      .RDEN((FIFO_RDEN&&!FIFO_EMPTY)),               // 1-bit input read enable      
      .RST(reset_FIFO),                 // 1-bit input reset
      .WRCLK(pclk),             // 1-bit input write clock
      .WREN(decoder_data_valid)                // 1-bit input write enable
    );
    
   // End of FIFO_DUALCLOCK_MACRO_inst instantiation
				
    
    /* simulate system clk */
     always
        begin 
           clk_sys = 1'b1;  
           #(T/2); 
           clk_sys = 1'b0;  
           #(T/2);
        end
    //reset pulse fo the user-systems;
    initial
        begin
        
            decoder_data_valid = 1'b0;
            FIFO_RDEN = 1'b0;
            start_stimulus = 1'b0;
            decoder_sync_clr_frame_cnt = 1'b0;
                
            reset_sys = 1'b1;
            #(T/2);
            reset_sys = 1'b0;
            #(T/2);
        end
     
     /* reset pulse for the fifo;
     bram fifo uses different reset because
     it requires different conditions
     ;*/
     initial
        begin
            /* to satisfy the bram fifo condition 
            1. RESET must be asserted for at least five read clock cycles;
            2. RDEN must be low before RESET is active HIGH;
            3. RDEN must remain low during this reset cycle
            */
            
            /* another bram fifo condition
            RST must be held high for at least five WRCLK clock cycles,
             and WREN must be low before RST becomes active high, 
             and WREN remains low during this reset cycle.
            */
            decoder_data_valid = 1'b0;
            FIFO_RDEN = 1'b0;
            reset_FIFO = 1'b1;
            #(40*20);
            #(T/2);
            reset_FIFO = 1'b0;
            #(40*10);
            start_stimulus = 1'b1;
            
        end
        
        
    /* monitoring system */
    initial begin
        $monitor("time: %t, dec_start: %0b, href: %0b, vsync: %0b, din: %8H, dec_valid: %0b, dec_dout: %8H, frame_start: %0b, frame_complete: %0b, uut.statereg: %s, uut.detect_vsync_edge: %0b, fifo_rd: %0b, fifo rd data: %8H",
        $time,
        decoder_start,
        href,
        vsync,
        emulator_dout,
        decoder_data_valid,
        decoder_dout,
        frame_start_tick,
        frame_complete_tick,
        uut.state_reg.name,
        uut.detect_vsync_edge,
        // fifo;
        FIFO_RDEN,
        FIFO_DOUT
        
        );
    end
        

endmodule
