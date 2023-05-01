#include "main.h"

/* global instance of each class representation of the IO cores*/
// mmio system;
core_gpo obj_led(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));

// video system;
video_core_src_mux vid_src_mux(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V2_DISP_SRC_MUX));
video_core_test_pattern_gen vid_test_pattern(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V1_DISP_TEST_PATTERN));


int main(){
    
    /*---------------------------------
    * LCD init via the processor    
    ---------------------------------*/
    // hand the control to the cpu;
    obj_lcd_controller.set_cpu_stream();

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
        
    // initialize the lcd;
    debug_str("initializing ... \r\n");
    obj_lcd.init();
    
    // orientation;
    debug_str("setting orientation ... \r\n");
    obj_lcd.set_orientation(0,0,0);

    // set pixel arrangement;
    obj_lcd.set_BGR_order(1);

    // turn it on;    
    obj_lcd.disp_on();
    
    /* !!!!!! IMPORTANT !!!!!!
    Need to issue the following command to the 
    LCD in order to display anything;
    otherwise, it wont work;
    this command enables the transfer
    the pixel data from the host (board)
    to the LCD memory;
    */
    // enable LCD memory write mode;
    obj_lcd.enable_memwr();

    /*---------------------------------------------
    * LCD display from HW pixel generation core(s)
    * not from the cpu;
    -------------------------------------------*/
    // slower write speed;
    obj_lcd_controller.set_clockmod(20, 20, 20, 40);
    
    // hand over the control to the hw pixel generation cores;
    obj_lcd_controller.set_video_stream();
    

    // try put some colour from the processor;
    // expect it to be ignored;
    debug_str("expect that cpu does not have the lcd control here;\r\n");
    obj_lcd.fill_colour(RGB565_COLOUR_ORANGE);
    
    // some delays;
    delay_busy_ms(1000);
    delay_busy_ms(1000);
    delay_busy_ms(1000);
    delay_busy_ms(1000);
    delay_busy_ms(1000);
    

    // use the test pattern generator as the pixel source;
    debug_str("selecting the HW test pattern generator \r\n");
    vid_src_mux.select_test();

    // enable the test pattern generator;
    debug_str("enabling the HW test pattern generator \r\n");
    vid_test_pattern.enable();
    
    while(1){        
        ;
    }
}

