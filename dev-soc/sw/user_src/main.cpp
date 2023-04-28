#include "main.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));



int main(){
    
    // var declare;
    int i; // loop index;

    // sample colour to test the lcd display;
    int colour_array[3] = {RGB565_COLOUR_YELLOW, RGB565_COLOUR_GREEN, RGB565_COLOUR_PURPLE};    

    // construct a sw driver for lcd;
    lcd_ili9341_sw_driver obj_lcd;

    // hw reset;
    obj_lcd.hw_reset();
    
    // to read LCD ILI9341 ids;
    obj_lcd.read_id();
    
    // read lcd display status;
    obj_lcd.read_status();

    // read lcd display power mode;
    obj_lcd.read_power_mode();

    // read self-diagnostic report;
    obj_lcd.read_diagnostic();
        
    // turn it on;    
    obj_lcd.disp_on();
    
    // to invert the lcd;
    obj_lcd.disp_inv(1);

    // initialize the lcd;
    debug_str("initializing ... \r\n");
    obj_lcd.init();
    
    // orientation;
    debug_str("setting orientation ... \r\n");
    obj_lcd.set_orientation(0,0,0);

    // set pixel arrangement;
    obj_lcd.set_BGR_order(1);

    // try painting the lcd with some colours;
    debug_str("colour filling ... \r\n");
    obj_lcd.fill_colour(RGB565_COLOUR_ORANGE);
    delay_busy_ms(1000); // one second;

    i = 0;
    
    while(1){
        // change lcd colour every N seconds;
        obj_lcd.fill_colour(colour_array[i]);
        i++;
        i = i%3; 

        delay_busy_ms(1000); // one second;
    
        
        
    }
}


