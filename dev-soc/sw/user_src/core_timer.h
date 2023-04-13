#ifndef _CORE_TIMER_H
#define _CORE_TIMER_H

/* ---------------------------------------------
Purpose: SW drivers for system timer core;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif


/*
* Feature + Control Signals
* 1. timer core could count up to 64-bit;
* 2. control clear; reset the counter;
* 3. control go; high to resume counting; low to pause;
*
* Register Map;
* 1. three register;
* 2. offset 0: lowerword counter val;
* 3. offset 1: upperword counter val;
* 4. offset 2: control register for clear and go signal
*               bit-0 for go; 
*               bit-1 for clear;
*
*/

// class declaration
class core_timer{
    // register map;
    enum{
        REG_LOWERWORD_CNT_OFFSET = 0,   // lowerword counter value;
        REG_UPPERWORD_CNT_OFFSET = 1,   // upperword counter value;
        REG_CTRL_OFFSET = 2             // ctrl reg;

    };

    // ctrl signal bit position within the ctrl reg;
    enum{
        CTRL_GO_POS = 0,
        CTRL_CLEAR_POS = 1,

        CTRL_GO_MASK = (uint32_t) BIT_MASK(CTRL_GO_POS),
        CTRL_CLEAR_MASK = (uint32_t)BIT_MASK(CTRL_CLEAR_POS)
    };

    public:
        core_timer(uint32_t core_base_addr); // constructor;
        ~core_timer();  // destructor;
        void pause(void);   // pause the timer;
        void resume(void);  // resume the timer;
        void clear(void);   // clear the time;r
        uint64_t read_counter(void);                // how many count;
        uint64_t read_time(void);                   // time elapsed based on the counter val;
        void delay_busy_us(uint64_t input_us);  // delay for x us; this is blocking;
        
    private:
        uint32_t base_addr;
        uint32_t ctrl_signal_state; // go? cleared?

};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_TIMER_H