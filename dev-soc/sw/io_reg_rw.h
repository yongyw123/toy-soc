#ifndef _IO_REG_RW_H
#define _IO_REG_RW_H

/* ---------------------------------------------
* Purpose: header map for register read and write;
1. contain macros to manipulate register;
---------------------------------------------*/

/*
* @note:
*   1. register address is 32-bit wide;
*   2. address is byte-addresable;
*   3. hence each register occupies 4-byte;
*/

#include "inttypes.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

#define REG_WORD_BYTE 4     // each register is 32-bit; hence 4-byte;

/*
* @macro        : IO_REG_READ();
* @purpose      : read a register;
* @input: 
*   base_addr   : base address of the register
*   offset      : offset of the register;
*/
#define REG_READ(base_addr, offset) (*(volatile uint32_t *)((base_add) + REG_WORD_BYTE*(offset)))

/*
* @macro        : REG_WRITE();
* @purpose      : write a data into a register;
* @input: 
*   base_addr   : base address of the register
*   offset      : offset of the register;
*   data        : 32-bit data to write;
*/
#define REG_WRITE(base_addr, offset, wr_data) (*(volatile uint32_t *)((base_add) + REG_WORD_BYTE*(offset)) = (wr_data))

/*
* @macro        : GET_IO_CORE_ADDR();
* @purpose      : get the base address of a specified IO core;
* @input: 
*   mmio_addr   : base (start) address of the MMIO address space;
*   core_num    : which io core of the MMIO;
*/
#define TOTAL_REG_NUM 32        // each core is allocated 2^{5} internal registers;
#define GET_IO_CORE_ADDR(mmio_addr, core_num) ((uint32_t)((mmio_base) + TOTAL_REG_NUM*REG_WORD_BYTE*(core_num)))


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_IO_REG_RW_H