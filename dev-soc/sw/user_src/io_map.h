#ifndef _IO_MAP_H
#define _IO_MAP_H


// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/*
*  Memory-mapped for MicroBlaze MCS;
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
* Reference:
* Title: MicroBlaze Micro Controller System v3.0/ LogiCORE IP Product Guide;
* Document: PG116 July 15, 2021;
*
*/

// system clock; fixed at 100MHz;
#define SYS_CLK_FREQ_MHZ    100  
#define SYS_CLK_FREQ_HZ     100000000   

/*------------------------------------------
* Note on Address Space
*-------------------------------------------
1. Microblaze MCS bus address is 32-bit-byte-addressable
2. hwoever, user-space only uses 24-bit-byte-addressable;
3. on word alignment, this is 22-bit-word-addressable;
4. As of now, 24-bit-byte address space is intended
    to host one general MMIO system and a video subsystem;
    
    where:
    
    MMIO system includes core such as
    system timer, GPIO, SPI, I2C etc;
    and the other specialized system is for future
    extensibility;
    
    video subystem is to stream a camera to display;

5. 21-bit-word-addressable usable memory is allocated for user-systems;

6. to distinguish between the two systems, the 23th bit of the 24-bit-byte
    addressable space is used as the select bit low for mmio; high for video;
    
7. mmio system;
    1. it has 32 cores (2^5);
    2. each core has 16 (2^4);
    3. each registers is 32-bit wide; 

8. video system:
    0. it has 16 video cores (2^4);
    1. each video core has 2^{4} = 16 registers;
    2. each register is 32-bit wide;
    
9. if there are other systems integrated in the future;
    more bits will be allocated for distinguishing purposes;
    
summary of the word-addressable memory;        
MMIO System	    :   0x_xxxx_xxxx_xxxs_ssss_rrrr
Video System    :   1x_xxxx_xxxx_xxxx_vvvv_rrrr


* x represents dont-care;
* s represents mmio core;
* r represents mmio or video core internal registers;
* v represents video core;
*/

#define BUS_MICROBLAZE_SIZE_G           32
#define BUS_USER_SIZE_G                 21  // as above; (word aligned);
#define BUS_SYSTEM_SELECT_BIT_INDEX_G   23  // the 24-bit; as above, to distinguish two systems;

//#define BUS_USER_SIZE_G                 23  // as above; (word aligned);
//#define BUS_SYSTEM_SELECT_BIT_INDEX_G   25  // the 24-bit; as above, to distinguish two systems;


//#define BUS_USER_SIZE_G                 13  // as above; (word aligned);
//#define BUS_SYSTEM_SELECT_BIT_INDEX_G   15  // the 26-bit; as above, to distinguish two systems;


// IO based address provided by microblaze MSC, as above;
#define BUS_MICROBLAZE_IO_BASE_ADDR_G 0xC0000000


/*---------------------------------------------------- 
* mmio address space
* this address space as above is to store
* the IO cores;
* 1. allocated to host 2^{5} = 32 cores;
* 2. each core has 2^{4} = 16 internal registers 
*   where each register is 32-bit wide;
----------------------------------------------------*/
#define MIMO_ADDR_SIZE_G        5   // mmio to accommodate 32 cores;
#define MIMO_CORE_TOTAL_G       32  // 2^{5} = 32 cores;

// register info of each core; 
#define REG_ADDR_SIZE_G     4       // each mimo core has 2^{4} = 16 internal registers;
#define REG_DATA_WIDTH_G    32      // MCS uses word (32-bit);

/*----------------------------------------------------
* IO modules/cores shall be sloted in the IO memory map;
* module index; each module is allocated with 32 registers;
* max number of cores is still undecided yet;
----------------------------------------------------*/  
#define S0_SYS_TIMER    0   // timer;
#define S1_UART_DEBUG   1   // uart for serial debugging;
#define S2_GPO_LED      2   // general purpose output to accommodate LED;
#define S3_GPI_SW       3   // general purpose input to accommodate switches;
#define S4_GPIO_PORT    4   // general purpose input output for flexibility and to reduce pinout;
#define S5_SPI         5   // spi master controller;
#define S6_I2C_MASTER   6   // i2c master controller;

