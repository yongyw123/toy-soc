#include "test_util.h"


/* function definition */


void test_led_sw(core_gpi *sw_obj, core_gpo *led_obj){
    /*
    * @brief        : to test HW GPO and GPI core by using led for gpo, sw for gpi;
    * @param        :
    *       sw_obj  : pointer to the (instantiated) core_gpi object;
    *       led_obj : pointer to the (instantiated) core_gpo object;s
    * @retval       : none
    * @test         : map switch state to led state;
    */

   // led output to correspond to the switch state;
   uint32_t sw_state = sw_obj->read();
   led_obj->write(sw_state);
}

void test_timer(core_gpo *led){
    /*
    * @brief    : to test timer core;
    * @param    : led - pointer to the instantiated core_gpi object;
    * @note     : core_timer obj has been instantiated;
    * @retval   : none
    * @test     : blink the LED every X second;
    */
   
   led->toggle();
   delay_busy_ms(2000); // two seconds;
}