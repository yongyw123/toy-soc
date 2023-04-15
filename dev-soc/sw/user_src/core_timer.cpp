#include "core_timer.h"


/* class definition; */ 

// constructor;
core_timer::core_timer(uint32_t core_base_addr){
    base_addr = core_base_addr;
    
    // overwrite any existing control state since this is the start;
    ctrl_signal_state = CTRL_GO_MASK;
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);

    // start the timer;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;
    ctrl_signal_state |= CTRL_GO_MASK;   
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);
}

// destructor; null;
core_timer::~core_timer(){}

// methods;
void core_timer::resume(void){
    /*
    @brief      : resume counting;
    @param      : none
    @retval     : none;
    */
    
    // note that here clear and go should be mutually exclusive;
    // otherwise the counter value is rest, if not careful;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;  // deasserted clear signal;
    ctrl_signal_state &= ~CTRL_GO_MASK;     // clean up;
    ctrl_signal_state |= CTRL_GO_MASK;      // set the go; 
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);

    /* note: do not assign, instead use OR,
    this is for future extensibility in case
    the control register is updated to accommodate
    other signals; */
    
}

void core_timer::pause(void){
    /*
    @brief      : stop counting;
    @param      : none
    @retval     : none;
    */
    
    // note that here clear and go should be mutually exclusive;
    // otherwise the counter value is rest, if not careful;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;  // deasserted clear signal;
    ctrl_signal_state &= ~CTRL_GO_MASK;     // clean up;
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);
}

void core_timer::clear(void){
    /*
    @brief      : reset counter value to zero;
    @param      : none
    @retval     : none;
    */
    
    // clear supercedes go signal;
    // so go dont care;
    ctrl_signal_state &= ~CTRL_GO_MASK;     // clean up;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;  // clear first;
    ctrl_signal_state |= CTRL_CLEAR_MASK;  // deasserted clear signal;
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);

    /* note: do not assign, instead use OR,
    this is for future extensibility in case
    the control register is updated to accommodate
    other signals; */
    
}

uint64_t core_timer::read_counter(void){
    /*
    @brief      : return counter value;
    @param      : none
    @retval     : 64-bit counter value;
    */
    
    // use 64-bit instead of 32-bit since bit shifting is needed later on;
    uint64_t lowercount = REG_READ(base_addr, REG_LOWERWORD_CNT_OFFSET);
    uint64_t uppercount = REG_READ(base_addr, REG_UPPERWORD_CNT_OFFSET);
    return (uint64_t)((uppercount<<32)|lowercount);

}

uint64_t core_timer::read_time(void){
    /*
    @brief      : convert counter value to time unit;
    @param      : none
    @retval     : elapsed time in 10 nanosecond;
    @assumption : system freq is 100MHz;
    */

    // note that the counter value changes every 10 ns at 100MHz freq;
    // but SYS_CLK_FREQ_MHZ is 100 unit;
    // so this amounts to 1 microsecond;
    return (uint64_t)(read_counter()/SYS_CLK_FREQ_MHZ);
}

void core_timer::delay_busy_us(uint64_t input_us){
    /*
    * @brief        : delay for X amount of microsecond;
    * @param        : input_us - X microsecond; must be in integer;
    * @retval       : none
    * @note         : this is a blocking function;
    * 
    * @assumption   : system clock is 100MHz;
    * 
    * @assumption   : current_time > start_time;
    * this does not always hold since the counter may wrap around (overflow);
    * to be handled in the future;
    */  
   
   uint64_t start_time;
   uint64_t current_time;
   uint64_t diff_time;

   // to start from a clean slate;
   pause();     
   clear();
   resume();

   // start the delay;
   start_time = read_time();

    while(1){
        current_time = read_time();
        diff_time = (current_time - start_time);
        if(diff_time >= input_us){
            break;
        }     
    }
}