/* -------------------------------------------------
*  Register Map of the Individual IO core register;
--------------------------------------------------*/

/**************************************************************
* S0_SYS_TIMER
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
#define S0_SYS_TIMER_REG_CNTLOW_OFFSET      0
#define S0_SYS_TIMER_REG_CNTHIGH_OFFSET     1
#define S0_SYS_TIMER_REG_CTRL_OFFSET        2

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
#define S1_UART_REG_STATUS_OFFSET               0
#define S1_UART_REG_BAUD_OFFSET                 1
#define S1_UART_REG_TX_WRITE_REQUEST_OFFSET     2
#define S1_UART_REG_RX_READ_REQUEST_OFFSET      3
#define S1_UART_REG_RX_READ_DATA_OFFSET         4
// bit position of the status flags within status register;
#define S1_UART_REG_STATUS_BIT_POS_RX_EMPTY         0
#define S1_UART_REG_STATUS_BIT_POS_TX_FULL          1

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
#define S5_SPI_TOTAL_REG_NUM        6

// register offset;
#define S5_SPI_REG_STATUS_OFFSET    0   // 000
#define S5_SPI_REG_SS_OFFSET        1   // 001
#define S5_SPI_REG_MOSI_WR_OFFSET   2   // 010
#define S5_SPI_REG_MISO_RD_OFFSET   3   // 011
#define S5_SPI_REG_CTRL_OFFSET      4   // 100
#define S5_SPI_REG_SCLK_MOD_OFFSET  5   // 101
#define S5_SPI_REG_DC_OFFSET        6   // 110
    
// bit position;
#define S5_SPI_REG_STATUS_BIT_POS_READY     0
#define S5_SPI_REG_CTRL_BIT_POS_CPOL        0
#define S5_SPI_REG_CTRL_BIT_POS_CPHA        1
#define S5_SPI_REG_DC_BIT_POS_DC            0

// misc;
#define S5_SPI_REG_SCLK_WIDTH           16
#define S5_SPI_REG_TOTAL_STATUS_NUM     1

// DC contrl signal to indicate to the slave;
// HIGh if it is data; LOW if it is a command;
#define S5_SPI_REG_DC_DATA 1



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
#define S6_I2C_REG_READ_OFFSET      0   // 00
#define S6_I2C_REG_CLKMOD_OFFSET    1   // 01
#define S6_I2C_REG_WRITE_OFFSET     2   // 10

// bit position;
#define S6_I2C_REG_READ_BIT_POS_ACK     8  
#define S6_I2C_REG_READ_BIT_POS_READY   9

#define S6_I2C_REG_WRITE_BIT_POS_CMD_OFFSET 8   

/*----------------------------------------------------
video address space;
1. video system:
    0. it has 16 video cores (2^4);
    1. each video core has 2^{4} = 16 registers;
    2. each register is 32-bit wide;
----------------------------------------------------*/
#define VIDEO_CORE_ADDR_BIT_SIZE_G   4
#define VIDEO_CORE_TOTAL_G           16  // 2**VIDEO_CORE_ADDR_SIZE_G;
#define VIDEO_REG_ADDR_BIT_SIZE_G    4  // each video core has 2^{4} = 16 registers

