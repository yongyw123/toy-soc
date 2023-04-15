
#include "main.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_gpio obj_jumper(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));


int main(){


    // set all gpio pins to read direction;
    int input_00;
    int input_01;
    int input_02;
    int input_03;
    

    test_gpio_ctrl_direction(&obj_jumper);

    while(1){
        
        /*
        input_00 = obj_jumper.read(PIN_GPIO_PMOD_JD0);
        input_01 = obj_jumper.read(PIN_GPIO_PMOD_JD1);
        
        obj_led.write(PIN_GPO_LED_00, input_00);
        obj_led.write(PIN_GPO_LED_01, input_01);
        
        debug_str("input 00: "); debug_dec(input_00); debug_str("\r\n");
        debug_str("input 01: "); debug_dec(input_01); debug_str("\r\n");
        */    
        //delay_busy_ms(10);
        
    }
}


