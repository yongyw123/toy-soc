
#include "core_gpio.h"
#include "io_map.h"
#include "test_util.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));


int main(){

    while(1){
        //test_led_sw(&obj_sw, &obj_led);
        test_timer(&obj_led);
    }
}


