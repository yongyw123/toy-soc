#ifndef _USER_UTIL_H
#define _USER_UTIL_H

/* ---------------------------------------------
Purpose: general purpose utility tool;
1. delay;
2. serial debugging; 
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"
#include "core_timer.h"
#include "core_uart.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

// to enable debugging?
#define _DEBUG 1


/* function prototypes */
//> time utility;
void delay_busy_ms(uint64_t ms);    // busy delay for X millisecond;

//> debugging utility;
void debug_off(void);   // nop;
void debug_on(const char *str); 

#if _DEBUG
    #define debug(str) (debug_on(str))
#else
    #define debug(str) (debug_off())
#endif


#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _USER_UTIL_H