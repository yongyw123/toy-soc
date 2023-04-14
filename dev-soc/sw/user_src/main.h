#ifndef _MAIN_H
#define _MAIN__H

/* ---------------------------------------------
Purpose: top level directives;
1. to enable debugging;

---------------------------------------------*/

#include "io_map.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "core_uart.h"
#include "test_util.h"
#include "user_util.h"


// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif


#define _DEBUG  1


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_MAIN__H