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

/*-----------------------------------
 * CONSTANTS
 ----------------------------------*/
//> LCD physical info
// note that depending on the orientation, the LCD dimension is (240W x 320H) or (320H x 240W);
#define LCD_ILI9341_DIMENSION_LOW_240 	240		// by above;
#define LCD_ILI9341_DIMENSION_HIGH_320 	320		// by above;
#define LCD_ILI9341_PIXEL_NUM 			76800 	// total number of pixels = 240 * 320


/*------------------------------
* function prototype;
------------------------------*/
void lcd_ili9341_hw_reset(void); // hw reset using an gpio pin;
void lcd_ili9341_read_id(void);
void lcd_ili9341_init(void);
void lcd_ili9341_set_area(uint16_t column_start, uint16_t page_start, uint16_t column_end, uint16_t page_end);
void lcd_ili9341_set_orientation(uint8_t MY, uint8_t MX, uint8_t MV, uint8_t RGB_order);
void lcd_ili9341_write_pixel(uint16_t pixel);
void lcd_ili9341_fill_colour(uint16_t mono_colour);

/*------------------------------
* 16-bit RGB colour samples
------------------------------*/








#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_LCD_ILI9341_H