#ifndef _VIDEO_CORE_SRC_MUX_H
#define _VIDEO_CORE_SRC_MUX_H

/* ---------------------------------------------
Purpose : SW drivers for HW module as follows
Module  : core_video_lcd_test_pattern_gen.sv
---------------------------------------------*/
#include "io_map.h"
#include "io_reg_util.h"

/**************************************************************
* V1_DISP_TEST_PATTERN
-----------------------
this core wraps the following modules: 
1. pixel_gen_colour_bar()
2. frame_counter();

Register Map
1. register 0 (offset 0): write register; 

Register Definition:
1. register 0: write register;
        bit[0]  start bit;
        HIGH to start this video core;
        
        
Register IO access:
1. register 0: write and read;
******************************************************************/

class video_core_test_pattern_gen{

    // register map;
    enum{
        REG_WR_OFFSET = 0
    };

    // field;
    enum{
        BIT_POS_WR = 0        
    };

    // constanst;
    enum{
        ENABLE_TEST_PATTERN = 1,
        DISABLE_TEST_PATTERN = 0
    };

    public:
        video_core_test_pattern_gen();
        ~video_core_test_pattern_gen();

        void enable(void);  // enable the pattern generatorl
        void disable(void); // disable the pattern generator;

        int get_state(void);    // is the test pattern enabled or not;

    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;

        int curr_state;    // keep track of the state: on or off?

};


// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_SRC_MUX_H