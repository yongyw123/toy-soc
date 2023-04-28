`ifndef _IO_MAP_SVH
`define _IO_MAP_SVH

/*
*  Memory-mapped for MicroBlaze MCS;
*  The instantiated MCS only has the CPU (processor) added;
*  The rest of the IO module such as GPIO, UART, Timer, etc are constructed from the user;
*  
* Assumption:
* 32-bit address space;
* byte addressable;
*
* Register Space (Address Map) for the MCS:
* by above, we only need to know the IO bus address;
* this address region shall host the to-be-constructed IO cores/modules;
* IO bus address: 0xC0000000 - 0xFFFFFFFF; mapped to IO bus address output;
*

* MMIO Address Space;
* 1. MMIO is intended for cores such as system timer, GPIO, UART etc.
* 2. MMIO to host up to 64 cores; (2^{6})
* 3. each core has 32 internal registers; (2^{5});
*

* Reference:
* Title: MicroBlaze Micro Controller System v3.0/ LogiCORE IP Product Guide;
* Document: PG116 July 15, 2021;
*
*/

// system clock; fixed at 100MHz;
`define SYS_CLK_FREQ_MHZ    100   
`define SYS_CLK_FREQ_HZ     100000000
/*------------------------------------------
* Note on Address Space
*-------------------------------------------
1. Microblaze MCS bus address is 32-bit-byte-addressable
2. hwoever, user-space only uses 26-bit-byte-addressable;
3. on word alignment, this is 24-bit-word-addressable;
4. As of now, 26-bit-byte address space is intended
    to host one general MMIO system and a video subsystem;
    
    where:
    
    MMIO system includes core such as
    system timer, GPIO, SPI, I2C etc;
    and the other specialized system is for future
    extensibility;
    
    video subystem is to stream a camera to display;

5. 23-bit-word-addressable usable memory is allocated for user-systems;

6. to distinguish between the two systems, the 26th bit of the 26-bit-byte
    addressable space is used as the select bit low for mmio; high for video;
    
7. mmio system;
    1. it has 64 cores (2^6);
    2. each core has 32 registers of 32-bit wide; (2^5);

8. video system:
    0. it has 8 video cores (2^3);
    1. a pixel occupies 16-bit;
    2. each core has 8 (2^3) internal registers for configuration purposes;
    so, we have each core uses 16+3 = 19 bit space, summarized below;
    1. 
    1. it has 8 cores (2^3);
    2. each core has 2^19 word;
    
9. if there are other systems integrated in the future;
    more bits will be allocated for distinguishing purposes;
    
summary of the word-addressable memory;        
mmio system:    0xxx_xxxx_xxxx_xsss_sssr_rrrr
video system:   1xvv_vrrr_aaaa_aaaa_aaaa_aaaa

* x represents dont-care (to accommodate frame buffer?)
* s represents mmio core;
* r represents mmio or video core internal registers;
* v represents video core;
* a represents video space of each core; where this space is used for various purposes;
*       such as to store i=the 16-bit pixel
*/

`define BUS_MICROBLAZE_SIZE_G           32
//`define BUS_USER_SIZE_G                 21  // as above; (word aligned);
//`define BUS_SYSTEM_SELECT_BIT_INDEX_G   23  // the 24-bit; as above, to distinguish two systems;

`define BUS_USER_SIZE_G                 23  // as above; (word aligned);
`define BUS_SYSTEM_SELECT_BIT_INDEX_G   25  // the 26-bit; as above, to distinguish two systems;

// IO based address provided by microblaze MSC, as above;
`define BUS_MICROBLAZE_IO_BASE_ADDR_G 32'hC0000000

/*---------------------------------------------------- 
* mmio address space
* this address space as above is to store
* the IO cores;
* 1. allocated to host 2^{6} = 64 cores;
* 2. each core has 2^{5} = 32 internal registers 
*   where each register is 32-bit wide;
----------------------------------------------------*/
`define MIMO_ADDR_SIZE_G        6                   // mmio to accommodate 64 cores;
//`define MIMO_CORE_TOTAL_G       2**MIMO_ADDR_SIZE_G // 64 cores;
`define MIMO_CORE_TOTAL_G       64 // 64 cores;

// register info of each core; 
`define REG_DATA_WIDTH_G    32  // MCS uses word (32-bit);
`define REG_ADDR_SIZE_G     5   // each mimo core has 2^{5} = 32 internal registers;

/*----------------------------------------------------
* IO modules/cores shall be sloted in the IO memory map;
* module index; each module is allocated with 32 registers;
* max number of cores is still undecided yet;
----------------------------------------------------*/  
`define S0_SYS_TIMER    0   // timer;
`define S1_UART_DEBUG   1   // uart for serial debugging;
`define S2_GPO_LED      2   // general purpose output to accommodate LED;
`define S3_GPI_SW       3   // general purpose input to accommodate switches;
`define S4_GPIO_PORT    4   // general purpose input output for flexibility and to reduce pinout;
`define S5_SPI          5   // spi (mainly to test TFT-LCD);
`define S6_I2C_MASTER   6   // i2c master (to configure ov7670 camera);