/*----------------------------------------------------
* video modules/cores shall be sloted in the video system;
----------------------------------------------------*/  
#define V0_DISP_LCD                 0   // lcd ILI9341 display via mcu 8080 seris protocol;
#define V1_DISP_TEST_PATTERN        1   // test pattern generator for the lcd;
#define V2_DISP_SRC_MUX             2   // direct which pixel source to the LCD: test pattern generator or from the camera?
#define V3_CAM_DCMI_IF              3   // camera dcmi interface (with a dual-clock fifo embedded);
#define V4_PIXEL_COLOUR_CONVERTER   4   // transform Y of YUV422 to RGB565;
#define V5_MIG_INTERFACE            5   // DDR2 MIG synchronous interface;

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
#define V0_DISP_LCD_REG_RD_DATA_OFFSET      0   // 000
#define V0_DISP_LCD_REG_WR_CLOCKMOD_OFFSET  1   // 001
#define V0_DISP_LCD_REG_RD_CLOCKMOD_OFFSET  2   // 010
#define V0_DISP_LCD_REG_WR_DATA_OFFSET      3   // 011
#define V0_DISP_LCD_REG_STREAM_CTRL_OFFSET  4   // 100
#define V0_DISP_LCD_REG_CSX_OFFSET          5   // 101
#define V0_DISP_LCD_REG_DCX_OFFSET          6   // 110

// bit position;
#define V0_DISP_LCD_REG_STATUS_BIT_POS_READY  8  
#define V0_DISP_LCD_REG_STATUS_BIT_POS_DONE   9

#define V0_DISP_LCD_REG_CSX_BIT_POS           0 // chip select;

#define V0_DISP_LCD_REG_DCX_BIT_POS           0 // dcx;



/**************************************************************
* V1_DISP_TEST_PATTERN
-----------------------
this core wraps the following modules: 
1. pixel_gen_colour_bar()
2. frame_counter();

Register Map
1. register 0 (offset 0): write register;
2. register 1 (offset 1): status register; 

Register Definition:
1. register 0: write register;
        bit[0]  start bit;
        HIGH to start this video core;

2. register 1: status register;
        bit[0] frame start? active high assertion;
        bit[1] frame end?   active high assertion;
        
Register IO access:
1. register 0: write and read;
2. register 1: read only;
******************************************************************/

// register offset;
#define V1_DISP_TEST_PATTERN_REG_WR_OFFSET      0
#define V1_DISP_TEST_PATTERN_REG_STATUS_OFFSET  1

// bit position;
#define V1_DISP_TEST_PATTERN_REG_WR_BIT_POS_START 0  

#define V1_DISP_TEST_PATTERN_REG_STATUS_BIT_POS_START   0
#define V1_DISP_TEST_PATTERN_REG_STATUS_BIT_POS_END     1

/**************************************************************
* V2_DISP_SRC_MUX
-----------------------

purpose:
1. direct which pixel source to the LCD: test pattern generator(s) or from the camera?
2. allocate 6 pixel sources for future purposes;
3. in actuality; should be only between the test pattern generators and the camera;

important note:
1. all pixel sources (inc camera) are mutually exclusive;

Register Map
1. register 0 (offset 0): select register; 
        bit[2:0] for multiplexing;
        3'b001: test pattern generator;
        3'b010: camera ov7670;
        3'b100: none;
        
Register Definition:
1. register 0: control register;
        
Register IO access:
1. register 0: write and readl
******************************************************************/
// register offset;
#define V2_DISP_SRC_MUX_REG_SEL_OFFSET     0

// multiplexing;
#define V2_DISP_SRC_MUX_REG_SEL_TEST     1 // 3'b001  // from the test pattern generator;
#define V2_DISP_SRC_MUX_REG_SEL_CAM      2 // 3'b010  // from the camera OV7670;
#define V2_DISP_SRC_MUX_REG_SEL_NONE     4 // 3'b100  // nothing by blanking;

