
#include "core_gpio.h"
#include "io_map.h"
#include "test_util.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_gpio obj_jumper(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));

int main(){
    uint32_t i = 0;
	uint32_t j = 0;

    // set to output direction;
    obj_jumper.set_direction(0, 1); 
        

    while(1){
        //test_led_sw(&obj_sw, &obj_led);
        //test_timer(&obj_led);
    	
        //test_timer(&obj_led);
        
        obj_jumper.write(0, 1);
        delay_busy_ms(1000);
        obj_jumper.write(0, 1);
        delay_busy_ms(1000);
        
    }
}


