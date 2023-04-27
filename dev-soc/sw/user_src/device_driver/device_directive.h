#ifndef _DEVICE_DIRECTIVE_H
#define _DEVICE_DIRECTIVE_H

#include "io_reg_util.h"
#include "io_map.h"
#include "user_util.h"
#include "video_core_lcd_display.h"

/* ------------------------------------------------
* common place for the external device drives;
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* ---------------------------------
// HW RESET PINS;
// use HW gpio pin;
-----------------------------------*/
// gpio pinout;
#define CAM_OV7670_HW_RSTN_PIN_JA07         0   // for camera; pmod jumper at JA07
#define LCD_ILI9341_HW_RSTN_PIN_JD07        1   // for lcd; pmod jumper at JD07

// global declaration;
// gpio core is mainly for HW reset pin for the external devices;
extern core_gpio obj_gpio;


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_DEVICE_DIRECTIVE_H