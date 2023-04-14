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

/*---------------------------------
* CONTROL
---------------------------------*/
#define _DEBUG  1

/* ---------------------------------
* PIN MAPPING
----------------------------------*/
// gpo - board all leds;
#define PIN_GPO_LED_00  0
#define PIN_GPO_LED_01  1
#define PIN_GPO_LED_02  2
#define PIN_GPO_LED_03  3

// ?? to be filled in ??

// gpi - board all switches;

// gpio pins - PMOD JD00 to JD03 are allocated for GPIO; 
#define PIN_GPIO_PMOD_JD0   0
#define PIN_GPIO_PMOD_JD1   1
#define PIN_GPIO_PMOD_JD2   2
#define PIN_GPIO_PMOD_JD3   3



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_MAIN__H