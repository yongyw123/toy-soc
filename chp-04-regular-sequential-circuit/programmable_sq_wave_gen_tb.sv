`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 23:04:39
// Design Name: 
// Module Name: programmable_sq_wave_gen_tb
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


module programmable_sq_wave_gen_tb();
    /* declare; */
    localparam T = 10;  // clk period: 10ns
   
    logic clk;
    logic reset;
    
    // var for declarations;
    logic [3:0] count_debug_ns_tick;
    logic [3:0] count_on;
    logic [3:0] count_off;
    
    // main input
    logic [3:0] ctrl_on;    // control signal for on;
    logic [3:0] ctrl_off;   // control signal fpr off;
    logic sq_wave;          // output;    
    logic debug_ns_tick;    // output;
    logic debug_ns_count;    // output;
    // uut instantiate;
    programmable_sq_wave_gen uut(.*);
   
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

	// reset before simulating;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
    end
	
	// setup the initial value;
	initial
	begin
	   count_debug_ns_tick  = 4'd0;
	   count_on = 4'd0;
	   count_off = 4'd0;
	   ctrl_on = 4'd1;
	   ctrl_off = 4'd3;
	   assert((ctrl_off >= 4'd1) && (ctrl_on >= 4'd1)) $display("OK");
	       else $error("control signal must be greater than zero");
	end
	
	// start simulating;
	initial 
	begin
	   	/* expectation:
	   	   1. after every 100ns, there will be a tick;
	   	   2. During ON interval, there should be #(100ns tick) which corresponds
	   	       to (control_on - 1);
	   	   3. likewise for OFF interval; 
	   	*/
	   	for(int i = 0; i < 100; i++)
	   	begin
	   	   #(10*T);    // 100ns has elapsed   
	   	end
	
		$stop;
    end	
		
endmodule
