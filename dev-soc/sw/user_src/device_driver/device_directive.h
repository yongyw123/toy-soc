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

// global declaration;
// gpio core is mainly for HW reset pin for the external devices;
core_gpio obj_gpio(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_DEVICE_DIRECTIVE_H