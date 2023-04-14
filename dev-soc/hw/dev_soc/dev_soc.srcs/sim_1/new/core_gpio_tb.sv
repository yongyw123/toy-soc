`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2023 01:51:44
// Design Name: 
// Module Name: core_gpio_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for core_gpio module;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module core_gpio_tb();
    // general;
    localparam T = 10;  // clock period: 10ns;
    logic clk;
    logic reset;
    localparam DATA_WIDTH = 32;         // microblaze uses 32-bit data;
    localparam REG_ADDRESS_WIDTH = 5;   // each io core has 2**5 registers;
    
    // specific;
    localparam PORT_WIDTH = 16;             // gpio port width;
    logic cs;                               // input; chip select;
    logic write;                            // input;
    logic read;                             // input;
    logic [REG_ADDRESS_WIDTH -1:0] addr;    // input; register address;
    logic [DATA_WIDTH-1:0] wr_data;         // input;
    logic [DATA_WIDTH-1:0] rd_data;         // input;
    tri [PORT_WIDTH-1:0] dinout;            // tristate for gpio;
    
    // internal register of the core;
    localparam REG_DATA_OUT_OFFSET = 2'b00;         // for output data;
    localparam REG_DATA_IN_OFFSET = 2'b01;          // for input data;
    localparam REG_CTRL_DIRECTION_OFFSET = 2'b10;   // for direction control;
    
    // simulation var;
    logic [PORT_WIDTH-1:0] temp_wr_data;
    logic [PORT_WIDTH-1:0] temp_wr_data_02;
    logic [PORT_WIDTH-1:0] temp_rd_data;
    logic [PORT_WIDTH-1:0] temp_rd_data_02;
    logic [PORT_WIDTH-1:0] dir_all_out_data;
    logic [PORT_WIDTH-1:0] dir_all_in_data;
    logic [PORT_WIDTH-1:0] clean_data;
    logic [PORT_WIDTH-1:0] dir_mix_data;
    logic [PORT_WIDTH-1:0] dir_mix_data_02;
    logic [PORT_WIDTH-1:0] high_imp_data;
    logic [PORT_WIDTH-1:0] all_true_data;
    logic [PORT_WIDTH-1:0] all_false_data;
    
    // instantiation;
    core_gpio #(.PORT_WIDTH(PORT_WIDTH)) uut(.*);
    
    // simulate clk
    always
    begin 
       clk = 1'b1;  
       #(T/2); 
       clk = 1'b0;  
       #(T/2);
    end

    // reset before simulating;
    // by default, all data input output buffers are zero;
    // by default, the direction is input;
    initial
    begin
        reset = 1'b1;
        #(T/2);
        reset = 1'b0;
        #(T/2);
    end
    
    // setup some init value;
    // this is necessary since not all bits are used;
    // need to set the rest to avoid "X" unknown values;
    /*
    initial
    begin
        //addr = 5'b0;        // reset the register address
        wr_data = 32'b0;     // reset the write data;  
    end
    */
    initial
    begin
        high_imp_data = PORT_WIDTH'(32'bz);
        all_true_data = PORT_WIDTH'(32'b1);
        all_false_data = PORT_WIDTH'(32'b0);
        temp_wr_data = PORT_WIDTH'($random);
        temp_wr_data_02 = PORT_WIDTH'($random);
        temp_rd_data = PORT_WIDTH'($random);
        temp_rd_data_02 = PORT_WIDTH'($random);
        dir_all_out_data = PORT_WIDTH'(32'hFFFF);
        dir_all_in_data = PORT_WIDTH'(0);
        clean_data = PORT_WIDTH'(0);
        dir_mix_data = PORT_WIDTH'($random);
        dir_mix_data_02 = PORT_WIDTH'($random);
    end
    
    initial
    begin
        $display("----- test starts -----");
        /* --------- test 00 ---------
        * check all registers are at default values, after reset;
        -----------------------------*/
        $display("----- test 00 -----");
        
        // after reset, the rd_data will be reset to zero;
        // expect read data to be either zero or unknown;
        // depending on the reset timing;
        $display("time %0t; rd_data: %0B", $time, rd_data);
        
        @(negedge clk);
        
        // expect read data to be zero or unknown;
        // depending on the reset timing;
        $display("time %0t; rd_data: %0B", $time, rd_data);
        
        read = 1'b1;    
        write = 1'b0;
        cs = 1'b1;
        addr[1:0] = REG_DATA_IN_OFFSET;
        
        @(negedge clk);
        // expect read data to be high impedance since all output is disabled;
        $display("time %0t; rd_data: %0B", $time, rd_data);
        
        @(negedge clk);
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        
        @(negedge clk);
        // expect read direction to be zero (input);
        // direction is input after reset;
        $display("time %0t; rd_data: %0B", $time, rd_data);
        
        
        /* --------- test 01 --------- 
        * action:
        * 1. direction is inwards for all ports; 
        * 2. write some data to output register;
        * 
        * expectation:
        * 1. all dinout to be high impedance since output port is disabled;
        * 2. rd_data to sample dinout; hence same as dinout;
        *       Why?
        *       by construction;
        *       rd_data either samples dinout or the direction_register;
        *       depending on the decoded address;
        *       by default, it always samples dinout
        *       unless the decoded address is the direction_register;
        * 
        -----------------------------*/
        $display("----- test 01 -----");
        @(negedge clk);
        // enable write operation;
        read = 1'b0;    
        write = 1'b1;
        cs = 1'b1;
        
        // write data to the output buffer;
        // but direction is configured as input by the reset above;
        addr[1:0] = REG_DATA_OUT_OFFSET;    
        wr_data[PORT_WIDTH - 1:0] = temp_wr_data;
        // expect the dinout to be high impedance because direction is inwards;
        @(negedge clk);   
        
        /* ******** IMPORTANT **********************
        the following assertion will always return false;
        //assert(dinout == 16'bZ) $display("Ok"); 
        
        why? cannot compare high impedance; even though both are "same";
        HiZ is floating; it does not make sense to physically realize it;
        because HiZ means neither zero or one;
        so HiZ == HiZ does not make sense?
        
        */
        
       $display("expect dinout to be all High Impedance");
       $display("time %0t; dinout: %0B", $time, dinout);
       $display("time %0t; rd_data: %0B", $time, rd_data);
        
        /* --------- test 02 --------- 
        * action:
        * 1. direction is outwards for all ports; 
        * 2. write some data to output register;
        * 
        * expectation:
        * 1. all dinout to be driven the write_data above;
        * 2. rd_data to sample direction_register
        -----------------------------*/
        $display("----- test 02 -----");
        // now change all ports to output direction;
        @(negedge clk);
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_all_out_data;
        // it takes one clock cycle to update the state;
        @(negedge clk); 
        
        // expect that the dinout reflects the write data;
        assert(dinout == temp_wr_data) $display("Ok");
                else $error("time %0t, expect all dinout to reflect wr_data", $time);
        
        // expect rd_data to reflect the direction register;
        assert(rd_data == dir_all_out_data) $display("Ok");
                else $error("time %0t, expect all rd_data to the direction register", $time);
        
        
        /* --------- test 03 --------- 
        * action:
        * 1. direction is inwards for all ports; 
        * 
        * expectation:
        * 1. all dinout to be HIGH impedance since output port is disabled;
        * 2. rd_data to sample direction register data;
        -----------------------------*/
        $display("----- test 03 -----");
        
        // now change back to input direction;
        @(negedge clk);
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_all_in_data;
        
        // enable read and disable write;
        @(negedge clk); 
        
        // expect that the dinout reflects the data written at the input port for reading;
        $display("expect dinout to be all High Impedance");
        $display("time %0t; dinout: %0B", $time, dinout);
           
        // expect rd_data to reflect the direction register;
        assert(rd_data == dir_all_in_data) $display("Ok");
                else $error("time %0t, expect all rd_data to the direction register", $time);
        @(negedge clk);
        
        /* --------- test 04 --------- 
        * action:
        * 1. mix direction across different ports;
        * 2. wr_data is also mixed; 
        *
        * test method; 
        * 1. this requires checking each port bit individually and visually;
        *
        * expectation;
        * 0. index i is a given bit (port) position;
        * 1. if the decoded address is direction register, rd_data[i] to reflect the direction[i];
        * 2. if the decoded address is not direction register: 
        *           if direction[i] is out, then rd_data[i] == dinout[i];
        *           if direction[i] is in, then rd_data[i] is high impedance[i];
       -----------------------------*/
        $display("----- test 04 -----");
        
        /*
        * change the direction register to mixed;
        */
        read = 1'b0;    
        write = 1'b1;
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_mix_data;
        
        /*
        * read the direction register;
        */
        @(negedge clk);
        read = 1'b1;    
        write = 1'b0;
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        
        @(negedge clk);
        assert(rd_data == dir_mix_data) $display("Ok");
            else $error("time %0t, expect rd_data to correspond to the direction data", $time);

        /*
        * read the dinout;
        */
        
        addr[1:0] = REG_DATA_IN_OFFSET;
        @(negedge clk);
        $display("time  %0t", $time);
        
        for(int i = 0; i < 16; i++) begin
            // remember: cannot compare high impedance;
            // can only do so by visual comparison;
            // maybe there is a better way, but the tester has not figured it out;            
            $display("i: %0d, dir: %0b, dinout: %0b, wr_data: %0b, rd_data: %0b", i, dir_mix_data[i], dinout[i], temp_wr_data[i], rd_data[i]);   
            
        end 
        
        /* 
        output something;
        change direction to out;
        */
        read = 1'b0;    
        write = 1'b1;
        addr[1:0] = REG_DATA_OUT_OFFSET;    
        wr_data[PORT_WIDTH - 1:0] = temp_wr_data_02;
        
        @(negedge clk);        
        addr[1:0] = REG_CTRL_DIRECTION_OFFSET;
        wr_data[PORT_WIDTH - 1:0] = dir_mix_data_02;
        
        @(negedge clk);        
        addr[1:0] = REG_DATA_IN_OFFSET;
        $display("time  %0t", $time);
        
        @(negedge clk);
        for(int i = 0; i < 16; i++) begin
            $display("i: %0d, dir: %0b, dinout: %0b, wr_data: %0b, rd_data: %0b", i, dir_mix_data_02[i], dinout[i], temp_wr_data_02[i], rd_data[i]);
        end
        
                
       #(T);
       $display("----- test ends -----");
    $stop;
    end
    
    
endmodule
