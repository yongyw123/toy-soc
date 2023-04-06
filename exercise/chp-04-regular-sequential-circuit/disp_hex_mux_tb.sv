`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 19:05:00
// Design Name: 
// Module Name: disp_mux_hex_tb
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


module disp_hex_mux_tb();
    
	/* declare; */
    localparam T = 20;  // clk period: 20ns
    
	// number of bits for the refresh rate;
	// no need to set to 18 to have ~1000 Hz in simulation;
	localparam N = 4;   
	
    logic clk;
    logic reset;
    
    // main input
    logic [3:0] hex0, hex1, hex2, hex3; // indiviudal hex digit pattern 
    logic [3:0] dp_in;	// decimal points for the disp;
    logic [3:0] an;     // seven seg enable; 
    logic [7:0] sseg;    // led seven segments;
        
    // uut instantiate;
    disp_hex_mux #(.N(N)) uut(.*);
    
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
		dp_in = 4'b0000;	// dummy val; not important;
		hex0 = 4'b0001;
		hex1 = 4'b0010;
		hex2 = 4'b0100;
		hex3 = 4'b1000;
	end
	
	// start simulating;
	initial 
	begin	
		/* expectation;
	     * by above, refresh rate is set to 2^2 = 4
	     * so after every 4 clock cycles, 
		 * hex is enabled in order of 0, 1, 2, 3;
		*/
		#(4*T);	
		$display("----first sseg----");
		$display("time = %0t, an = 0b%4B, sseg = 0b%8B", $time, an, sseg);
		assert(an == 4'b1110) $display("OK");
		  else $error("incorrect enable");
		assert(sseg == {dp_in[0], 7'b111_1001}) $display("OK");
		  else $error("incorrect decoded hex");
		  
	   #(4*T);
	   $display("----second sseg----");
	   $display("time = %0t, an = 0b%4B, sseg = 0b%8B", $time, an, sseg);
		assert(an == 4'b1101) $display("OK");
		  else $error("incorrect enable");
		assert(sseg == {dp_in[1], 7'b010_0100}) $display("OK");
		  else $error("incorrect decoded hex");	
		
		#(4*T);
		$display("----third sseg----");
		$display("time = %0t, an = 0b%4B, sseg = 0b%8B", $time, an, sseg);
	    assert(an == 4'b1011) $display("OK");
		  else $error("incorrect enable");
		assert(sseg == {dp_in[2], 7'b001_1001}) $display("OK");
		  else $error("incorrect decoded hex");
		
		#(4*T);
		$display("----forth sseg----");
		$display("time = %0t, an = 0b%4B, sseg = 0b%8B", $time, an, sseg);
		assert(an == 4'b0111) $display("OK");
		  else $error("incorrect enable");
		assert(sseg == {dp_in[3], 7'b000_0000}) $display("OK");
		  else $error("incorrect decoded hex");
	
		#(4*T);
	    $display("----repeat first sseg----");
	    $display("time = %0t, an = 0b%4B, sseg = 0b%8B", $time, an, sseg);
		assert(an == 4'b1110) $display("OK");
		  else $error("incorrect enable");
		assert(sseg == {dp_in[0], 7'b111_1001}) $display("OK");
		  else $error("incorrect decoded hex");
	
	$display("----done----");
	$stop;
	end
endmodule
	