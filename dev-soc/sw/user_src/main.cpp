
#include "core_gpio.h"
#include "io_map.h"
#include "test_util.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));


int main(){
    uint32_t i = 0;
	uint32_t j = 0;

    while(1){
        //test_led_sw(&obj_sw, &obj_led);
        //test_timer(&obj_led);
    	obj_led.write((uint32_t)0xFFFFFFFF);
        delay_busy_ms(1000); // two seconds;
        
        obj_led.write((uint32_t)0x0);
        delay_busy_ms(1000); // two seconds;

        /*
    	for(i = 0; i < 5000; i++){
    		for(j = 0; j < 10000; j++){
    			;
    		}
    	}

    	obj_led.write((uint32_t)0x0);
    	for(i = 0; i < 5000; i++){
			for(j = 0; j < 10000; j++){
				;
			}
		}
        */
    }
}


