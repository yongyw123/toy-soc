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
#define SYS_CLK_FREQ 100   

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
#define S1_DEBUG_UART   1   // uart for serial debugging;
#define S2_GPO_LED      2   // general purpose output to accommodate LED;
#define S3_GPI_SW       3   // general purpose input to accommodate switches;

#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_IO_MAP_H