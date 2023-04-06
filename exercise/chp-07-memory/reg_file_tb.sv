`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2023 22:58:02
// Design Name: 
// Module Name: reg_file_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for reg_file module 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reg_file_tb();
    localparam T = 10;  // clock period, 10ns;
    logic clk;
    
    // signal prep;
    // memory is of 4 x 8-bit size;
    localparam DATA_WIDTH = 8;      // data width;
    localparam ADDR_WIDTH = 2;      // 2^2 addresses;
    logic [DATA_WIDTH-1:0] rd_data; // output read;
    logic [DATA_WIDTH-1:0] wr_data; // input; write data;
    
    logic [ADDR_WIDTH-1:0] rd_addr; // input; read address;
    logic [ADDR_WIDTH-1:0] wr_addr; // input; write address;
    logic wr_en;                    // write enable;
    
    
    // temp var;
    localparam total_addresses = 2**ADDR_WIDTH;
    // simulate clk;
    always
    begin
        clk = 1'b1; // high for 5 ns;
        #(T/2);
        clk = 1'b0; // low for 5 ns;
        #(T/2);            
    end
    
    // uut instantiation;
    // use 4x8 size;
    reg_file #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) uut(.*);
    
    initial
    begin
        /* test 01: set the memory content */
        @(negedge clk);
        wr_en = 1'b1;
        
        // write;
        for(int i = 0; i < total_addresses; i++) begin
            @(negedge clk); 
            wr_addr = i;
            wr_data = {DATA_WIDTH{i}};
        end
        
        // read;
        for(int i = 0; i < total_addresses; i++) begin
            @(negedge clk); 
            rd_addr = i;
            #5 $strobe("time: %0t, index: %0d, read: %0d", $time, i, rd_data);
            #5 assert(rd_data == DATA_WIDTH'(i)) $display("OK");
                else $error("something went wrong");
        end
     
        /* test the write enable */
        @(negedge clk);
        wr_en = 1'b0;   // disable
        
        // try writing;
        for(int i = 0; i < total_addresses; i++) begin
            // enable the write for index 2 only;
            @(negedge clk);
            if(i == 2) begin
                wr_en = 1'b1;
            end
            else
            begin
                wr_en = 1'b0;
            end
       
            wr_addr = i;
            wr_data = {DATA_WIDTH{$random}};    // use random values;
            
            #5 $display("time: %0t, index: %0d, wr_enable: %0d, write: %0d", $time, i, wr_en, wr_data);
        end
        
        // read;
        for(int i = 0; i < total_addresses; i++) begin
            @(negedge clk); 
            rd_addr = i;
            #5 $display("time: %0t, index: %0d, read: %0d", $time, i, rd_data);
        end
        
        #(10*T);  
     
    $stop;
    end
    
    
endmodule