/**************************************************************
* V3_CAM_DCMI_IF
-----------------------
Camera DCMI Interface

Purpose:
1. Mainly, to interface with camera OV7670 which drives the synchronization signals;
2. Note that this is asynchronous since this module is driven by OV7670 24MHz PCLK;

Constituent Block:
1. A dual-clock macro FIFO for the cross time domain;
      
Assumptions:
1. The synchronization signal settings are fixed; 
    thus; require the camera to be configured apriori;
    
Issue + Constraint:
1. The DUAL-CLOCK FIFO is a MACRO;
2. there are conditions to meet before this FIFO could operate;
3. Mainly, its RESET needs to satisfy the following:  
    Condition: A reset synchronizer circuit has been introduced to 7 series FPGAs. RST must be asserted
    for five cycles to reset all read and write address counters and initialize flags after
    power-up. RST does not clear the memory, nor does it clear the output register. When RST
    is asserted High, EMPTY and ALMOSTEMPTY are set to 1, FULL and ALMOSTFULL are
    reset to 0. The RST signal must be High for at least five read clock and write clock cycles to
    ensure all internal states are reset to correct values. During Reset, both RDEN and WREN
    must be deasserted (held Low).
    
        Summary: 
            // read;
            1. RESET must be asserted for at least five read clock cycles;
            2. RDEN must be low before RESET is active HIGH;
            3. RDEN must remain low during this reset cycle
            4. RDEN must be low for at least two RDCLK clock cycles after RST deasserted
            
            // write;
            1. RST must be held high for at least five WRCLK clock cycles,
            2. WREN must be low before RST becomes active high, 
            3. WREN remains low during this reset cycle.
            4. WREN must be low for at least two WRCLK clock cycles after RST deasserted;
    
4. as such, this core will have a FSM just for the above;
    this FSM will use the reset_system to create a reset_FIFO
    that satisfies the conditions above;
    once satistifed, the FSM will assert that the entire system is ready to use;
    the SW is responsible to check this syste readiness;
    the SW should not start the DCMI decoder until the system is ready!

5. by above, a register shall be created to store the system readiness;            
6. reference: "7 Series FPGAs Memory Resources User Guide (UG473);

------------
Register Map
1. register 0 (offset 0): control register;
2. register 1 (offset 1): status register;
3. register 2 (offset 2): frame counter read register;
4. register 3 (offset 3): FIFO status register;
5. register 4 (offset 4): FIFO read and write counter;  
6. register 5 (offset 5): FIFO (and system) readiness state
        
Register Definition:
1. register 0: control register;
    bit[0] start the decoder;
            0 to disable the decoder;
            1 to enable the decoder;
    bit[1] synchronously clear decoder frame counter;
            1 yes;
            0 no;
    bit[2] reset the internal fifo in case if the fifo has unresolved errors;
            1 to reset;
            0 otherwise;
            
2. register 1: status register;
    bit[0] detect the start of a frame
        1 yes; 
        0 otherwise
        *this will clear by itself;
    bit[1] detect the end of a frame (finish decoding);
        1 yes;
        0 otherwise;
        *this will clear by itself;
    bit[2]: is the decoder idle?
        1 yes;
        0 otherwise;
        
3. register 2: frame counter read register;
        bit[31:0] to store the number of frame detected;
        *note: 
            - this will overflow and wrap around;
            - will clear to zero after a system reset;

4. register 3: FIFO status register;
        bit[0] - almost empty;
        bit[1] - almost full;
        bit[2] - empty;
        bit[3] - full;
        bit[4] - read error;
        bit[5] - write error;

5. register 4: FIFO read and write counter;
        bit[15:0]   - read count;
        bit[31:16]  - write count;      
       
6. register 5: FIFO (and system) readiness state
        bit[0] 
            1 - system is ready to use;
            0 - otheriwse            

Register IO access:
1. register 0: write and read;
2. register 1: read only;
3. register 2: read only;
4. register 3: read only;
5. register 4: read only;
6. register 5: read only;
******************************************************************/
// register offset;
#define V3_CAM_DCMI_IF_REG_CTRL_OFFSET                  0   // 3'b000;
#define V3_CAM_DCMI_IF_REG_DECODER_STATUS_OFFSET        1   // 3'b001;
#define V3_CAM_DCMI_IF_REG_FRAME_RD_OFFSET              2   // 3'b010;
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_OFFSET           3   // 3'b011;
#define V3_CAM_DCMI_IF_REG_FIFO_CNT_OFFSET              4   // 3'b100;
#define V3_CAM_DCMI_IF_REG_SYS_READY_STATUS_OFFSET      5   // 3'b101;

