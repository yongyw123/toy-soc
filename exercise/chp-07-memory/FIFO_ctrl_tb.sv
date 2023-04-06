`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.04.2023 01:29:02
// Design Name: 
// Module Name: FIFO_ctrl_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for FIFO_ctrl module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO_ctrl_tb();
    // general;
    localparam T = 10;  // clk period; 10ns;
    localparam ADDR_WIDTH = 4;  // total address = 2^{4};
    localparam total_addr_num = 2**ADDR_WIDTH;
    logic clk;    
    logic reset;
    
    // inputs for the module under test;
    logic ctrl_rd, ctrl_wr;     // [input] control signal fo read and write;
    logic flag_empty, flag_full;     // [output] flag signals: empty/full fifo;
    logic [ADDR_WIDTH-1:0] wr_addr;  // [output] write address; pointing at the next available FIFO space;
    logic [ADDR_WIDTH-1:0] rd_addr;  // [output] read address; pointing at the top non-empty content;
    
    // simulate clk;
    always
        begin
            clk = 1'b1;
            #(T/2);
            clk = 1'b0;
            #(T/2);
        end
   
   
   // uut instantiate;
   FIFO_ctrl #(.ADDR_WIDTH(ADDR_WIDTH)) uut(.*);
        
    // apply reset;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
        @(negedge clk); // avoid data setup and hold time for subsequent simulation;
    end
   
    // set up intiial values;
    initial
    begin
        ctrl_rd = 1'b0;
        ctrl_wr = 1'b0;
    end
    // start testing;
    initial
    
    begin   
        
        $display("---- check fifo state after reset -----");
        $display("time: %0t, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, wr_addr, rd_addr, flag_full, flag_empty);
        assert((flag_empty == 1'b1)&&(flag_full == 1'b0)) $display("OK");
            else $error("something went wrong");
        
        $display("---- write until full flagged  -----");
        @(negedge clk);
        ctrl_rd  = 1'b0;    // write only;
        for(int i = 0; i < (total_addr_num + 10); i++) begin
            @(negedge clk);
            ctrl_wr = 1'b1;
            #5 $display("time: %0t, index: %0d, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, i, wr_addr, rd_addr, flag_full, flag_empty);
        end
        
        $display("--------- read until empty -------------");
        @(negedge clk);
        ctrl_wr = 1'b0; // read only; 
        for(int i = 0; i < (total_addr_num + 10); i++) begin
            @(negedge clk);
            ctrl_rd = 1'b1;
            #5 $display("time: %0t, index: %0d, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, i, wr_addr, rd_addr, flag_full, flag_empty);
        end
        
    
        $display("--------- read and write simultaneously - v1 -------------");
        /* expectation;
            0. we expect the read ptr and write ptr should be the same
            1. we expect every read/write, the ptr will increment;
            2. since the fifo is empty by previous simulation;
            3. we expect that the FIFO to be flagged empty at all times; 
        */
        @(negedge clk);
        ctrl_wr = 1'b0; // reset;
        ctrl_wr = 1'b0; // reset; 
        for(int i = 0; i < (total_addr_num + 10); i++) begin
            @(negedge clk);
            ctrl_rd = 1'b1;
            ctrl_wr = 1'b1;
            #5 $display("time: %0t, index: %0d, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, i, wr_addr, rd_addr, flag_full, flag_empty);
        end
    
    
        $display("--------- read and write simultaneously - v2-------------");
        /* expectation;
            1. this repeats the v1 but with non empty fifo to begin with;
            2. we expect the fifo both flags not to be flag: non-empty; non-full; 
            3. also, we should not expect both write and read pointers to be the same;
        */
        
        // empty the fifo first by reading it (not resetting)
        $display("--------- read and write simultaneously - v2 - prep -------------");
        @(negedge clk);
        ctrl_wr = 1'b0; // read only; 
        for(int i = 0; i < (total_addr_num + 10); i++) begin
            @(negedge clk);
            ctrl_rd = 1'b1;
            #5 $display("time: %0t, index: %0d, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, i, wr_addr, rd_addr, flag_full, flag_empty);
        end
        
        // fill two slots;
        $display("--------- read and write simultaneously - v2 - fill in -------------");
        @(negedge clk);
        ctrl_wr = 1'b1; 
        ctrl_rd = 1'b0;
        $display("time: %0t, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, wr_addr, rd_addr, flag_full, flag_empty);
         
        @(negedge clk);
        ctrl_wr = 1'b1; 
        ctrl_rd = 1'b0; 
        $display("time: %0t, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, wr_addr, rd_addr, flag_full, flag_empty);
        
        // start the real test;
        $display("--------- read and write simultaneously - v2 - actual start -------------");
        for(int i = 0; i < (total_addr_num + 10); i++) begin
            @(negedge clk);
            ctrl_rd = 1'b1;
            ctrl_wr = 1'b1;
            #5 $display("time: %0t, index: %0d, wr_ptr_addr: %0d, rd_ptr_addr: %0d, full_flag: %0d, empty_flag: %0d",
                         $time, i, wr_addr, rd_addr, flag_full, flag_empty);
        end
    
    $stop;
    end
endmodule
