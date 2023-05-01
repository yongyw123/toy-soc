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
	delay_busy_ms(100);

    /*---------------------------------------------
    * LCD display from HW pixel generation core(s)
    * not from the cpu;
    -------------------------------------------*/
    // slower write speed;
    //obj_lcd_controller.set_clockmod(50, 50, 50, 50);	// ok;
    //obj_lcd_controller.set_clockmod(10, 10, 50, 50);	// ok
    //obj_lcd_controller.set_clockmod(6, 6, 50, 50);	// ok
    //obj_lcd_controller.set_clockmod(3, 3, 50, 50);	// ok
    obj_lcd_controller.set_clockmod(2, 2, 50, 50);	    // ok
    

    /* !!!!!! IMPORTANT !!!!!!
	Need to issue the following command to the
	LCD in order to display anything;
	otherwise, it wont work;
	this command enables the transfer
	the pixel data from the host (board)
	to the LCD memory;
	*/
	// enable LCD memory write mode prior to switching the stream mode;
	obj_lcd.enable_memwr();
	delay_busy_ms(100);

	// hand over the control to the hw pixel generation cores;
	obj_lcd_controller.set_video_stream();

    // use the test pattern generator as the pixel source;
    debug_str("selecting the HW test pattern generator \r\n");
    vid_src_mux.select_test();

    // enable the test pattern generator;
    debug_str("enabling the HW test pattern generator \r\n");
    vid_test_pattern.enable();
    
    // pause before switching the display;
    for(int i = 0; i < 10; i++){
        delay_busy_ms(1000);
    }

    // disable the hw pattern generator
    vid_test_pattern.disable();

    // pause before switching the display;
    for(int i = 0; i < 5; i++){
        delay_busy_ms(1000);
    }

    /*---------------------------------------------------
    * switching back to CPU control;
    * this is to test the interchangeability between
    * two controls;
    --------------------------------------------------*/
    // hand over the control to the hw pixel generation cores;
	obj_lcd_controller.set_cpu_stream();
    obj_lcd.fill_colour(RGB565_COLOUR_PINK);

    while(1){        
        ;
    }
}

