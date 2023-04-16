`timescale 1ns / 10ps

module  spi_sys_top_tb();
    
    // general;
    localparam T = 10;  // system clock period: 10ns;
    logic clk;          // common system clock;
    logic reset;        // async system clock;
    
    // constants;
    localparam DATA_BIT = 8;
    localparam MAX_SPI_CLOCK_WIDTH = 16;
    
    /*  -------- specific -----*/
    // input;
    logic [DATA_BIT-1:0] mosi_data_write;   // data to send to the slave;    
    logic [MAX_SPI_CLOCK_WIDTH-1:0] count_mod; // counter threshold for spi clock as discussed above;
    logic cpol;
    logic cpha;
    logic start;        // start spi transaction;
    logic miso;  // slave input bit to sample;
    
    // outputs;
    logic [DATA_BIT-1:0] miso_assembled_data; // assembled data from the slave after one SPI transaction is complete 
    logic spi_complete_flag; // spi transcation is done;
    logic spi_ready_flag;   // spi is idle, available for new transaction;
    logic sclk;  // spi clock;
    logic mosi;  // master output bit to shift out (write0;

    // sim var;
    logic [5:0] test_index;
            
    /* instantiation */
    spi_sys uut(.*);
    
    // test stimulus;
    spi_sys_tb tb(.*);
    
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
        $monitor("time: %0t, test index: %0d, spi_state: %s, cpol: %0b, cpha: %0b, start: %0b, count_mod: %0D, mosi_din: %0B, complete: %0b, ready: %0b, sclk: %0b, miso: %0b, mosi: %0b, miso_assembled: %0B",
            $time,
            test_index,
            uut.state_reg.name,
            cpol,
            cpha,
            start,
            count_mod,
            mosi_data_write,
            spi_complete_flag,
            spi_ready_flag,
            sclk,
            miso,
            mosi,
            miso_assembled_data);
    end
    
    
    
    
endmodule
    