`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2023 20:34:23
// Design Name: 
// Module Name: core_video_mig_interface_tb
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

`ifndef CORE_VIDEO_MIG_INTERFACE_TB_SV
`define CORE_VIDEO_MIG_INTERFACE_TB_SV

//`include "IO_map.svh"

module core_video_mig_interface_tb(
        input logic clk_sys,
        input logic [15:0] LED,
        output logic reset_sys,
        input logic  locked, // mmcm locked status;
        
        // mig status;
        input logic core_MIG_init_complete,   // MIG DDR2 initialization complete;
        input logic core_MIG_ready,           // MIG DDR2 ready to accept any request;
        input logic core_MIG_transaction_complete, // a pulse indicating the read/write request has been serviced;
        input logic core_MIG_ctrl_status_idle,    // MIG synchronous interface controller idle status;

        // bus interface;
        output logic cs,    
        output logic write,              
        output logic read,               
        output logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,           
        output logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        input logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        // motion detection core interface;
        output logic core_motion_wrstrobe,
        output logic core_motion_rdstrobe,
        output logic [22:0] core_motion_addr,
        output logic [127:0] core_motion_wrdata,
        input logic [127:0] core_motion_rddata        
             
    );
    
    ////////// for simulation;
    localparam LED_END_RANGE = 4;
    //localparam RANDOM_128BIT_WRDATA = {128{$random}};
    logic [127:0] RANDOM_128BIT_WRDATA = {127{$random}};     
        
    //localparam TEST_ARRAY_SIZE_CORE_MOTION = 1000;
    //localparam TEST_ARRAY_SIZE_CORE_MOTION = 2;
    localparam TEST_ARRAY_SIZE_CORE_MOTION = 1000;    
    bit[TEST_ARRAY_SIZE_CORE_MOTION-1:0][127:0] TEST_ARRAY_CORE_MOTION;
    
    //localparam TEST_ARRAY_SIZE_CORE_CPU = 2;
    localparam TEST_ARRAY_SIZE_CORE_CPU = 500;    
    bit[TEST_ARRAY_SIZE_CORE_CPU-1:0][127:0] TEST_ARRAY_CORE_CPU;

    //////////// register address;
    localparam MIG_INTERFACE_REG_SEL       = `V5_MIG_INTERFACE_REG_SEL;
    localparam MIG_INTERFACE_REG_STATUS    = `V5_MIG_INTERFACE_REG_STATUS;
    localparam MIG_INTERFACE_REG_ADDR      = `V5_MIG_INTERFACE_REG_ADDR;
    localparam MIG_INTERFACE_REG_CTRL      = `V5_MIG_INTERFACE_REG_CTRL;
    
    localparam MIG_INTERFACE_REG_WRDATA_01 = `V5_MIG_INTERFACE_REG_WRDATA_01;
    localparam MIG_INTERFACE_REG_WRDATA_02 = `V5_MIG_INTERFACE_REG_WRDATA_02;
    localparam MIG_INTERFACE_REG_WRDATA_03 = `V5_MIG_INTERFACE_REG_WRDATA_03;
    localparam MIG_INTERFACE_REG_WRDATA_04 = `V5_MIG_INTERFACE_REG_WRDATA_04;
    
    localparam MIG_INTERFACE_REG_RDDATA_01 = `V5_MIG_INTERFACE_REG_RDDATA_01;
    localparam MIG_INTERFACE_REG_RDDATA_02 = `V5_MIG_INTERFACE_REG_RDDATA_02;
    localparam MIG_INTERFACE_REG_RDDATA_03 = `V5_MIG_INTERFACE_REG_RDDATA_03;
    localparam MIG_INTERFACE_REG_RDDATA_04 = `V5_MIG_INTERFACE_REG_RDDATA_04;
    
    localparam MIG_INTERFACE_REG_SEL_NONE    = 3'b000;  // none;
    localparam MIG_INTERFACE_REG_SEL_CPU     = 3'b001;  // cpu;
    localparam MIG_INTERFACE_REG_SEL_MOTION  = 3'b010;  // motion detection video cores;
    localparam MIG_INTERFACE_REG_SEL_TEST    = 3'b100;  // hw testing circuit;
    
    initial begin
        // initial reset;
        wait(locked == 1'b1);
        reset_sys = 1'b1;
        #(100);
        reset_sys = 1'b0;
        #(100);
        
        /* initial value; 
        set to cpu source
        */
        @(posedge clk_sys);
        cs <= 1;
        write <= 1;
        read <= 0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_CPU;
        
        // disable
        @(posedge clk_sys);
        cs <= 1;
        write <= 0;
        read <= 0;
        addr <= MIG_INTERFACE_REG_SEL;
                
        
        
        /* test 01: read the status via cpu*/
        @(posedge clk_sys);
        read <= 1;
        addr <= MIG_INTERFACE_REG_STATUS;
        // wait for init complete;
        wait(rd_data[0] == 1);  
        #(100);
        
        
        // other status must either hold true/high after init is completed;
        // until something changes;
        
        // transaction complete must be low since there is no request;
        @(posedge clk_sys);
        #(100);
        assert(rd_data[2] == 0) $display("ok");
            else $error("transaction complete status is not low;");
         // controller must be idle;
        assert(rd_data[3] == 1) $display("ok");
            else $error("controller is not idle");   
        
        #(100);
        
        /* test 02: write and read via the cpu */
        // push the 32-bit cpu data four times to populate the 128-bit ddr2; 
        @(posedge clk_sys);
        read <= 0;
        write <= 1;
        addr <= MIG_INTERFACE_REG_WRDATA_01;
        wr_data <= 32'ha;
        
        @(posedge clk_sys);
        write <= 1;
        addr <= MIG_INTERFACE_REG_WRDATA_02;
        wr_data <= 32'hb;
        
        @(posedge clk_sys);
        write <= 1;
        addr <= MIG_INTERFACE_REG_WRDATA_03;
        wr_data <= 32'hc;
        
        @(posedge clk_sys);
        write <= 1;
        addr <= MIG_INTERFACE_REG_WRDATA_04;
        wr_data <= 32'hd;
        
        // prepare the write address;
        @(posedge clk_sys);
        write <= 1;
        addr <= MIG_INTERFACE_REG_ADDR;
        wr_data <= 5;
        
        // submit the write request;
        @(posedge clk_sys);
        write <= 1'b1;
        addr <= MIG_INTERFACE_REG_CTRL;
        wr_data <= {31'b0, 1'b1};
        
        // disable the write otherwise it will keep writing;
        @(posedge clk_sys);
        write <= 1'b1;
        addr <= MIG_INTERFACE_REG_CTRL;
        wr_data <= {31'b0, 1'b0};
        
        // wait for the transaction complete status;
        @(posedge clk_sys);
        write <= 1'b0;
        read <= 1'b1;
        addr <= MIG_INTERFACE_REG_STATUS;
        
        @(posedge clk_sys);
        wait(rd_data[2] == 1);
        #(100);
        
        /* test 03: read from the previous write (at the same address) */
        
        // prepare the address;
		// maintain as the write address;
        @(posedge clk_sys);
        write <= 1;
        addr <= MIG_INTERFACE_REG_ADDR;
        wr_data <= 5;
        
		// submit the read request;		
        @(posedge clk_sys);
        write <= 1'b1;
        addr <= MIG_INTERFACE_REG_CTRL;
        wr_data <= {30'b0, 2'b10};
		
        // optional: disable the read; otherwise it will keep on reading;
        @(posedge clk_sys);
        write <= 1'b1;
        addr <= MIG_INTERFACE_REG_CTRL;
        wr_data <= {30'b0, 2'b00};
		
		// wait for the transaction to complete;
		// wait for the transaction complete status;
        @(posedge clk_sys);
        write <= 1'b0;
        read <= 1'b1;
        addr <= MIG_INTERFACE_REG_STATUS;
        
        @(posedge clk_sys);
        wait(rd_data[2] == 1);
            
		// read the 128-bit DDR2 into four read data registers;
        @(posedge clk_sys);
        read <= 1'b1;
		addr <= MIG_INTERFACE_REG_RDDATA_01;
		@(posedge clk_sys);
		assert(rd_data == 32'ha) $display("ok, rd_data: %10h", rd_data);
			else begin            
                $error("Sequential CPU transfer test: read data does not match with the written data");
                $error("stop the simulation at once");
                $stop;
            end        
        		
		@(posedge clk_sys);
        read <= 1'b1;
		addr <= MIG_INTERFACE_REG_RDDATA_02;
		@(posedge clk_sys);
		assert(rd_data == 32'hb) $display("ok, rd_data: %10h", rd_data);
			else begin            
                $error("Sequential CPU transfer test: read data does not match with the written data");
                $error("stop the simulation at once");
                $stop;
            end                
		
		@(posedge clk_sys);
        read <= 1'b1;
		addr <= MIG_INTERFACE_REG_RDDATA_03;
		@(posedge clk_sys);
		assert(rd_data == 32'hc) $display("ok, rd_data: %10h", rd_data);
			else begin            
                $error("Sequential CPU transfer test: read data does not match with the written data");
                $error("stop the simulation at once");
                $stop;
            end                
		
		@(posedge clk_sys);
        read <= 1'b1;
		addr <= MIG_INTERFACE_REG_RDDATA_04;
		@(posedge clk_sys);
		assert(rd_data == 32'hd) $display("ok, rd_data: %10h", rd_data);
			else begin            
                $error("Sequential CPU transfer test: read data does not match with the written data");
                $error("stop the simulation at once");
                $stop;
            end                
        
        #(100);
        
        /* test 04: change to hw test */
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_TEST;
                
        // current setup allows the led binary representation up to integer 32;
        // allow the led to be free running until when it hits 9;
        @(posedge clk_sys);
        wait(LED[LED_END_RANGE:0] == 9);
        
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_NONE;
        
        // observe that the led stops counting;
        #(500);
        
        // "re-enable" the test; expect the led to display from when it is stopped previously;
        // this is by construction since there is no built-in stop/start button for the hw test;
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_TEST;
        
        @(posedge clk_sys);
        assert(LED[LED_END_RANGE:0] != 1) $display("Ok, LED resumes from where it stops");
            else begin
                $error("LED resets, this is not expected, stop the simulation at once");
                $stop;
            end
            
        // allow the led to run until 21 then stops it;
        wait(LED[LED_END_RANGE:0] == 21);
        
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_NONE;
        
        #(100);
        
        
        /* test 05: change source to video core: motion detection */        
        // recall that in motion detection core; we deal with 128-bit transaction directly;
        // this is unlike cpu as cpu is limited by the 32-bit register width;        
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_MOTION;
        core_motion_rdstrobe <= 0;
        core_motion_wrstrobe <= 0;
        
        // prepare the addr and the write data before submitting;
        @(posedge clk_sys);
        core_motion_addr <= 7;
        core_motion_wrdata <= RANDOM_128BIT_WRDATA;
        // submit the write request;
        core_motion_wrstrobe <= 1;
        
        // disable after a write; otherwise, it will continue to write;
        @(posedge clk_sys);
        core_motion_wrstrobe <= 0;
        
        // wait for transaction to complete;
        @(posedge clk_sys);
        wait(core_MIG_transaction_complete == 1);
        
        // read from the previous write;
        @(posedge clk_sys);
        core_motion_addr <= 7;
        // submit the write request;
        core_motion_rdstrobe <= 1;        
        
        // disable after a read; otherwise, it will continue to read;
        @(posedge clk_sys);
        core_motion_rdstrobe <= 0;
                
        // wait for the transaction to complete;
        @(posedge clk_sys);
        wait(core_MIG_transaction_complete == 1);
        
        // data is valid to read;
        @(posedge clk_sys);
        assert(core_motion_rddata == RANDOM_128BIT_WRDATA) $display("core motion: read data matches: %10h", RANDOM_128BIT_WRDATA);
            else begin
                $error("core motion: read data does not match with the written data, stop the simulation at once");
                $stop;
            end
        
        #(100);
              
        /* test 06: burst write and read via video core: motion detection */
		// prepare an array of random data to write;
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_MOTION; i++) begin
            //TEST_ARRAY_CORE_MOTION[i] = {128{$random}};
             // urandom generates 32-bit pseudorandom number each time it is called;
            TEST_ARRAY_CORE_MOTION[i] = {$urandom(1*i+2),  $urandom(2*i+2),  $urandom(3*i+2),  $urandom(4*i+2)};                    
        end
        
        // burst write;
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_MOTION; i++) begin
            // setup;
            @(posedge clk_sys);                                
            core_motion_addr <= i;
            core_motion_wrdata = TEST_ARRAY_CORE_MOTION[i];        
            core_motion_wrstrobe <= 1'b1; // submit the write request;
            
            @(posedge clk_sys);
            // disable otherwise it will keep going;
            core_motion_wrstrobe <= 1'b0; // disable write;
            
            /*
            // submit the write request;
            @(posedge clk_sys);
            core_motion_wrstrobe <= 1'b1;                                            
            @(posedge clk_sys);
            core_motion_wrstrobe <= 1'b0; // disable write;
            */          
            // wait for the transaction to complete
            @(posedge clk_sys);
            wait(core_MIG_transaction_complete == 1'b1);
            
            //@(posedge clk_sys);        
        end
        
        // burst read;
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_MOTION; i++) begin
            // setup;
            @(posedge clk_sys);
            core_motion_addr <= i;                        
            core_motion_rdstrobe <= 1'b1; // submit the read request;                                            
            
            @(posedge clk_sys);
            // disable otherwise it will keep going;
            core_motion_rdstrobe <= 1'b0; 
            
            /*
            // submit the read request;
            @(posedge clk_sys);
            core_motion_rdstrobe <= 1'b1;                                            
            @(posedge clk_sys);
            core_motion_rdstrobe <= 1'b0; 
            */          
            
            // wait for the transaction to complete
            @(posedge clk_sys);
            wait(core_MIG_transaction_complete == 1'b1);
            
            @(posedge clk_sys);            
            // check if the read data matches with what it is written at a given address;
             assert(core_motion_rddata == TEST_ARRAY_CORE_MOTION[i]) 
             begin                
                $display("Burst Motion Core - Test index: %0d, Time; %t, Status: OK, read data matches with the written data at Address: %0d", i, $time, core_motion_addr);
             end  
             else begin 
                    $error("Burst Motion Core - Read Data does not match with the Written Data @ time: %t, Address: %0d", $time, core_motion_addr);
                    $error("Burst Motion Core - ERROR Encountered: terminate the simulation at once");                                                     
                    $stop;  // stop the simulation immediately upon discovering a mismatch; as this should not happen unless intended;                     
             end            
         end
         
        /* test 07: switch to the hw test */
        @(posedge clk_sys);
        write <= 1'b1;
        read <= 1'b0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_TEST;
        
            
        // allow it to wrap around twice after it hits 31;
        wait(LED[LED_END_RANGE:0] == 0);
        wait(LED[LED_END_RANGE:0] == 1);
        wait(LED[LED_END_RANGE:0] == 0);
        wait(LED[LED_END_RANGE:0] == 1);
        wait(LED[LED_END_RANGE:0] == 0);
                
        /* test 08: burst write and read via the cpu */
        /////// change the source to cpu;
        @(posedge clk_sys);
        cs <= 1;
        write <= 1;
        read <= 0;
        addr <= MIG_INTERFACE_REG_SEL;
        wr_data <= MIG_INTERFACE_REG_SEL_CPU;
        
        // disable write
        @(posedge clk_sys);
        cs <= 1;
        write <= 0;
        read <= 0;
                
        // prepare an array of random data to write;
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_CPU; i++) begin  
            //TEST_ARRAY_CORE_CPU[i] = {128{$random}};          
            // urandom generates 32-bit pseudorandom number each time it is called;
            TEST_ARRAY_CORE_CPU[i] = {$urandom(1*i+1),  $urandom(2*i+1),  $urandom(3*i+1),  $urandom(4*i+1)};        
        end
        
        ////// burst write;
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_CPU; i++) begin
            @(posedge clk_sys);
            read <= 0;
            write <= 1;
            addr <= MIG_INTERFACE_REG_WRDATA_01;
            wr_data <= TEST_ARRAY_CORE_CPU[i][31:0];
        
            @(posedge clk_sys);
            write <= 1;
            addr <= MIG_INTERFACE_REG_WRDATA_02;
            wr_data <= TEST_ARRAY_CORE_CPU[i][63:32];
        
            @(posedge clk_sys);
            write <= 1;
            addr <= MIG_INTERFACE_REG_WRDATA_03;
            wr_data <= TEST_ARRAY_CORE_CPU[i][95:64];
        
            @(posedge clk_sys);
            write <= 1;
            addr <= MIG_INTERFACE_REG_WRDATA_04;
            wr_data <= TEST_ARRAY_CORE_CPU[i][127:96];
        
            // prepare the write address;
            @(posedge clk_sys);
            write <= 1;
            addr <= MIG_INTERFACE_REG_ADDR;
            wr_data <= i;	// address index-based
        
            // submit the write request;
            @(posedge clk_sys);
            write <= 1'b1;
            addr <= MIG_INTERFACE_REG_CTRL;
            wr_data <= {31'b0, 1'b1};
        
            // disable the write otherwise it will keep writing;
            @(posedge clk_sys);
            write <= 1'b1;
            addr <= MIG_INTERFACE_REG_CTRL;
            wr_data <= {31'b0, 1'b0};
        
            // wait for the transaction complete status;
            @(posedge clk_sys);
            write <= 1'b0;
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_STATUS;
        
            @(posedge clk_sys);
            wait(rd_data[2] == 1);	
        end
        
        
        ///////////////////// burst read;
        
        for(int i = 0; i < TEST_ARRAY_SIZE_CORE_CPU; i++) begin
            // prepare the address;
            // maintain as the write address;
            @(posedge clk_sys);
            write <= 1;
            addr <= MIG_INTERFACE_REG_ADDR;
            wr_data <= i ; // index-based;
        
            // submit the read request;		
            @(posedge clk_sys);
            write <= 1'b1;
            addr <= MIG_INTERFACE_REG_CTRL;
            wr_data <= {30'b0, 2'b10};
        
            // optional: disable the read; otherwise it will keep on reading;
            @(posedge clk_sys);
            write <= 1'b1;
            addr <= MIG_INTERFACE_REG_CTRL;
            wr_data <= {30'b0, 2'b00};
        
            // wait for the transaction to complete;
            // wait for the transaction complete status;
            @(posedge clk_sys);
            write <= 1'b0;
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_STATUS;
        
            @(posedge clk_sys);
            wait(rd_data[2] == 1);
        
            ///////// read the 128-bit DDR2 into four read data registers;
        
            // first batch
            @(posedge clk_sys);
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_RDDATA_01;
            @(posedge clk_sys);
            assert(rd_data == TEST_ARRAY_CORE_CPU[i][31:0]) 
            begin
                $display("Burst CPU Core - Test index: %0d, Batch: 1; Time; %t, Status: OK, read data: %10h matches with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][31:0], i);
            end
            else begin            
                $display("Burst CPU Core - Test index: %0d, Batch: 1; Time; %t, Status: FAILED, read data: %10h DOES NOT match with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][31:0], i);
                $error("Burst Motion Core - ERROR Encountered: terminate the simulation at once");                                                     
                $stop;  // stop the simulation immediately upon discovering a mismatch; as this should not happen unless intended;
            end        
        
            // second batch
            @(posedge clk_sys);
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_RDDATA_02;
            @(posedge clk_sys);
            assert(rd_data == TEST_ARRAY_CORE_CPU[i][63:32]) 
            begin
                $display("Burst CPU Core - Test index: %0d, Batch: 2; Time; %t, Status: OK, read data: %10h matches with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][63:32], i);
            end
            else begin            
                $display("Burst CPU Core - Test index: %0d, Batch: 2; Time; %t, Status: FAILED, read data: %10h DOES NOT match with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][63:32], i);
                $error("Burst Motion Core - ERROR Encountered: terminate the simulation at once");                                                     
                $stop;  // stop the simulation immediately upon discovering a mismatch; as this should not happen unless intended;
            end        
        
            // third batch
            @(posedge clk_sys);
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_RDDATA_03;
            @(posedge clk_sys);
            assert(rd_data == TEST_ARRAY_CORE_CPU[i][95:64]) 
            begin
                $display("Burst CPU Core - Test index: %0d, Batch: 3; Time; %t, Status: OK, read data: %10h matches with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][95:64], i);
            end
            else begin            
                $display("Burst CPU Core - Test index: %0d, Batch: 3; Time; %t, Status: FAILED, read data: %10h DOES NOT match with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][95:64], i);
                $error("Burst Motion Core - ERROR Encountered: terminate the simulation at once");                                                     
                $stop;  // stop the simulation immediately upon discovering a mismatch; as this should not happen unless intended;
            end        
        
            // forth batch
            @(posedge clk_sys);
            read <= 1'b1;
            addr <= MIG_INTERFACE_REG_RDDATA_04;
            @(posedge clk_sys);
            assert(rd_data == TEST_ARRAY_CORE_CPU[i][127:96]) 
            begin
                $display("Burst CPU Core - Test index: %0d, Batch: 4; Time; %t, Status: OK, read data: %10h matches with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][127:96], i);
            end
            else begin            
                $display("Burst CPU Core - Test index: %0d, Batch: 4; Time; %t, Status: FAILED, read data: %10h DOES NOT match with the written data: %10h at Address: %0d", i, $time, rd_data, TEST_ARRAY_CORE_CPU[i][127:96], i);
                $error("Burst Motion Core - ERROR Encountered: terminate the simulation at once");                                                     
                $stop;  // stop the simulation immediately upon discovering a mismatch; as this should not happen unless intended;
            end        
        end

        $stop;
         
    end
endmodule

`endif //CORE_VIDEO_MIG_INTERFACE_TB_SV

