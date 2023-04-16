`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 18:10:30
// Design Name: 
// Module Name: core_spi
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

`ifndef CORE_SPI_SV
`define CORE_SPI_SV

`include "IO_map.svh"


module core_spi
    #(
        parameter 
        SPI_SLAVE_NUM = 1, // number of spi slaves for the master?
        SPI_DATA_BIT = 8    // this is fixed usually;
    )
    
    (
        // general;
        input logic clk,    // 100 MHz;
        input logic reset,  // async;
        
        //> given interface with mmio controller (which interfaces with the bus);
        // note that not all interfacce will be used;
        input logic cs,    
        input logic write,              
        input logic read,               
        input logic [`REG_ADDR_SIZE_G-1:0] addr,         
        input logic [`REG_DATA_WIDTH_G-1:0]  wr_data,    
        output logic [`REG_DATA_WIDTH_G-1:0]  rd_data,
        
        /* EXTERNAL PINS: spi specific;*/
        // spi standard signals;
        output logic spi_sclk,
        output logic spi_mosi,
        input logic spi_miso,
        
        // extra SPI pins; 
        // note that this depends on the slave device specs;
        output logic[SPI_SLAVE_NUM-1:0] spi_ss_n,    // low to assert a given slave;
        output logic spi_data_or_command,            // is the current MOSI a data or command for the slave?  
     
        // debug;
        output logic[SPI_SLAVE_NUM-1:0] spi_ss_reg,    // low to assert a given slave;
        output logic[SPI_SLAVE_NUM-1:0] spi_ss_next    // low to assert a given slave;
    );
   
   // for cleaner view; 
   localparam REG_WIDTH = `REG_DATA_WIDTH_G;
   localparam REG_SPI_SCLK_W = `S5_SPI_REG_SCLK_WIDTH;
   localparam SPI_REG_ADDR_W = $clog2(`S5_SPI_TOTAL_REG_NUM);
   localparam SPI_TOTAL_STATUS_FLAG_NUM = `S5_SPI_REG_TOTAL_STATUS_NUM;
   localparam ZERO_PAD_RD_DATA_MISO = {(REG_WIDTH - SPI_DATA_BIT){1'b0}};
   localparam ZERO_PAD_RD_DATA_STATUS = {(REG_WIDTH - SPI_TOTAL_STATUS_FLAG_NUM){1'b0}};
   
   // register offset;
   localparam SPI_REG_STATUS = `S5_SPI_REG_STATUS_OFFSET;
   localparam SPI_REG_SS = `S5_SPI_REG_SS_OFFSET;
   localparam SPI_REG_MOSI_WR = `S5_SPI_REG_MOSI_WR_OFFSET;
   localparam SPI_REG_MISO_RD = `S5_SPI_REG_MISO_RD_OFFSET;
   localparam SPI_REG_CTRL = `S5_SPI_REG_CTRL_OFFSET;
   localparam SPI_REG_SCLK = `S5_SPI_REG_SCLK_MOD_OFFSET;
   
   // required for decoding as there are multiple register for writing/reading;
   logic wr_en;
   logic wr_ss;
   logic wr_spi_start;
   logic wr_ctrl;
   logic rd_en;
   
   // SPI settings;   
   logic cpol;
   logic cpha;
   logic sclk_mod;
   
   // reassmebled miso slave data;
   logic [SPI_DATA_BIT-1:0] spi_miso_reassembled;
   
   // spi status;
   logic spi_ready_flag;

    /*
     registers;
     
     note that there is no need to create another register for MOSI write data;
     instead, we could just plug in wr_data from the processor directly
     to the spi_sys module at port mosi_data_write;
     this is because spi_sys itself already has a register to hold this;
     
    */
   logic [REG_WIDTH-1:0] ctrl_reg, ctrl_next;
   logic[SPI_SLAVE_NUM-1:0] spi_ss_reg, spi_ss_next;
   logic[REG_WIDTH-1:0] spi_sclk_mod_reg, spi_sclk_mod_next;    // to program sclk;
   
   // spi controller instantiation;
   spi_sys spi_controller
   (
    .clk(clk),
    .reset(reset),
    .mosi_data_write(wr_data[SPI_DATA_BIT-1:0]),
    .count_mod(sclk_mod),
    .cpol(cpol),
    .cpha(cpha),
    .start(wr_spi_start),
    .miso_assembled_data(spi_miso_reassembled),
    .spi_complete_flag(),   // not needed;
    .spi_ready_flag(spi_ready_flag),
    .sclk(spi_sclk),
    .mosi(spi_mosi),
    .miso(spi_miso)
   );
   
   // register ;
   always_ff @(posedge clk, posedge reset)
        if(reset)
            begin
                // zero means the spi sclk is disabled;
                spi_sclk_mod_reg <= {REG_WIDTH{1'b0}};
                                
                // by default, {cpol, cpha} = {0,0};
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPOL] <= 1'b0;
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPHA] <= 1'b0;
                
                // spi data is interpreted as data (not command) for the slave;    
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_DC] <= 1'b1;
                
                //  all slave is NOT selected; (active LOW);
                spi_ss_reg <= {SPI_SLAVE_NUM{1'b1}};
            end
        else
            begin
                if(wr_sclk)
                    spi_sclk_mod_reg <= spi_sclk_mod_next;
                if(wr_ctrl)
                    ctrl_reg <= ctrl_next;
                if(wr_ss)
                    spi_ss_reg <= spi_ss_next;
            end    
   
   // decoding;
   assign wr_en         = write && cs;
   assign wr_ss         = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_SS);
   assign wr_spi_start  = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_MOSI_WR);
   assign wr_ctrl       = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_CTRL);
   assign wr_sclk       = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_SCLK);
   
   /* DO NOT DO THE FOLLOWING; BAD PRACTICE!!!
   // instead, put the (wr_XX) enable signals on th flip flop above;
   // this is because it is possible that any of this signals are in an unknown state;
   // which will render it to be unknown as well;
   
   BAD CODE:
   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   assign spi_ss_next       = (wr_ss) ? wr_data[SPI_SLAVE_NUM-1:0] : spi_ss_reg;
   assign ctrl_next         = (wr_ctrl) ? wr_data : ctrl_reg;
   assign spi_sclk_mod_next = (wr_sclk) ? wr_data : spi_sclk_mod_reg;
   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   
   ???? WHY ??
   // for exmaple; take ss;
   after reset, spi_ss_reg is all HIGH;
   but write and cs are undefined (unknown);
   this means that wr_ss is alos unknown;
   ==> spi_ss_next could take either value; hence unknnown;
   at the next clock edge, if wothout a conditional safeguard,
   the flip flop will clock in this unknown value;
   i.e
   
   always_ff @(posedge clk)
        spi_ss_reg <= spi_ss_next;
        
    by above, we have spi_ss_reg as unknown;
    since this is assigned as the output logic, spi_ss_n pin;
    it is alos unknown as well;
   
   */
   
   // OK CODE in contrast to the above;
   assign spi_ss_next       = wr_data[SPI_SLAVE_NUM-1:0];
   assign ctrl_next         = wr_data;
   assign spi_sclk_mod_next = wr_data;
   
   // input to the spi system;
   assign cpol = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPOL];
   assign cpha = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPHA];
   assign sclk_mod = spi_sclk_mod_reg;
   
   // output to the processor;
   assign spi_data_or_command = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_DC];
   assign spi_ss_n = spi_ss_reg;
   
   // read;
   assign rd_en = read && cs;   // this is actually not necessary;
   always_comb
        case({rd_en, addr[SPI_REG_ADDR_W-1:0]})
            {1'b1, SPI_REG_MISO_RD} : rd_data = {ZERO_PAD_RD_DATA_MISO, spi_miso_reassembled};
            {1'b1, SPI_REG_STATUS}  : rd_data = {ZERO_PAD_RD_DATA_STATUS, spi_ready_flag};
            default                 : ; // nop
        endcase
endmodule

`endif // CORE_SPI_SV