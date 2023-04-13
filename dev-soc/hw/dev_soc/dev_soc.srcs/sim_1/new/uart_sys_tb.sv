`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2023 01:41:32
// Design Name: 
// Module Name: uart_sys_tb
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
purpose: program to drive this module: uart_sys_top_tb.sv
*/

program uart_sys_tb
    #(
        parameter 
        UART_DATA_BIT = 8,                   // number of data bits;
        UART_STOP_BIT_SAMPLING_NUM = 16,     // this corresponds to one stop bit; (16 oversampling);
        FIFO_ADDR_WIDTH = 2,            // FIFO addr size; its data
        FIFO_DATA_WIDTH = 8             // fifo data size;
    )
   (
        input logic clk,
        output logic reset,
        // uart system;
        output logic ctrl_rd,
        output logic ctrl_wr,
        output logic [UART_DATA_BIT-1:0] wr_data,
        input logic [UART_DATA_BIT-1:0] rd_data,       
        input logic rx_empty,
        input logic tx_full
    );
    
    localparam wr_data_num = 2**FIFO_ADDR_WIDTH;
     
    logic [UART_DATA_BIT-1:0] wr_data_array [0:wr_data_num-1];
   
    /* reminder:
        1. there is no UART control flow using CTS and RTS;
        2. so there will be data loss if UART Rx FIFO is full but kept being driven;
        3. as such, this will not be tested
        */
     
    initial begin
        // start from a clean slate
        @(posedge clk)
        ctrl_wr <= 1'b0;
        ctrl_rd <= 1'b0;
        
        /* test 00; sequential (no burst writing);
        transmit one data, wait for it to arrive on the rx end;
        then repeat;
        
        so uart tx will never be full;
        */
        $display("----------------test 00--------------");
        for(int i = 0; i < wr_data_num; i++) begin
            @(posedge clk);
            ctrl_wr = 1'b1;
            wr_data = (UART_DATA_BIT)'($random);

            // disable write otherwise fifo will be kept written, by construction;
            @(posedge clk);
            ctrl_wr = 1'b0;
            
            // wait for the arrival;
            wait(rx_empty == 1'b0);
            ctrl_rd = 1'b1;
            
            // expect that the rd_data == wr_data;
            wait(rd_data == wr_data);
          
            // expect after one read; UART rx to be empty;
            wait(rx_empty == 1'b1);
            
            // disable read;
            @(posedge clk);
            ctrl_rd = 1'b0;
            
            $display("transfer: %0d is done", i);
            $display("------------------------");
        end 
        
        
        $display("resetting the system for a different stimulus");
        $display("------------------------");
        
        @(posedge clk);
        reset <= 1'b1;
        
        @(posedge clk);
        reset <= 1'b0;
        
        @(posedge clk);
                    
        /* 
        Test 01;
        1. trigger a burst of transfer which populate the tx fifo until full;
        2. wait on the end until the first data has arrived;
        3. then keep reading until empty;
        */
        $display("----------------test 01--------------");
        $display("UART TX: burst transfer");
        $display("------------------------");
        /* UART Tx */
        // write until fifo is full
        // write beyond the fifo size to ensure fifo full is covered; 
        for(int i = 0; i < (wr_data_num + 2); i++) begin
        //for(int i = 0; i < 1; i++) begin
            @(posedge clk)
            ctrl_wr <= 1'b1;
            wr_data = (UART_DATA_BIT)'($random);            
            
            // store the wr_data for later check in the read section;
            wr_data_array[i] = wr_data;
            $display("uart tx: %0d, wr_data: %0B, fifo full?: %0b", i, wr_data, tx_full);
        end
        
        //wait(tx_full == 1'b1);
        // disable write;
        @(posedge clk)
        ctrl_wr <= 1'b0;
    
        
        // expect that the tx fifo flag will be dropped;
        // because uart tx will keep on requesting data from tx fifo
        // as long as it is not empty;
        // if there is no write request to the tx fifo;
        // its tx full flag will be dropped;
        wait(tx_full == 1'b0);

        /* UART rx; */
        $display("UART RX: burst read;");
        $display("------------------------");
        /*
        expect that the rx end will be slower;
        */
        
        // keep reading until empty flag;
        for(int i = 0; i < (wr_data_num); i++) begin
            
            // wait for the arrival;
            if(rx_empty) begin
                $display("debug: %0d", i);
                // disable read as there is nothing to read;
                @(posedge clk)
                ctrl_rd <= 1'b0;
                
                // wait for the data arrival;
                wait(rx_empty == 1'b0);
                ctrl_rd <= 1'b1;
                
                // expect the read data to correspond;
                // to the wr data in first in first out manner;
                wait(rd_data == wr_data_array[i]);
                
                // need to disable read;
                // otherwise it will keep reading;
                // since it takes one clock edge to update the fifo
                // empty flag;
                
                @(posedge clk)
                ctrl_rd <= 1'b0;
                
                $display("uart rx read: %0d is done", i);                
            end
            // already arrive;
            else begin
                // read it;
                @(posedge clk)
                ctrl_rd <= 1'b1;
                
                // expect the read data to correspond;
                // to the wr data in first in first out manner;
                wait(rd_data == wr_data_array[i]);
                
                // need to disable read;
                // otherwise it will keep reading;
                // since it takes one clock edge to update the fifo
                // empty flag;
                
                @(posedge clk)
                ctrl_rd <= 1'b0;
                
                $display("uart rx read: %0d is done", i);
            end
        end
        
        // ensure the fifo here is already empty;
        @(posedge clk)
        assert(rx_empty) $display("OK");
            else $error("expected uart rx fifo to be empty here");
        
   $display("DONE");
   #(20);
   //$finish;
   end 
endprogram
