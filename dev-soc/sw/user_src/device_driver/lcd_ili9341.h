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
void lcd_ili9341_enable(void);  // chip select;
void lcd_ili9341_disable(void);  // deselect the chip;
void lcd_ili9341_read_id(void); 
void lcd_ili9341_read_disp_status(void);    // read display status;
void lcd_ili9341_init(void);    // basic initialization;
void lcd_ili9341_set_area(uint16_t column_start, uint16_t page_start, uint16_t column_end, uint16_t page_end);
void lcd_ili9341_set_orientation(uint16_t MY, uint16_t MX, uint16_t MV, uint16_t RGB_order);
void lcd_ili9341_write_pixel(uint16_t pixel);
void lcd_ili9341_fill_colour(uint16_t mono_colour);


/*------------------------------
* RGB 16-bit Colour Samples
------------------------------*/
#define RGB565_COLOUR_BLACK     0x0000  //   0,   0,   0
#define RGB565_COLOUR_BLUE      0x001F  //   0,   0, 255
#define RGB565_COLOUR_GREEN     0x07E0  //   0, 255,   0
#define RGB565_COLOUR_RED       0xF800  // 255,   0,   0
#define RGB565_COLOUR_YELLOW    0xFFE0  // 255, 255,   0
#define RGB565_COLOUR_WHITE     0xFFFF  // 255, 255, 255
#define RGB565_COLOUR_ORANGE    0xFD20  // 255, 165,   0
#define RGB565_COLOUR_PURPLE    0x780F  // 123,   0, 123
#define RGB565_COLOUR_PINK      0xFC18  // 255, 130, 198



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_LCD_ILI9341_H