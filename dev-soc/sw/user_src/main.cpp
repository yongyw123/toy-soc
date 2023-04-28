#include "main.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));


int main(){
    
    delay_busy_ms(2000);
    
    // chip select the lcd;
    lcd_ili9341_enable();

    // hw reset;
    lcd_ili9341_hw_reset();
    
    // to read LCD ILI9341 ids;
    lcd_ili9341_read_id();
    
    // read lcd display status;
    lcd_ili9341_read_disp_status();

    // read lcd display power mode;
    lcd_ili9341_read_disp_power_mode();

    // turn it on;    
    lcd_ili9341_disp_on();
    
    // to invert the lcd;
    lcd_ili9341_disp_inv(1);

    /*
    // initialize the lcd;
    debug_str("initializing ... \r\n");
    lcd_ili9341_init();

    // orientation;
    debug_str("setting orientation ... \r\n");
    lcd_ili9341_set_orientation(0,0,0,0);

    // try painting the lcd with some colours;
    debug_str("colour filling ... \r\n");
    lcd_ili9341_fill_colour(RGB565_COLOUR_ORANGE);

    */
    debug_str("done??\r\n");
    while(1){
        lcd_ili9341_read_diagnostic();
        delay_busy_ms(1000);
        
    }
}


