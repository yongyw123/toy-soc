#include "user_util.h"

/* instantiate class; */
core_timer sys_timer(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S0_SYS_TIMER));


void busy_delay_ms(uint64_t ms){
    /*
    * @brief    : busy delay for X millisecond;
    * @param    : ms - X millisecond in integer;
    * @retval   : none
    */
   
   // reset the counter;
   sys_timer.clear();
   sys_timer.delay_poll_us((uint64_t)1000*ms);
}

