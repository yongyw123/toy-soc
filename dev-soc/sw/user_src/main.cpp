
#include "core_gpio.h"
#include "io_map.h"
#include "test_util.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_gpio obj_jumper(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));

int main(){
    uint32_t port01 = 0;
	uint32_t port03 = 0;

    // set to output direction;
    obj_jumper.set_direction(0, 1);     // port 0; write
    obj_jumper.set_direction(1, 0);     // port 1; read;
    obj_jumper.set_direction(2, 1);     // port 2; write
    obj_jumper.set_direction(3, 0);     // port 3; read;

    while(1){
        port01 = obj_jumper.read(1);
        port03 = obj_jumper.read(3);

        obj_led.write(1, port01);
        obj_led.write(3, port03);

    }
}


