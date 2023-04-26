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
        SPI_DATA_BIT = 8,    // this is fixed usually;
        MAX_SPI_CLOCK_WIDTH = 16    // this is for covenience;
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
        output logic spi_data_or_command          // is the current MOSI a data or command for the slave?
    );
   
   // for cleaner view; 
   localparam REG_WIDTH = `REG_DATA_WIDTH_G;
   localparam REG_SPI_SCLK_W = `S5_SPI_REG_SCLK_WIDTH;
   localparam SPI_REG_ADDR_W = $clog2(`S5_SPI_TOTAL_REG_NUM);
   localparam SPI_TOTAL_STATUS_FLAG_NUM = `S5_SPI_REG_TOTAL_STATUS_NUM;
   localparam ZERO_PAD_RD_DATA_MISO = {(REG_WIDTH - SPI_DATA_BIT){1'b0}};
   localparam ZERO_PAD_RD_DATA_STATUS = {(REG_WIDTH - SPI_TOTAL_STATUS_FLAG_NUM){1'b0}};
   
   // register offset;
   /* !!! important ;!!! need to explict cast the bit width otherwise comparsion may resultt in false
   since other bits of the same address amy be unkonwn or other values */
   
   /* CAUTION for address decoding;
   cpu addr width is 5 bits;
   here we cast it as 3-bit wide for the internal register address;
   so if we were to decode the cpu addr to see if it matches the internal register address;
   , one may result in wrong result or undefined behaviour;
   since 5-bit wide is NOT equivalent to 3-bit wide address!!
   
   so we need to explicit make sure the comparison is done on the same bit-width;
   */
   
   localparam SPI_REG_STATUS = SPI_REG_ADDR_W'(`S5_SPI_REG_STATUS_OFFSET);
   localparam SPI_REG_SS = SPI_REG_ADDR_W'(`S5_SPI_REG_SS_OFFSET);
   localparam SPI_REG_MOSI_WR = SPI_REG_ADDR_W'(`S5_SPI_REG_MOSI_WR_OFFSET);
   localparam SPI_REG_MISO_RD = SPI_REG_ADDR_W'(`S5_SPI_REG_MISO_RD_OFFSET);
   localparam SPI_REG_CTRL = SPI_REG_ADDR_W'(`S5_SPI_REG_CTRL_OFFSET);
   localparam SPI_REG_SCLK = SPI_REG_ADDR_W'(`S5_SPI_REG_SCLK_MOD_OFFSET);
   localparam SPI_REG_DC = SPI_REG_ADDR_W'(`S5_SPI_REG_DC_OFFSET);
   
   
   // required for decoding as there are multiple register for writing/reading;
   logic wr_en;
   logic wr_ss;
   logic wr_spi_start;
   logic wr_ctrl;
   logic wr_sclk;
   logic wr_dc;
   logic rd_en;
   
   // SPI settings;   
   logic cpol;
   logic cpha;
   logic [MAX_SPI_CLOCK_WIDTH-1:0] sclk_mod;
   
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
     
     also, no need for miso reassmebled data;
     by the same reason above;
     
    */
   logic [REG_WIDTH-1:0] ctrl_reg, ctrl_next;
   logic[SPI_SLAVE_NUM-1:0] spi_ss_reg, spi_ss_next;
   logic [REG_WIDTH-1:0] spi_dc_reg, spi_dc_next;
   logic[MAX_SPI_CLOCK_WIDTH-1:0] spi_sclk_mod_reg, spi_sclk_mod_next;    // to program sclk;
   //logic spi_status_reg, spi_status_next;
   
    
   // spi controller instantiation;
   spi_sys spi_controller
   (
    .clk(clk),
    .reset(reset),
    .mosi_data_write(wr_data[SPI_DATA_BIT-1:0]),
    .count_mod(sclk_mod),
    //.count_mod(spi_sclk_mod_reg),
    //.count_mod(16'(3'b100)),
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
                // status;
                //spi_status_reg <= {REG_WIDTH{1'b1}};    // after reset, spi should be free;
                
                // zero means the spi sclk is disabled;
                spi_sclk_mod_reg <= {MAX_SPI_CLOCK_WIDTH{1'b0}};
                //spi_sclk_mod_reg <= MAX_SPI_CLOCK_WIDTH'(4);
                                
                // by default, {cpol, cpha} = {0,0};
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPOL] <= 1'b0;
                ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPHA] <= 1'b0;
                
                //  all slave is NOT selected; (active LOW);
                spi_ss_reg <= {SPI_SLAVE_NUM{1'b1}};
                
                // command or data? data;
                spi_dc_reg <= {REG_WIDTH{1'b1}};
            end
        else
            begin
                //spi_status_reg <= spi_status_next;
                
                if(wr_sclk)
                    spi_sclk_mod_reg <= spi_sclk_mod_next;
                if(wr_ctrl)
                    ctrl_reg <= ctrl_next;
                if(wr_ss)
                    spi_ss_reg <= spi_ss_next;
                if(wr_dc)
                    spi_dc_reg <= spi_dc_next;
            end    
   
   // decoding;
   
   assign wr_en         = write && cs;
   assign wr_ss         = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_SS);
   assign wr_spi_start  = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_MOSI_WR);   // auto;
   //assign wr_spi_start  = wr_en && (addr[SPI_REG_ADDR_W-1:0] == 3'b010);   // auto;
   //assign wr_spi_start  = wr_en && (addr[2:0] == 3'b010);   // auto;
   assign wr_ctrl       = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_CTRL);
   assign wr_sclk       = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_SCLK);
   assign wr_dc         = wr_en && (addr[SPI_REG_ADDR_W-1:0] == SPI_REG_DC);
   
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
   assign spi_sclk_mod_next = wr_data[MAX_SPI_CLOCK_WIDTH-1:0];
   assign spi_dc_next       = wr_data;
   
   //assign spi_status_next   = spi_ready_flag;
   
   // input to the spi system;
   assign cpol = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPOL];
   assign cpha = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_CPHA];
   assign sclk_mod = spi_sclk_mod_reg;
   
   // output to the processor;
   //assign spi_data_or_command = ctrl_reg[`S5_SPI_REG_CTRL_BIT_POS_DC];
   assign spi_data_or_command = spi_dc_reg[`S5_SPI_REG_DC_BIT_POS_DC];
   
   assign spi_ss_n = spi_ss_reg;
   
   // read;
   assign rd_en = read && cs;   // this is actually not necessary;
   always_comb
   begin
        // default;
        rd_data = 0;
        case({rd_en, addr[SPI_REG_ADDR_W-1:0]})
        //case({rd_en, addr[2:0]})
            {1'b1, SPI_REG_MISO_RD} : rd_data = {ZERO_PAD_RD_DATA_MISO, spi_miso_reassembled};
            //{1'b1, SPI_REG_STATUS}  : rd_data = {ZERO_PAD_RD_DATA_STATUS, spi_status_next};
            {1'b1, SPI_REG_STATUS}  : rd_data = {ZERO_PAD_RD_DATA_STATUS, spi_ready_flag};
            //{1'b1, SPI_REG_STATUS}  : rd_data = {31'b0, spi_ready_flag};
            //{1'b1, 3'b0}  : rd_data = {31'b0, spi_ready_flag};
            //{1'b1, 3'b011} : rd_data = {24'b0, spi_miso_reassembled};
            //{1'b1, 3'b000} : rd_data = {31'b0, spi_ready_flag};
            default                 : ; // nop
        endcase
    end
endmodule

`endif // CORE_SPI_SV