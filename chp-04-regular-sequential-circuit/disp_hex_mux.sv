`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 17:17:53
// Design Name: 
// Module Name: disp_hex_mux
// Project Name: 
// Target Devices: nexys a7 50t 
// Tool Versions: 
// Description: 
//      seven segment time multipexing circuit for hexadecimal display
//      four seven segments shall be time multiplexed
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
// acknowledgement:
// this is based on Pong P. Chu's book: "FPGA Prototyping by System Verilog Examples"
// chapter 4: regular sequential circuit;
// listing 4.17;
//////////////////////////////////////////////////////////////////////////////////

module disp_hex_mux
    #(parameter N = 18) // to determine the time multiplexing refreshing rate'
    (
    input logic clk,        // assummed at 100MHz;
    input logic reset,      // asyn reset;
    input logic [3:0] hex0, hex1, hex2, hex3, // indiviudal hex digit pattern 
    input logic [3:0] dp_in,    // decimal points for the disp;
    output logic [3:0] an,          // seven seg enable; 
    output logic [7:0] sseg         // led seven segments;
    );
    
    // declare;
    logic[N-1:0] q_curr;
    logic[N-1:0] q_next;    
    logic[3:0] hex_in;      // to decode hex for sseg display;
    logic dp;               // for decimal point;
    
    // reg;
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            q_curr <= 0;
        else
            q_curr <= q_next; 
    end

    // counter;
    assign q_next = q_curr + 1;
    
    // time multiplexe
    always_comb 
        case(q_curr[N-1:N-2])
            2'b00:
                begin
                    an = 4'b1110;
                    hex_in = hex0;
                    dp = dp_in[0];
                end
        
            2'b01:
                begin
                    an = 4'b1101;
                    hex_in = hex1;
                    dp = dp_in[1];
                end
        
            2'b10:
                begin
                    an = 4'b1011;
                    hex_in = hex2;
                    dp = dp_in[2];
                end
            
            default:
                begin
                    an = 4'b0111;
                    hex_in = hex3;
                    dp = dp_in[3];
                end
        endcase
        
       // hex decoder for sseg displ;
       always_comb
       begin
            case(hex_in)
                4'h0: sseg[6:0] = 7'b100_0000;
                4'h1: sseg[6:0] = 7'b111_1001;
                4'h2: sseg[6:0] = 7'b010_0100;
                4'h3: sseg[6:0] = 7'b011_0000;
                4'h4: sseg[6:0] = 7'b001_1001;
                4'h5: sseg[6:0] = 7'b001_0010;
                4'h6: sseg[6:0] = 7'b000_0010;
                4'h7: sseg[6:0] = 7'b111_1000;
                4'h8: sseg[6:0] = 7'b000_0000;
                4'h9: sseg[6:0] = 7'b001_0000;
                4'ha: sseg[6:0] = 7'b000_1000;
                4'hb: sseg[6:0] = 7'b000_0011;
                4'hc: sseg[6:0] = 7'b100_0110;
                4'hd: sseg[6:0] = 7'b010_0001;
                4'he: sseg[6:0] = 7'b000_0110;
                default: sseg[6:0] = 7'b000_1110;
            endcase
        sseg[7] = dp;
       end
       
endmodule
