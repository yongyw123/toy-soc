
#include "core_gpio.h"
#include "io_map.h"

/* global instance of each class representation of the IO cores*/
core_gpo obj_led(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));

/* function prototypes */
void test_led_sw(core_gpi *sw, core_gpo *led);  // led corresponds to the switch;

int main(){

    while(1){
        test_led_sw(&obj_sw, &obj_led);
    }
}


/* function definition */

void test_led_sw(core_gpi *sw_obj, core_gpo *led_obj){
    /*
    * @brief: to test hw gpio core by using led for gpo, sw for gpi;
    * @param:
    *       sw_obj - pointer to the (instantiated) core_gpi object;
    *       led_obj - pointer to the (instantiated) core_gpo object;s
    * @retval: none
    */

   // led output to correspond to the switch state;
   uint32_t sw_state = sw_obj->read();
   led_obj->write(sw_state);
}