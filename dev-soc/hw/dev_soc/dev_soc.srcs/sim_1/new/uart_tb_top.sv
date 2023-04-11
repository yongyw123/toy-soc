`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2023 00:29:17
// Design Name: 
// Module Name: uart_tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for 3 modules: uart baud rate generator, uart rx and uart tx 
//  
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
Purpose: test bench to test for the following modules:
1. baud rate generator;
2. uart_tx;
3. uart_rx;

Test Method:
1. loop uart_tx to uart_rx;
2. each driven by different baud_rate generator;

Important;
1. the input to uart_rx must be asynchronous;
2. hence uart_tx and its baud rate must be driven async;
3. just use different clock edge will do;
*/

module uart_tb_top();
    
    
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // system clock;
    logic reset;        // async system clock;
    
    // common setting;
    localparam DATA_BIT = 8;
    localparam SAMPLING_STOP_BIT = 16; // one stop bit;
    
    /* baud rate gen common var */
    /* baud rate calculation 
    label programmable_mod, v;
    
    formula;
    to set the following baud rate;
    baud rate, B;    
    system clk, f = 100MHz;
    oversampling: 16;
    
    ==> v + 1 = f/(16*B);
    ==> v =  = f/(16*B) - 1;
    reason wht + 1 is because the baud rate generator starts from zero;
    and count up to the given threshold without minus one to offset it;
    
    */
   
    // the minimum supported standard baud rate is 110 b/s;
    // this requires 9 ms simulation time;
    // this exceeds the simulation time supported by vivado;
    // hence, we artificially inflate the baud rate;
    // just make sure to respect this constraint: 16*baud_rate < 100Mhz;
    localparam baud_rate = 500000;         // bits per second;
    localparam programmable_mod = 100000000/(16*baud_rate);;  // input to program the baud rate gen;
    
    // baud rate generator var for uart rx
    logic sampling_tick_rx;     // output; oversampling tick of the baud rate gen;
    
    // baud rate generator var for uart tx;
    logic sampling_tick_tx;     // output; oversampling tick of the baud rate gen;
    
    /* uart tx var */
   logic clk_tx;
   logic tx_start;  // input; request tx
   logic [DATA_BIT-1:0] din;    // input for tx;
   logic rx;                    // output for uart_rx input;
   logic tx_complete_tick;       // output flag;
   
   assign clk_tx = ~clk;    // async;
  
    /* uart rx var */
    logic rx_complete_tick;         // output flag;
    logic [DATA_BIT-1:0] dout;      // output;
    
    // simulate system clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

   /* instantiation */
   
   // to drive uart tx;
   baud_rate_generator baud_gen_tx
   (.clk(clk_tx), 
   .reset(reset), 
   .programmable_mod(programmable_mod), 
   .sampling_tick(sampling_tick_tx));
   
   // to drive uart rx;
   baud_rate_generator baud_gen_rx
   (.clk(clk), 
   .reset(reset), 
   .programmable_mod(programmable_mod), 
   .sampling_tick(sampling_tick_rx));
   
   // uart rx;
   uart_rx #(.DATA_BIT(DATA_BIT), .SAMPLING_STOP_BIT(SAMPLING_STOP_BIT))
    uart_rx_uut
    (   
      .clk(clk),
      .reset(reset),
      .rx(rx),
      .baud_rate_tick(sampling_tick_rx),
      .rx_complete_tick(rx_complete_tick),
      .dout(dout)
    );
   
   // uart tx;
   uart_tx #(.DATA_BIT(DATA_BIT), .SAMPLING_STOP_BIT(SAMPLING_STOP_BIT))
    uart_tx_uut
    (   
      .clk(clk_tx),
      .reset(reset),
      .tx_start(tx_start),
      .din(din),
      .baud_rate_tick(sampling_tick_tx),
      .tx_complete_tick(tx_complete_tick),
      .tx(rx)
    );
   
   /// monitoring;
    initial 
    begin
    $display("program mod: %0d", programmable_mod);
    $monitor("tx din: %0B", din);
    $monitor("time %0t, tx_flag: %0b, rx: %0b, rx_flag: %0b, rx_dout: %0B",
        $time, tx_complete_tick, rx, rx_complete_tick, dout);
    end
   
   /* simulate system clk;*/
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // apply reset;
    initial
    begin
        tx_start = 1'b0;
        
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
        @(negedge clk); // avoid data setup and hold time for subsequent simulation;
    end
    
    
    // set up values;
    initial 
    begin
        // start the tx;
        din = (DATA_BIT)'($random);
        tx_start = 1'b1;
        #(2*T);
        tx_start = 1'b0;
        
        @(posedge rx_complete_tick);
         
        #(10*T);
        $stop;
    end
    
    
endmodule
