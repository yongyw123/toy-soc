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

  
// only if debugging is enabled at the top level: main.h
#if _DEBUG
    void debug_str(const char *str){
        /*
        @brief  : serial print out a string (message) for debugging purpose;
        @param  : str, a pointer to the string (message) to print
        @retval : none
        */
    sys_uart.print(str);
    }

    void debug_num(int num){
        /*
        @brief  : serial print a (signed) number for debugging purposes;
        @param  : integer
        @retval : none
        */
    sys_uart.print(num);
    }
// debugging is disabled;
// NOP then;
#else
    void debug_str(const char *str){}
    
    void debug_num(int num){}

#endif