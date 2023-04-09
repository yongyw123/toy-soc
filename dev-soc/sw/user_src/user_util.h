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

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* function prototypes */

void busy_delay_ms(uint64_t ms);    // busy delay for X millisecond;

#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _USER_UTIL_H