// bit pos;
#define V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_START       0   // start the dcmi decoder;
#define V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_FRAME_RST   1   // reset decoder frame counter;
#define V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_FIFO_RST    2    // reset the internal fifo;

#define V3_CAM_DCMI_IF_REG_DECODER_STATUS_BIT_POS_START 0   
#define V3_CAM_DCMI_IF_REG_DECODER_STATUS_BIT_POS_END   1
#define V3_CAM_DCMI_IF_REG_DECODER_STATUS_BIT_POS_READY 2

#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_AEMPTY   0 // almost empty;
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_AFULL    1 // almost full;
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_EMPTY    2 
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_FULL     3 
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_RD_ERROR 4 
#define V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_WR_ERROR 5 


/******************************************************************
V4_PIXEL_COLOUR_CONVERTER
--------------------------
Purpose: if the camera output is in YUV422, then a conversion is needed
because LCD only accepts RGB565 format;

Construction:
1. for convenience, only the Y of the YUV422 is converted; 
2. hence, the LCD display will be grayscale;

Assumption:
1. the camera output YUV422 configuration is UYVY;
2. the Y appears as every second byte;
3. this could be configured on the camera OV7670 side;

------------
Register Map
1. register 0 (offset 0): control register;
        
Register Definition:
1. register 0: control register;
        bit[0] bypass the colour converter
        0: "disabled" to bypass the colour converter;
        1: "enabled" to go through the colour converter;
                    
Register IO access:
1. register 0: write and read;
******************************************************************/
#define V4_PIXEL_COLOUR_CONVERT_REG_CTRL 0
#define V4_PIXEL_COLOUR_CONVERT_REG_CTRL_BIT_POS 0

