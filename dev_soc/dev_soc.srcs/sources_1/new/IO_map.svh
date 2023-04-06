`ifndef _MMIO_MAP_INCLUDED
`def _MMIO_MAP_INCLUDED

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

/*
* IO modules/cores shall be sloted in the IO memory map;
* module index; each module is allocated with 32 registers;
*/  
`define S0_SYS_TIMER    0
`define S1_DEBUG_UART   1   
`define S2_GPO_LED      2
`define S3_GPI_SW       3


`endif //_MMIO_MAP_INCLUDED