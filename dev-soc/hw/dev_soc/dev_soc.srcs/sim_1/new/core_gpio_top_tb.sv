`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.04.2023 13:47:23
// Design Name: 
// Module Name: core_gpio_top_tb
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


module core_gpio_top_tb();
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // param;
    localparam PORT_WIDTH = 4;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    
    /* specific; */
    // input;
    logic cs;   
    logic write;   
    logic read;
    logic [REG_ADDRESS_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wr_data;
    
    // output;
    logic [DATA_WIDTH-1:0] rd_data;
    
    // inout;
    tri [PORT_WIDTH-1:0] dinout;
    
    // sim;
    logic[4:0] test_index;
    
    // internal register of the core;
    localparam REG_DATA_OUT_OFFSET = 2'b00;         // for output data;
    localparam REG_DATA_IN_OFFSET = 2'b01;          // for input data;
    localparam REG_CTRL_DIRECTION_OFFSET = 2'b10;   // for direction control;
    
     /* instantiation */
     core_gpio #(.PORT_WIDTH(PORT_WIDTH))
     uut(.*);
     
     // test stimulus drive;
     core_gpio_tb tb(.*);
     
     /* simulate clk */
     always
        begin 
           clk = 1'b1;  
           #(T/2); 
           clk = 1'b0;  
           #(T/2);
        end
    
     /* reset pulse */
     initial
        begin
            reset = 1'b1;
            #(T/2);
            reset = 1'b0;
            #(T/2);
        end
        
    
     /* monitoring */
     initial
     begin
        $monitor("time: %0t, index: %0d, addr: %0d, cs: %0b, rd: %0b, wr: %0b, wr_data: %0B, rd_data: %0B, dinout: %0B",
            $time,
            test_index,
            addr[1:0],
            cs,
            read,
            write,
            wr_data[PORT_WIDTH-1:0],
            rd_data[PORT_WIDTH-1:0],
            dinout[PORT_WIDTH-1:0]);
     end
     
    
    
    
endmodule
