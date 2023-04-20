
#include "main.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));

int main(){
    
    // initialize camera ov7670;
    ov7670_hw_reset();
    delay_busy_ms(1000);    // settingly time;
    ov7670_write_array(ov7670_basic_init_array);
    delay_busy_ms(1000);    // settingly time;
    ov7670_read_array(ov7670_basic_init_array);

    while(1){
        ;        
    }
}


