#include "core_timer.h"


/* class definition; */ 

// constructor;
core_timer::core_timer(uint32_t core_base_addr){
    base_addr = core_base_addr;
    // note that clear signal supercedes go signla;
    // reset the counter before starting the timer;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;
    ctrl_signal_state &= ~CTRL_GO_MASK;
    ctrl_signal_state |= CTRL_CLEAR_MASK;
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);

    // start the timer;
    ctrl_signal_state &= ~CTRL_CLEAR_MASK;
    ctrl_signal_state |= CTRL_GO_MASK;   
    REG_WRITE(base_addr, REG_CTRL_OFFSET, ctrl_signal_state);
}

// destructor; null;
core_timer::~core_timer(){}

// methods;
void core_timer::resume(){
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

void core_timer::pause(){
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

void core_timer::clear(){
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

uint64_t core_timer::read_counter(){
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

uint64_t core_timer::read_time(){
    /*
    @brief      : convert counter value to time unit;
    @param      : none
    @retval     : elapsed time in 10 nanosecond;
    @assumption : system freq is 100MHz;
    */

    // note that the counter value changes every 10 ns at 100MHz freq;
    return (uint64_t)(read_counter()/SYS_CLK_FREQ);
}

void core_timer::delay_poll_ms(uint64_t ms){
    /*
    * @brief        : delay for X amount of millisecond;
    * @param        : ms - X millisecond; must be in integer;
    * @retval       : none
    * @note         : this is a blocking function;
    * 
    * @assumption   : 64-bit counter does not expire?
    */

   // recall that at 100MHz, each counter tick is 10ns;
   // 1ms/10ns = 1e5;
   uint64_t ms_threshold = 100000;  
   uint64_t ms_tick = 0;       // how many ms has elapsedl
   
   uint64_t start_time;
   uint64_t current_time;
   uint64_t diff_time;
   uint32_t status = 1;     // loop breaker;
   start_time = read_time();

    // assumption: current_time > start_time;
    // this does not always hold since the counter may wrap around (overflow);
    // to be handled in the future;

    while(1){
        current_time = read_time();
        diff_time = (current_time - start_time);
        
        if(diff_time > ms_threshold){
            ms_tick++;
        }
        if(ms_tick > ms){
            break;
        }
    }
}


