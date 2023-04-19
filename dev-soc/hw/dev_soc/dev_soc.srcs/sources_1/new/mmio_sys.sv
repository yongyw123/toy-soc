`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2023 00:23:53
// Design Name: 
// Module Name: mmio_sys
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: wrapper (system) of mmio controller and its IO cores;
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`ifndef _MMIO_SYS_SV
`define _MMIO_SYS_SV

`include "IO_map.svh"

module mmio_sys
    #(
        parameter 
        SW_NUM = 8,   // number of switches at the GPI port;
        LED_NUM = 8,  // number of LED at the GPO port;
        PORT_NUM = 4,  // number of port for GPIO (board PMOD jumper)
        
        UART_DATA_BIT = 8,                  // number of UART data bits;
        UART_STOP_BIT_SAMPLING_NUM = 16,    // this corresponds to one stop bit; (16 oversampling);
        
        SPI_DATA_BIT = 8,     
        SPI_SLAVE_NUM = 1,  // how many connected SPI slaves on the same board SPI core?
        
        I2C_DATA_BIT = 8
    )
    (
    // general;
    input logic clk,    // 100 MHz;
    input logic reset,  // async;
    
    /*
    // user bus interface;
    // where user bus is bridged by the microblaze MCS IO bus;
    */
    input logic mmio_cs,        // chip select for mmio system;
    input logic mmio_wr,
    input logic mmio_rd,
    input logic [`BUS_USER_SIZE_G-1:0] mmio_addr, // addr to decode for IO core address and its register address;
    input logic [`REG_DATA_WIDTH_G-1:0] mmio_wr_data,   // 32-bit'
    output logic [`REG_DATA_WIDTH_G-1:0] mmio_rd_data,   // 32-bit;
    
    /* HW pin mapping (by the constraint file) */
    input logic [SW_NUM-1:0] sw, // gpi
    output logic [LED_NUM-1:0] led,  // gpo;
    inout tri[PORT_NUM-1:0] pmod,    // tristate for gpio;
    
    // uart;
    input logic uart_rx,    // receiver;
    output logic uart_tx,   // transmitter;
    
    // spi;
    output logic spi_sclk,  // spi clock; to synchronize with the slave;
    output logic spi_mosi,  // spi mosi bit to the slave;
    input logic spi_miso,   // spi slave data bit;
    output logic [SPI_SLAVE_NUM-1:0] spi_ss_n,  // multiple slave selects;
    output logic spi_data_or_command,            // is the mosi a data or command for the slave?
    
    // i2c master;
    output tri i2c_scl, // i2c master clock (note, it must be in tristate);
    inout tri i2c_sda   // sda line; note it is inout type since sda line is shared; 
    
    );
    
    /* ----- broadcasting arrays; */
    // individual control signals for each core;
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_cs_array; // chip select;
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_wr_array; // write enable; 
    logic [`MIMO_CORE_TOTAL_G-1:0] core_ctrl_rd_array; // read enable;
    
    // input, output, and register data for each core;
    logic [`REG_ADDR_SIZE_G-1:0] core_addr_reg_array[`MIMO_CORE_TOTAL_G-1:0]; // register of each core;
    logic [`REG_DATA_WIDTH_G-1:0] core_data_rd_array[`MIMO_CORE_TOTAL_G-1:0]; // read data from each core;
    logic [`REG_DATA_WIDTH_G-1:0] core_data_wr_array[`MIMO_CORE_TOTAL_G-1:0]; // write data from each core;
    
    /* ------- instantiation;
    1. mmio_controller;
    2. core_gpo;
    3. core_gpi;
    4. core timer;
    -----------------------*/
    
    // controller;
    mmio_ctrl ctrl_unit
    (
        .clk(clk),
        .reset(reset),
        
        // system control sigmals;
        .mmio_cs(mmio_cs),  
        .mmio_rd(mmio_rd),
        .mmio_wr(mmio_wr),
        
        // address to decode;
        .mmio_addr(mmio_addr),
        
        // data;
        .mmio_wr_data(mmio_wr_data),
        .mmio_rd_data(mmio_rd_data),
        
        // broadcaster to all io cores;
        .core_ctrl_cs_array(core_ctrl_cs_array),    // chip select for each io;    
        .core_ctrl_wr_array(core_ctrl_wr_array),    // write enable for each io;
        .core_ctrl_rd_array(core_ctrl_rd_array),    // read enable for each io;
        .core_data_wr_array(core_data_wr_array),    // write data;
        .core_data_rd_array(core_data_rd_array),    // data to multiplex
        .core_addr_reg_array(core_addr_reg_array)    // register address to decode;      
    );
    
    // timer core;
    core_timer timer_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S0_SYS_TIMER]),
        .write(core_ctrl_wr_array[`S0_SYS_TIMER]),
        .read(core_ctrl_rd_array[`S0_SYS_TIMER]),
        .addr(core_addr_reg_array[`S0_SYS_TIMER]),
        .wr_data(core_data_wr_array[`S0_SYS_TIMER]),
        .rd_data(core_data_rd_array[`S0_SYS_TIMER])    
    );
    
    // uart core;
    core_uart
    #(
       .UART_DATA_BIT(UART_DATA_BIT),
       .UART_STOP_BIT_SAMPLING_NUM(UART_STOP_BIT_SAMPLING_NUM),
       .FIFO_ADDR_WIDTH(8), // uart fifo address; could hold up to 2^{8} = 64 data;
       .FIFO_DATA_WIDTH(UART_DATA_BIT)
    )
    uart_unit
    (
        .clk(clk),
        .reset(reset),
        
        // bus interface;
        .cs(core_ctrl_cs_array[`S1_UART_DEBUG]),
        .write(core_ctrl_wr_array[`S1_UART_DEBUG]),
        .read(core_ctrl_rd_array[`S1_UART_DEBUG]),
        .addr(core_addr_reg_array[`S1_UART_DEBUG]),
        .wr_data(core_data_wr_array[`S1_UART_DEBUG]),
        .rd_data(core_data_rd_array[`S1_UART_DEBUG]),
        
        // mapped with the board uart pins;
        .tx(uart_tx),
        .rx(uart_rx)
    );
    
    // general purpose output core;
    core_gpo #(.W(LED_NUM)) gpo_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S2_GPO_LED]),
        .write(core_ctrl_wr_array[`S2_GPO_LED]),
        .read(core_ctrl_rd_array[`S2_GPO_LED]),
        .addr(core_addr_reg_array[`S2_GPO_LED]),
        .wr_data(core_data_wr_array[`S2_GPO_LED]),
        .rd_data(core_data_rd_array[`S2_GPO_LED]),
        .dout(led)  // mapped with the board leds
    );
    
    // general purpose input core;
    core_gpi #(.W(SW_NUM)) gpi_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S3_GPI_SW]),
        .write(core_ctrl_wr_array[`S3_GPI_SW]),
        .read(core_ctrl_rd_array[`S3_GPI_SW]),
        .addr(core_addr_reg_array[`S3_GPI_SW]),
        .wr_data(core_data_wr_array[`S3_GPI_SW]),
        .rd_data(core_data_rd_array[`S3_GPI_SW]),
        .din(sw)    // mapped with the board switches;
    ); 
    
    // general purpose input and output;
    core_gpio #(.PORT_WIDTH(PORT_NUM)) gpio_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S4_GPIO_PORT]),
        .write(core_ctrl_wr_array[`S4_GPIO_PORT]),
        .read(core_ctrl_rd_array[`S4_GPIO_PORT]),
        .addr(core_addr_reg_array[`S4_GPIO_PORT]),
        .wr_data(core_data_wr_array[`S4_GPIO_PORT]),
        .rd_data(core_data_rd_array[`S4_GPIO_PORT]),
        .dinout(pmod)    // this is a tristate, mapped to the board jumper (pmod);
    
    ); 
    
    // spi core;
    core_spi #(.SPI_DATA_BIT(SPI_DATA_BIT), .SPI_SLAVE_NUM(SPI_SLAVE_NUM)) spi_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S5_SPI]),
        .write(core_ctrl_wr_array[`S5_SPI]),
        .read(core_ctrl_rd_array[`S5_SPI]),
        .addr(core_addr_reg_array[`S5_SPI]),
        .wr_data(core_data_wr_array[`S5_SPI]),
        .rd_data(core_data_rd_array[`S5_SPI]),
        
        // spi specific pin;
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss_n(spi_ss_n),
        .spi_data_or_command(spi_data_or_command)
    );
     
    // i2c core;
    core_i2c_master #(.I2C_DATA_BIT(I2C_DATA_BIT)) i2c_master_unit
    (
        .clk(clk),
        .reset(reset),
        .cs(core_ctrl_cs_array[`S6_I2C_MASTER]),
        .write(core_ctrl_wr_array[`S6_I2C_MASTER]),
        .read(core_ctrl_rd_array[`S6_I2C_MASTER]),
        .addr(core_addr_reg_array[`S6_I2C_MASTER]),
        .wr_data(core_data_wr_array[`S6_I2C_MASTER]),
        .rd_data(core_data_rd_array[`S6_I2C_MASTER]),
        
        // i2c specific;
        .scl(i2c_scl),
        .sda(i2c_sda)
        
    );
    
    /* ground the the read data signals from the empty io cores 
    for vivao synthesis optimization to opt out these unused signals */
    generate
        genvar i;
            for(i = 7; i < `MIMO_CORE_TOTAL_G; i++)
            begin
                // always HIGH ==> idle ==> not signals;
                assign core_data_rd_array[i] = 32'hFFFF_FFFF;
            end
        endgenerate

endmodule

`endif // _MMIO_SYS_SV;