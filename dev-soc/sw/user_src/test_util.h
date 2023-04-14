#ifndef _TEST_UTIL_H
#define _TEST_UTIL_H

#include "io_reg_util.h"
#include "io_map.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "user_util.h"

/* ------------------------------------------------
Purpose: test functions to check each HW IO cores;
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* function prototypes */

/*
* IO cores to test:
* 1. general purpose output (gpo);
* 2. general purpose input (gpi);
*
* Method:
* 1. map led to gpo;
* 2. map sw to gpi;
* 3. map sw state to led state;
*/
void test_led_sw(core_gpi *sw, core_gpo *led);  


/*
* IO cores to test:
* 1. timer;
* 
* Method:
* use in conjunction with led;
*/
void test_timer(core_gpo *led);


/*
* IO core to test;
1. uart;

method;
1. connect the board to any PC;
2. open any serial console;
3. e.g. tera term;

uart default settings;
1. baud rate; 9600;
2. number of data bits; 8;
3. number of stop bits; 1;
4. parity bits; none;

*/
void test_uart(void);


#ifdef __cpluscplus
} // extern "C";
#endif



#endif // _TEST_UTIL_H
