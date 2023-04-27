#include "lcd_ili9341.h"


void lcd_ili9341_hw_reset(void){
    /*
    @brief      : to HW reset the LCD ILI9341;
    @param      : none
    @retval     : none
    @pinout     : PMOD JD07
    @assumption : gpio core class has been instantiated as global
    */

    // gpio core has been instantiated on device_directive.h
    obj_gpio.set_direction(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);
    
    // apply a reset pulse;
    // active low to reset;
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);
    delay_busy_ms(10);
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 0);
    delay_busy_ms(10);
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);

} 

