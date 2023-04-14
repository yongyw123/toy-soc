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
#include "main.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif



/* function prototypes */
//> time utility;
void delay_busy_ms(uint64_t ms);    // busy delay for X millisecond;


/*  debugging utility;
this emulate C printf function;
recall that printf by default only prints string literal;
to extend it, one requires formatter;

however, we separate into two functions to keep it simple 
(one argument for one function);

assumption: class core_uart has been instantiated as a global object;

1. for strings only;
2. for integers;
3. [future] floating;
*/
void debug_str(const char *str);
void debug_num(int num); 

#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _USER_UTIL_H