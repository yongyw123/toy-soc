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

`include "IO_map.svh"

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
    
    
    localparam LED_END_RANGE = 4;
        
    // address;
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
                
        /* initial reset pulse */
        wait(locked == 1'b1);
        reset_sys = 1'b1;
        #(100);
        reset_sys = 1'b0;
        #(100);
        
        
        /* test 01: read the status via cpu*/
        @(posedge clk_sys);
        read <= 1;
        addr <= MIG_INTERFACE_REG_STATUS;
        // wait for init complete;
        wait(rd_data[0] == 1);  
        #(100);
        $stop;
        
        // other status must either hold true/high after init is completed;
        // until something changes;
        
        // transaction complete must be low since there is no request;
        /*
        @(posedge clk_sys);
        #(100);
        assert(rd_data[2] == 0) $display("ok");
            else $error("transaction complete status is not low;");
         // controller must be idle;
        assert(rd_data[3] == 1) $display("ok");
            else $error("controller is not idle");   
        
        #(100);
        */
        
        /* test 02: write and read via the cpu */
        /*
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
        assert(rd_data[2] == 1) $display("ok, transaction complete status is detected;");
            else $error("expected transaction complete status to be high;");
        
        #(100);
        
        */
        
        
        
        $stop;
         
    end
endmodule

`endif //CORE_VIDEO_MIG_INTERFACE_TB_SV

