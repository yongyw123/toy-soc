#include "user_util.h"

/* instantiate class; */
core_timer sys_timer(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S0_SYS_TIMER));
core_uart  sys_uart(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S1_UART_DEBUG));

void delay_busy_ms(uint64_t ms){
    /*
    * @brief    : busy delay for X millisecond;
    * @param    : ms - X millisecond in integer;
    * @retval   : none
    */
   
   sys_timer.delay_busy_us((uint64_t)1000*ms);
}


//> debugging utility;
void debug_off(void){
    /*
    @brief  : to turn off uart printing;
    @note   : this is just a placeholder for NOP;
    @param  : none
    @retval : none
    */
   ;    // nop;
}
  
void debug_on(const char *str){
    /*
    @brief  : serial print out for debugging purpose;
    @param  : string (message) to print
    @retval : none
    */
   sys_uart.print(str);
}

