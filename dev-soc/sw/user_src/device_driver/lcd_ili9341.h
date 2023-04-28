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
* function declaration;
------------------------------*/
void lcd_ili9341_hw_reset(void);    // independent hw reset;

/*------------------------------
* class declaration;
------------------------------*/
class lcd_ili9341_sw_driver{

    public:
        lcd_ili9341_sw_driver();
        ~lcd_ili9341_sw_driver();

        void hw_reset(void);
        void enable(void);      // chip enable;
        void disable(void);     // chip disable;
        
        void disp_on(void);     // turn on the lcd display;
        void disp_off(void);    // off;
        
        /* read ops;
        output result (read data)
        to the serial output to the pc;
        */
        void read_id(void);         // available ids
        void read_status(void);     // display status;
        void read_diagnostic(void); // self diagnostic;
        void read_power_mode(void); // power mode status;

        /* orientation */
        uint16_t MY_p; // row address order;
        uint16_t MX_p; // column address order;
        uint16_t MV_p; // row and column exchange;
        uint16_t BGR_order_p; // pixel in RGB or BGR? 1 for BGR;

        /* for configuring */
        void init(void);
        void set_area(uint16_t column_start, uint16_t page_start, uint16_t column_end, uint16_t page_end);    // set display region;
        void set_orientation(uint16_t MY, uint16_t MX, uint16_t MV); // set display orientation;
        // set how the pixel is arranged: RGB or BGR;
        void set_BGR_order(int BGR_order);    

        /* actual display */
        void write_pixel(uint16_t pixel);       // for sending a pixel to the lcd;
        void fill_colour(uint16_t mono_colour); // to fill the lcd with a single colour;
        void disp_inv(int to_invert);           // to invert the display or not?

    private:
        // constants;
        uint16_t pixel_bit_p = 16;    // bpp;
        uint16_t lcd_width_p = LCD_ILI9341_DIMENSION_LOW_240;
        uint16_t lcd_height_p = LCD_ILI9341_DIMENSION_HIGH_320;

        
};

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