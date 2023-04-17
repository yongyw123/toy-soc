
#include "main.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_gpio obj_jumper(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));
core_spi obj_spi(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));

int main(){
    
    test_spi_mosi(&obj_spi);

    while(1){
        ;    
    }
}


