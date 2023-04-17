#ifndef _IO_MAP_H
#define _IO_MAP_H


// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

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
#define SYS_CLK_FREQ_MHZ    100  
#define SYS_CLK_FREQ_HZ     100000000   

/*------------------------------------------
* Note on Address Space
*-------------------------------------------
1. Microblaze MCS bus address is 32-bit-byte-addressable
2. hwoever, user-space only uses 24-bit-byte-addressable;
3. on word alignment, this is 22-bit-word-addressable;
4. As of now, 24-bit-bute address space is intended
    to host one general MMIO system and at least one 
    specialized system;
    where MMIO system includes core such as
    system timer, GPIO, SPI, I2C etc;
    and the other specialized system is for future
    extensibility;

5. 21-bit-word-addressable is allocated for user-systems;
6. for now to distinguish between different spaces (systems)
    bit-23 is used;
    LOW for MMIO system;
    HIGH otherwise;
7. if there are other systems integrated in the future;
    more bits will be allocated for distinguishing purposes;
*/
#define BUS_MICROBLAZE_SIZE_G           32
#define BUS_USER_SIZE_G                 21  // as above; (word aligned);
#define BUS_SYSTEM_SELECT_BIT_INDEX_G   23  // as above, to distinguish two systems;

// IO based address provided by microblaze MSC, as above;
#define BUS_MICROBLAZE_IO_BASE_ADDR_G 0xC0000000

/*---------------------------------------------------- 
* mmio address space
* this address space as above is to store
* the IO cores;
* 1. allocated to host 2^{6} = 64 cores;
* 2. each core has 2^{5} = 32 internal registers 
*   where each register is 32-bit wide;
----------------------------------------------------*/

#define MIMO_ADDR_SIZE_G        6                   // mmio to accommodate 64 cores;
//#define MIMO_CORE_TOTAL_G       2**MIMO_ADDR_SIZE_G // 64 cores;
#define MIMO_CORE_TOTAL_G       64 // 64 cores;

// register info of each core; 
#define REG_DATA_WIDTH_G    32  // MCS uses word (32-bit);
#define REG_ADDR_SIZE_G     5   // each core has 2^{5} = 32 internal registers;

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
#define S5_SPI          5

/* -------------------------------------------------
*  Register Map of the Individual IO core register;
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



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_IO_MAP_H