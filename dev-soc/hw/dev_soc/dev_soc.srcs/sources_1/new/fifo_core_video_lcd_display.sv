`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 15:21:48
// Design Name: 
// Module Name: fifo_core_video_lcd_display
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
Construction: 
this is a FIFO buffer between the pixel generation (source) and the sink (lcd)
via the core_video_lcd_display_module();
it uses Xilinx synchronous FIFO

Sink Device:
1. LCD ILI9341
2. Interface Protocol: MCU 8080-I series;
*/


module fifo_core_video_lcd_display
    #(parameter
        DATA_WIDTH = 8,     // this corresponds to LCD parallel 8-bit;
        ADDRESS_WIDTH = 5   // 2^5 = 32 fifo depth;
    )
    (
        // general;
        input clk,  // system clock; 100MHz;
        input reset, // async;
        
        // source: left side of the fifo;
        input logic [DATA_WIDTH-1:0] src_data,   // 8 bits;
        input logic src_valid,   // source data is ready; perform the write;
        output logic src_ready,  // fifo is ready to accept new data;
        
        // sink: right side of the fifo;
        output logic [DATA_WIDTH-1:0] sink_data,
        output logic sink_valid, // fifo is non-empty;
        input logic sink_ready // the sink is ready to ready data from this fifo;
       
    );
    
    
    logic almost_empty; // not used;
    logic almost_full;
    logic full;         // not used;
    logic empty;
    logic [10:0] rd_cnt;    // not used;
    logic [10:0] wr_cnt;    // not used;
    logic wr_err;           // not used;
    logic rd_err;           // not used;
    
    assign sink_valid = !empty;         // as soon as the fifo has some data;
    assign src_ready = !almost_full;    // not when the fifo is already full;
    
    
    //  <-----Cut code below this line---->

   // FIFO_SYNC_MACRO: Synchronous First-In, First-Out (FIFO) RAM Buffer
   //                  Artix-7
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

   FIFO_SYNC_MACRO  #(
      .DEVICE("7SERIES"), // Target Device: "7SERIES" 
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(DATA_WIDTH), // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DO_REG(0),     // Optional output register (0 or 1)
      .FIFO_SIZE ("18Kb")  // Target BRAM: "18Kb" or "36Kb" 
   ) fifo_unit (
      .ALMOSTEMPTY(almost_empty), // 1-bit output almost empty
      .ALMOSTFULL(almost_full),   // 1-bit output almost full
      .DO(sink_data),                   // Output data, width defined by DATA_WIDTH parameter
      .EMPTY(empty),             // 1-bit output empty
      .FULL(full),               // 1-bit output full
      .RDCOUNT(rd_cnt),         // Output read count, width determined by FIFO depth
      .RDERR(rd_err),             // 1-bit output read error
      .WRCOUNT(wr_cnt),         // Output write count, width determined by FIFO depth
      .WRERR(wr_err),             // 1-bit output write error
      .CLK(clk),                 // 1-bit input clock
      .DI(src_data),                   // Input data, width defined by DATA_WIDTH parameter
      .RDEN(sink_ready),               // 1-bit input read enable
      .RST(reset),                 // 1-bit input reset
      .WREN(src_valid)                // 1-bit input write enable
    );

   // End of FIFO_SYNC_MACRO_inst instantiation
				
				
endmodule