/* -------------------------------------------------
*  Register Map of the Individual MMIO core register;
--------------------------------------------------*/

/**************************************************************
* S1_UART_DEBUG
--------------------
Timer Core uses three registers;

Register Map: 
   1. register 0 (offset 0): lower word of the counter;
   2. register 1 (offset 1): upper word of the counter;
   3. register 2 (offset 2): control register;  

   Control Signals
   1. clear: a Pulse will reset the counter to zero; (important: Pulse);
   2. go: pause or resume the counting;    
    
   Control Register:
   1. Bit 0: go;
   2. Bit 1: clear;
******************************************************************/
`define S0_SYS_TIMER_REG_CNTLOW_OFFSET      0
`define S0_SYS_TIMER_REG_CNTHIGH_OFFSET     1
`define S0_SYS_TIMER_REG_CTRL_OFFSET        2

/**************************************************************
* S1_UART_DEBUG
--------------------
UART core has five registers;

Register Map
1. register 01 (offset 0): status register      
2. register 02 (offset 1): baud rate setting divisor;
3. register 03 (offset 2): Tx (write) request register;
4. register 04 (offset 3): Rx (read-and-pop) request (control) register;
5. register 05 (offset 4): Rx Data;
        
Register Definition:
1. register 01: Status Register
    bit 0 - UART Rx FIFO buffer Empty Status
    bit 1 - UART Tx FIFO buffer Full Status
2. register 02: baud rate;
    where bit[10:0] is allocated to store
    the value to program the baud rate;
3. register 03: Tx write request;
    to put the wr_data on the bus for UART Tx;
4. register 04: Rx read request;
    where UART Rx FIFO requires a read requeat
        to get the data pointed and update the pointer
        to the next data;
5. register 05: Rx data;
    data popped by the read request from the register above;

Register IO Access;
1. Status Register              - Read Only
2. Baud Rate Setting Divisior   - Write Only
3. Tx Write Request Register    - Write Only
4. Rx Request Register          - Write Only;
5. Read Data Register           - Read Only;   
******************************************************************/
// register offset;
`define S1_UART_REG_STATUS_OFFSET               0
`define S1_UART_REG_BAUD_OFFSET                 1
`define S1_UART_REG_TX_WRITE_REQUEST_OFFSET     2
`define S1_UART_REG_RX_READ_REQUEST_OFFSET      3
`define S1_UART_REG_RX_READ_DATA_OFFSET         4

// bit position of the status flags within status register;
`define S1_UART_REG_STATUS_BIT_POS_RX_EMPTY         0
`define S1_UART_REG_STATUS_BIT_POS_TX_FULL          1


/**************************************************************
* S5_SPI;
--------------------
SPI core has seven registers;

Register Map
1. register 01 (offset 0): status register; 
2. register 02 (offset 1): slave select register;
3. register 03 (offset 2): MOSI write data register;
4. register 04 (offset 3): MISO read data register;
5. register 05 (offset 4): ctrl register;
6. register 06 (offset 5): SPI sclk programming register;
7. register 07 (offset 6): data or command register;

Register Definition:
1. register 01: status register;
    BIT[0]: store the SPI ready state
        HIGH if SPI is available;
        LOW otherwise;
        
2. register 02: slave select rgeister;
    for multiple slave selection;
    BIT[X-1:0], where X is the number of slaves;

3. register 03: MOSI write data register;
    BIT[7:0]: mosi data;
    once written, this automatically start the SPI;
    
4. register 04: MISO read data register;
    BIT[7:0] : (assembled) miso data from the slave;

5. register 05: control register;
    BIT[0]     : cpol;
    BIT[1]     : cpha;
    
6. register 06: SPI sclk register
    BIT[15:0]   : stores the SPI sclk counter modulus;

7. register 07: data or command register;
    BIT[0]     : current MOSI byte is command or data for the slave;
                HIGH if the current SPI byte is a data;
                LOW otherwise;
                (this is not SPI intrinsic; it 
                is created for convenience);

Register IO Access:
1. Status Register          : read only;
2. Slave Select Register    : write only;
3. MOSI Write Data Register : write only;
4. MISO Read Data Register  : read only; 
5. Control Regitser         : write only
6. SPI sclk register        : write only
7. Data or Command Register : write only
******************************************************************/
`define S5_SPI_TOTAL_REG_NUM        6

// register offset;
`define S5_SPI_REG_STATUS_OFFSET    0   // 000
`define S5_SPI_REG_SS_OFFSET        1   // 001
`define S5_SPI_REG_MOSI_WR_OFFSET   2   // 010
`define S5_SPI_REG_MISO_RD_OFFSET   3   // 011
`define S5_SPI_REG_CTRL_OFFSET      4   // 100
`define S5_SPI_REG_SCLK_MOD_OFFSET  5   // 101
`define S5_SPI_REG_DC_OFFSET        6   // 110
    
