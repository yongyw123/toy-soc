`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 23:05:40
// Design Name: 
// Module Name: core_video_lcd_display
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

`ifndef CORE_VIDEO_LCD_DISPLAY_SV
`define CORE_VIDEO_LCD_DISPLAY_SV

`include "IO_map.svh"


/**************************************************************
* V0_DISP_LCD
--------------------
this core wraps this module: LCD display controller 8080;
this is for the ILI9341 LCD display via mcu 8080 (protocol) interface;

Register Map
1. register 0 (offset 0): read register 
2. register 1 (offset 1): program write clock period
3. register 2 (offset 2): program read clock period;
4. register 3 (offset 3): write register;
5. register 4 (offset 4): stream control register;
6. register 5 (offset 5): chip select (CSX) register
7. register 6 (offset 6): data or command (DCX) register

Register Definition:
1. register 0: status and read data register
        bit[7:0]    : data read from the lcd;
        bit[8]      : ready flag;  // the lcd controller is idle
                        1: ready;
                        0: not ready;
        bit[9]      : done flag;   // [optional ??] when the lcd just finishes reading or writing;
                        1: done;
                        0: not done;
        
2. register 1: program the write clock period;
        bit[15:0] defines the clock counter mod for LOW WRX period;
        bit[31:16] defines the clock counter mod for HIGH WRX period;

2. register 2: program the read clock period;
        bit[15:0] defines the clock counter mod for LOW RDX period;
        bit[31:16] defines the clock counter mod for HIGH RDX period;

3. register 3: write data and data mode;
        bit[7:0]    : data to write to the lcd;
        bit[9:8]  : to store user commands;
        
4. register 4: stream control register
            there are two flows:
            flow one is from thh processor (hence SW app/driver);
            flow two is from other video source stream such as the camera;
            flow two will be automatically completed through a feedback loop
            via handshaking mechanism without any user/processor intervention
            until this stream control is updated again;
             
        bit[0]: 
            1 for stream flow;
            0 for processor flow; 

5. register 5: chip select;
            this is probably not necessary;
            since this could be done using general purpose pin;
            and emulated through SW;
            bit[0]  
                0: chip deselect;
                1: chip select
6. register 6: data or command (DCX);
            bit[0] : is the data to write a DATA or a COMMAND for the LCD?
                0 for data;
                1 for command;
    
Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;
4. register 3: write only;
5. register 4: write only;
6. register 5: write only;
7. register 6: write only;
******************************************************************/
module core_video_lcd_display
    #(
        parameter 
        BITS_PER_PIXEL = 16,  // bpp
        PARALLEL_DATA_BITS = 8 // how many data bits could be driven to teh lcd?
        
    )
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with video controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`VIDEO_REG_ADDR_BIT_SIZE_G-1:0] addr,  //  19-bit;         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
           
        /* hw pin specific to the lcd controller; */
        output logic lcd_drive_wrx,     //  to drive the lcd for write op;
        output logic lcd_drive_rdx,     // to drive the lcd for read op;
        output logic lcd_drive_csx,     // chip seletc;
        output logic lcd_drive_dcx,     // data or command; LOW for command;          
        inout tri[PARALLEL_DATA_BITS-1:0] lcd_dinout, // this is shared between the host and the lcd;
        
        /* stream flow:
        interface with this fifo module:
        fifo_core_video_lcd_display();
        
        note that in the flow;
        1. it is assummed to be CMD_WR;
        2. data type is always Data (not command);
        3. chip select will always be selected;
        */
        input logic [PARALLEL_DATA_BITS-1:0] stream_in_pixel_data,
        input logic stream_valid_flag,       // a lcd start write request from the fifo;
        output logic stream_ready_flag    // request a read from the fifo for more pixel;

    );
    
    // register offset constanst;
    localparam REG_WR_CLOCKMOD_OFFSET   = 3'b001;
    localparam REG_RD_CLOCKMOD_OFFSET   = 3'b010;
    localparam REG_WR_DATA_OFFSET       = 3'b011; 
    localparam REG_STREAM_CTRL_OFFSET   = 3'b100;
    localparam REG_CSX_OFFSET           = 3'b101;
    localparam REG_DCX_OFFSET           = 3'b110;
    
    // available commands;
    localparam CMD_NOP  = 2'b00;
    localparam CMD_WR   = 2'b01;
    localparam CMD_RD   = 2'b10;
    
    localparam BIT_POS_CMD_LSB = 8;
    localparam BIT_POS_CMD_MSB = 9;
    
    // stream control;
    localparam STREAM_CTRL_CPU      = 1'b0;      // from the processor;
    localparam STREAM_CTRL_VIDEO    = 1'b1;    // from other sources;
    
    // enabler signals
    logic wr_en;
    logic wr_en_data;
    logic wr_en_clockmod_wrx;
    logic wr_en_clockmod_rdx;
    logic wr_en_stream_ctrl;
    logic wr_en_csx;
    logic wr_en_dcx;
    
    /* argument for lcd_8080_interface_controller() */
    logic lcd_ready_flag;
    logic lcd_done_flag;
    logic lcd_user_start;
    logic [1:0] lcd_user_cmd;
    logic [PARALLEL_DATA_BITS-1:0] lcd_wr_data;
    logic [PARALLEL_DATA_BITS-1:0] lcd_rd_data;
    
    // set the write cycle time;
    logic [15:0] lcd_set_wr_mod_fhalf;    // first half of the write clock;     
    logic [15:0] lcd_set_wr_mod_shalf;    // second half of the write clockl
        
    // set the read cycle time;
    logic [15:0] lcd_set_rd_mod_fhalf;    // first halfl;
    logic [15:0] lcd_set_rd_mod_shalf;    // first halfl;

    
    /* register;
    only user_cmd is registered in the lcd_8080_interface_controller() module;
    so for the rest, we need to create registers
    */
    logic [31:0] set_wrx_period_mod_reg, set_wrx_period_mod_next;
    logic [31:0] set_rdx_period_mod_reg, set_rdx_period_mod_next;
    logic [31:0] wr_data_reg, wr_data_next;  
    logic stream_flow_reg, stream_flow_next;
    logic csx_reg, csx_next;
    logic dcx_reg, dcx_next;
    
    
    // ff;
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            wr_data_reg <= 0;
            set_wrx_period_mod_reg <= 0;    // this is equivalent to disabling wrx;
            set_rdx_period_mod_reg <= 0;    // this is equivalent to disabling rdx;
            stream_flow_reg <= 0;   // processor control;
            csx_reg <= 1'b0;        // chip deselect (active low);
            dcx_reg <= 1'b0;        // it is non-command;
        end
        else begin
            if(wr_en_data)
                wr_data_reg <= wr_data_next;
            if(wr_en_clockmod_wrx)
                set_wrx_period_mod_reg <= set_wrx_period_mod_next;
            if(wr_en_clockmod_rdx) 
                set_rdx_period_mod_reg <= set_rdx_period_mod_next;
            if(wr_en_stream_ctrl)
                stream_flow_reg <= stream_flow_next;  
            if(wr_en_csx)
                csx_reg <= csx_next;
            if(wr_en_dcx)
                dcx_reg <= dcx_next;
        end
        
    
    // decoding;
    assign wr_en = cs && write;
    assign wr_en_data           = wr_en && (addr[2:0] == REG_WR_DATA_OFFSET);
    assign wr_en_clockmod_wrx   = wr_en && (addr[2:0] == REG_WR_CLOCKMOD_OFFSET);
    assign wr_en_clockmod_rdx   = wr_en && (addr[2:0] == REG_RD_CLOCKMOD_OFFSET);
    assign wr_en_stream_ctrl    = wr_en && (addr[2:0] == REG_STREAM_CTRL_OFFSET);
    assign wr_en_csx            = wr_en && (addr[2:0] == REG_CSX_OFFSET);
    assign wr_en_dcx            = wr_en && (addr[2:0] == REG_DCX_OFFSET);
        
    // next state;
    assign wr_data_next             = wr_data;
    assign set_wrx_period_mod_next  = wr_data;
    assign set_rdx_period_mod_next  = wr_data;
    assign stream_flow_next         = wr_data[0];   // only one bit;
    assign csx_next                 = wr_data[0];
    assign dcx_next                 = wr_data[0];
    
    // lcd configuration; requires processor for this;
    assign lcd_set_wr_mod_fhalf = set_wrx_period_mod_reg[15:0];
    assign lcd_set_wr_mod_shalf = set_wrx_period_mod_reg[31:16];
    
    assign lcd_set_rd_mod_fhalf = set_rdx_period_mod_reg[15:0];
    assign lcd_set_rd_mod_shalf = set_rdx_period_mod_reg[31:16];
    
    
    // to the lcd;
    /*
    multiplex depending on which is the source;
    the processor
    or 
    video stream (pixel generation)
    ?
    */
    always_comb 
    begin
        case(stream_flow_reg)
        
            STREAM_CTRL_VIDEO: begin
                lcd_wr_data = stream_in_pixel_data;
                /*
                // it is pixel generation source to be written to the lcd;
                so it must always be:
                1. write command;
                2. data mode (not command);
                3. chip select enabled (for convenience);
                */
                lcd_user_cmd = CMD_WR;  
                lcd_drive_csx = 1'b0;   // active low;
                lcd_drive_dcx = 1'b1;   // otherwise, it is interpreted as a command;
                
                // when to start;
                // when the fifo has valid pixel to be displayed;
                lcd_user_start = stream_valid_flag;
                
                // broadcast its status to other video cores;
                stream_ready_flag = lcd_ready_flag;
            end
        
            // cpu control;
            default: begin
                lcd_wr_data = wr_data_reg[7:0];
                lcd_user_cmd = wr_data_reg[BIT_POS_CMD_MSB : BIT_POS_CMD_LSB];
                
                // auto start when wr/rd cmd;
                lcd_user_start = (wr_data_reg[BIT_POS_CMD_MSB : BIT_POS_CMD_LSB] != CMD_NOP);        
                
                // hw active low signal;
                //lcd_drive_csx = !wr_data_reg[`V0_DISP_LCD_REG_WR_DATA_BIT_POS_CSX]; 
                lcd_drive_csx = !csx_reg;
                
                // hw active low signal;
                //lcd_drive_dcx = !wr_data_reg[`V0_DISP_LCD_REG_WR_DATA_BIT_POS_DCX];
                lcd_drive_dcx = !dcx_reg;
                
                // always disable the stream ready flag;
                // otherwise, it will unintentionally draw out the src fifo;
                stream_ready_flag = 1'b0; 
            end        
        endcase
    end
  
    
    // instantiation;
    lcd_8080_interface_controller
    #(.PARALLEL_DATA_BITS(PARALLEL_DATA_BITS)) 
    display_ctrl    
    (
       .clk(clk),
       .reset(reset),
       
       // set the write cycle time;
       .set_wr_mod_fhalf(lcd_set_wr_mod_fhalf),    // first half of the write clock;     
       .set_wr_mod_shalf(lcd_set_wr_mod_shalf),    // second half of the write clockl
        
        // set the read cycle time;
        .set_rd_mod_fhalf(lcd_set_rd_mod_fhalf),    // first halfl;
        .set_rd_mod_shalf(lcd_set_rd_mod_shalf),    // first halfl;

        // user argument;      
        .user_start(lcd_user_start),     // start communicating with the lcd;        
        .user_cmd(lcd_user_cmd),       // read or write?
        
        .wr_data(lcd_wr_data),   
        .rd_data(lcd_rd_data),

        // status;
        .ready_flag(lcd_ready_flag),    // idle;
        .done_flag(lcd_done_flag),     // just finish the rd/wr operation;
        
        /* hw pins 
        note that there are other hw pins not listed here;
        dcx, rst, and cs;
        these pins could be configured as general pins;
        not necessary to integrate here;       
        */
        .drive_wrx(lcd_drive_wrx),   //  to drive the lcd for write op;
        .drive_rdx(lcd_drive_rdx),   // to drive the lcd for read op;          
        .dinout(lcd_dinout) // this is shared between the host and the lcd;
       );
   
    
    /* only one read register to accommodate all the data;
    so no need to multiple */
    assign rd_data = {31'b0, lcd_ready_flag, lcd_done_flag, lcd_rd_data};
    
    
endmodule

`endif //CORE_VIDEO_LCD_DISPLAY_SV