#ifndef _MAIN_H
#define _MAIN__H

/* ---------------------------------------------
Purpose: top level directives;
1. to enable debugging;
2. main include file;
---------------------------------------------*/

// general
#include "io_map.h"

// mmio system
#include "core_gpio.h"
#include "core_timer.h"
#include "core_uart.h"
#include "core_spi.h"

// video system;
#include "video_core_lcd_display.h"
#include "video_core_src_mux.h"
#include "video_core_test_pattern_gen.h"
#include "video_core_dcmi_interface.h"

// test driver;
#include "test_util.h"
#include "user_util.h"

// device drivers;
#include "cam_ov7670.h"
#include "lcd_ili9341.h"

// user directive;
#include "device_directive.h"


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