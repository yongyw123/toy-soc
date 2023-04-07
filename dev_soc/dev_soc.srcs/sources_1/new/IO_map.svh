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

* Reference:
* Title: MicroBlaze Micro Controller System v3.0/ LogiCORE IP Product Guide;
* Document: PG116 July 15, 2021;
*
*/

// system clock; fixed at 100MHz;
`define SYS_CLK_FREQ 100   

// IO based address provided by microblaze MSC, as above;
`define MCS_IO_BUS_BASE_ADDR 0xC0000000

// size;
`define REG_DATA_WIDTH_G    32  // MCS uses word (32-bit);
`define REG_ADDR_SIZE_G     5   // each core has 2^{5} = 32 internal registers;
`define CORE_ADDR_SIZE_G    6   // tba;

/*
* IO modules/cores shall be sloted in the IO memory map;
* module index; each module is allocated with 32 registers;
* max number of cores is still undecided yet;
*/  
`define S0_SYS_TIMER    0   // timer;
`define S1_DEBUG_UART   1   // uart for serial debugging;
`define S2_GPO_LED      2   // general purpose output to accommodate LED;
`define S3_GPI_SW       3   // general purpose input to accommodate switches;

`endif //_IO_MAP_SVH