// bit position;
`define S5_SPI_REG_STATUS_BIT_POS_READY     0
`define S5_SPI_REG_CTRL_BIT_POS_CPOL        0
`define S5_SPI_REG_CTRL_BIT_POS_CPHA        1
`define S5_SPI_REG_DC_BIT_POS_DC            0

// misc;
`define S5_SPI_REG_SCLK_WIDTH           16
`define S5_SPI_REG_TOTAL_STATUS_NUM     1

// DC contrl signal to indicate to the slave;
// HIGh if it is data; LOW if it is a command;
`define S5_SPI_REG_DC_DATA 1


/**************************************************************
* S6_I2C_MASTER
--------------------
i2c master has three registers;

Register Map
1. register 0 (offset 0): read register 
2. register 1 (offset 1): i2c clock rate set register;
3. register 2 (offset 2): write register;

Register Definition:
1. register 0: read register
        bit[7:0]    received slave data;
        bit[8]      slave ACK bit;
        bit[9]      i2c master controller ready status

2. register 1: i2c clock rate register;
        all 32 bits are dedicated to the program the i2c clock;
        this is to program the clock counter modulus (mod):

3. register 2: write register;
        bit[7:0]    master 8-bit data to slave;
        bit[10:8]   i2c user commands;

Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;                 
******************************************************************/
// register offset;
`define S6_I2C_REG_READ_OFFSET      0   // 00
`define S6_I2C_REG_CLKMOD_OFFSET    1   // 01
`define S6_I2C_REG_WRITE_OFFSET     2   // 10

// bit position;
`define S6_I2C_REG_READ_BIT_POS_ACK     8  
`define S6_I2C_REG_READ_BIT_POS_READY   9

`define S6_I2C_REG_WRITE_BIT_POS_CMD_OFFSET 8   

/*----------------------------------------------------
video address space;
1. 2^3 = 8 video cores;
2. each core has 19-bit address space;
    where this 19-bit is used for internal register
    and to store 16-bit pixel data;
    
summary:
video system:   1xvv_vrrr_aaaa_aaaa_aaaa_aaaa

* x represents dont-care (to accommodate frame buffer?)
* v represents video core;
* r represents video core internal registers;
* a represents video space of each core; where this space is used for various purposes;
*       such as to store i=the 16-bit pixel
----------------------------------------------------*/
`define VIDEO_CORE_ADDR_SIZE_G       3 
`define VIDEO_CORE_TOTAL_G           8 // 2**VIDEO_CORE_ADDR_SIZE_G;
`define VIDEO_REG_ADDR_BIT_SIZE_G   19  // each video core has 19-bit address space allocated;


/*----------------------------------------------------
* video modules/cores shall be sloted in the video system;
----------------------------------------------------*/  
`define V0_DISP_LCD    0   // lcd ILI9341 display via mcu 8080 seris protocol;

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

// register offset;
`define V0_DISP_LCD_REG_RD_DATA_OFFSET      0   // 000
`define V0_DISP_LCD_REG_WR_CLOCKMOD_OFFSET  1   // 001
`define V0_DISP_LCD_REG_RD_CLOCKMOD_OFFSET  2   // 010
`define V0_DISP_LCD_REG_WR_DATA_OFFSET      3   // 011
`define V0_DISP_LCD_REG_STREAM_CTRL_OFFSET  4   // 100
`define V0_DISP_LCD_REG_CSX_OFFSET          5   // 101
`define V0_DISP_LCD_REG_DCX_OFFSET          6   // 110

// bit position;
`define V0_DISP_LCD_REG_STATUS_BIT_POS_READY  8  
`define V0_DISP_LCD_REG_STATUS_BIT_POS_DONE   9

`define V0_DISP_LCD_REG_CSX_BIT_POS           0 // chip select;

`define V0_DISP_LCD_REG_DCX_BIT_POS           0 // dcx;

`endif //_IO_MAP_SVH