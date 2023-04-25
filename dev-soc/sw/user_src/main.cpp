
#include "main.h"

/* global instance of each class representation of the IO cores*/
// mmio system;
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));
// video system;
video_core_lcd_display obj_lcd(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V0_DISP_LCD));

int main(){
    
    // test the lcd display interface controller;
    test_video_core_lcd_display(&obj_lcd);
    
    while(1){
        test_timer(&obj_led);
    }
}