/*****************************************************************
V5_MIG_INTERFACE
-----------------
Purpose: to select which source to interface with the DDR2 SDRAM via MIG;
It is either interfacing with:
1. CPU;
2. other video core: motion detection?
3. a HW testing circuit;

Construction:
1. DDR2 read/write transaction is 128-bit.
2. So this complicates stuffs since ublaze register is 32-bit wide only;
3. to facilitate the read/write operation, we use multiple registers;

3.1 note that each address (bit) covers one 128-bit;

4. For write:
    1. we shall have multiple write control register bits:
    2. before submitting write request, we need to shift in the ublaze 32-bit into 128-bit;
    3. each bit is to push a 32-bit from ublaze to the 128-bit DDR2 register;
    4. some bits to setup the write address;
    5. one bit to submit the write request;

5. For read;
    1. similarly, we need multiple read control register bits;
    2. after submitting the read request along with the read address, we check and wait for transaction complete status;
    3. this completion status indicates the data on the bus is ready to be read;
    4. it takes "4 times" to shift in the 128-bit into four registers of 32-bit each;
      

-----
Register Map
1. Register 0 (Offset 0): select register;
2. Register 1 (Offset 1): status register;
3. Register 2 (Offset 2): address, common for read and write;
3. Register 3 (Offset 3): write control register;
4. Register 4 (Offset 4): read control register;
5. Register 5 (Offset 5): read data batch 01;
6. Register 6 (Offset 6): read data batch 02;
7. Register 7 (Offset 7): read data batch 03;
8. Register 8 (Offset 8): read data batch 04;

Register Definition:
1. Register 0 (Offset 0): select register;
    bit[2:0] for multiplexing
        3'b000: NONE
        3'b001: CPU
        3'b010: Motion Detection Core
        3'b100: HW Testing Circuit;
        
2. Register 1 (Offset 1): Status Register
        bit[0]: MIG DDR2 initialization complete status; active high;
        bit[1]: MIG DDR2 app ready status (implies init complete status); active high;
        bit[2]: transaction completion status, 
                common for both read and write; 
                once asserted, it will remain as it is until new write/read strobe is requested;                
        bit[3]: MIG controller idle status; active high;
            
3. Register 2 (Offset 2): address common for read and write;
        bit[22:0] address;

4. Register 3 (Offset 3): Control Register;
        bit[0]: submit the write request; (Need to clear once submitting for a single write operation);
        bit[1]: submit the read request; (Need to clear once submitting for a single write operation);        
      
5. Register 4 (Offset 4): DDR2 Write Register - push the first 32-bit batch of the write_data[31:0]; active HIGH;
6. Register 5 (Offset 5): DDR2 Write Register - push the second 32-bit batch of the write_data[63:32]; active HIGH;
7. Register 6 (Offset 6): DDR2 Write Register - push the third 32-bit batch of the write_data[95:64]; active HIGH;
8. Register 7 (Offset 7): DDR2 Write Register -  push the forth 32-bit batch of the write_data[127:96]; active HIGH;
       
9. Register 8-11: to store the 128-bit read data as noted in the construction;

Register IO:
1. Register 0: read and write;
2. Register 1: read only;
3. Register 2: read and write;
4. Register 3: write only;
5. Register 4: write only;
6. Register 5: write only;
7. Register 6: write only;
8. Register 7: write only;
9. Register 8: read only;
10. Register 9: read only;
11. Register 10: read only;
12. Register 11: read only;
 
*****************************************************************/#define V5_MIG_INTERFACE_REG_SEL       0    // 4'b0000     // 0;
#define V5_MIG_INTERFACE_REG_STATUS    1    // 4'b0001     // 1;
#define V5_MIG_INTERFACE_REG_ADDR      2    // 4'b0010     // 2;
#define V5_MIG_INTERFACE_REG_CTRL      3    // 4'b0011     // 3;

#define V5_MIG_INTERFACE_REG_WRDATA_01  4   //4'b0100     // 4
#define V5_MIG_INTERFACE_REG_WRDATA_02  5   //4'b0101     // 5
#define V5_MIG_INTERFACE_REG_WRDATA_03  6   //4'b0110     // 6;
#define V5_MIG_INTERFACE_REG_WRDATA_04  7   //4'b0111     // 7

#define V5_MIG_INTERFACE_REG_RDDATA_01  8   //4'b1000     // 8
#define V5_MIG_INTERFACE_REG_RDDATA_02  9   //4'b1001     // 9
#define V5_MIG_INTERFACE_REG_RDDATA_03  10  //4'b1010     // 10
#define V5_MIG_INTERFACE_REG_RDDATA_04  11  //4'b1011     // 11

// register 0: multiplexing;
#define V5_MIG_INTERFACE_REG_SEL_NONE     0 //3'b000  // none;
#define V5_MIG_INTERFACE_REG_SEL_CPU      1 //3'b001  // cpu;
#define V5_MIG_INTERFACE_REG_SEL_MOTION   2 //3'b010  // motion detection video cores;
#define V5_MIG_INTERFACE_REG_SEL_TEST     4 //3'b100  // hw testing circuit;

// register 1: status;
#define V5_MIG_INTERFACE_REG_BIT_POS_STATUS_MIG_INIT    0
#define V5_MIG_INTERFACE_REG_BIT_POS_STATUS_MIG_RDY     1
#define V5_MIG_INTERFACE_REG_BIT_POS_STATUS_COMPLETE    2
#define V5_MIG_INTERFACE_REG_BIT_POS_STATUS_CTRL_IDLE   3

// register 3: control;
#define V5_MIG_INTERFACE_REG_BIT_POS_WRSTROBE 0
#define V5_MIG_INTERFACE_REG_BIT_POS_RDSTROBE 1

 

#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_IO_MAP_H