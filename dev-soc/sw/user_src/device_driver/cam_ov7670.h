#ifndef _CAM_OV7670_H
#define _CAM_OV7670_H

#include "io_reg_util.h"
#include "io_map.h"
#include "user_util.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "core_spi.h"
#include "core_i2c_master.h"
#include "main.h"

/* ------------------------------------------------
Purpose: APP driver for Camera OV7670;
Content:
0. utility function;
1. the camera registers;
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* constants */
#define OV7670_HW_RSTN_PIN_JA07 0   // which gpio port index used for camera hw reset;


// hw reset using an gpio pin;
void ov7670_hw_reset(core_gpio *gpio_obj);





#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _CAM_OV7670_H

