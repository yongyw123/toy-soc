#ifndef _LCD_ILI9341_H
#define _LCD_ILI9341_H

#include "io_reg_util.h"
#include "io_map.h"
#include "user_util.h"
#include "video_core_lcd_display.h"
#include "lcd_ili9341_reg.h"

/* ------------------------------------------------
* Driver for LCD ILI9341
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/*------------------------------
function prototype;
------------------------------*/
void lcd_ili9341_hw_reset(void); // hw reset using an gpio pin;
void lcd_ili9341_read_id(void);




#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_LCD_ILI9341_H