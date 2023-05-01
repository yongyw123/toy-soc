#ifndef _VIDEO_CORE_TEST_PATTERN_GEN_H
#define _VIDEO_CORE_TEST_PATTERN_GEN_H

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
2. register 1 (offset 1): status register; 

Register Definition:
1. register 0: write register;
        bit[0]  start bit;
        HIGH to start this video core;

2. register 1: status register;
        bit[0] frame start? active high assertion;
        bit[1] frame end?   active high assertion;
        
Register IO access:
1. register 0: write and read;
2. register 1: read only;
******************************************************************/
class video_core_test_pattern_gen{

    // register map;
    enum{
        REG_WR_OFFSET = 0,
        REG_STATUS_OFFSET = 1   
    };

    // field;
    enum{
        
        REG_WR_BIT_POS_WR = 0,

        REG_STATUS_BIT_POS_START    = 0, // frame generation has not started;
        REG_STATUS_BIT_POS_END      = 1, // frame is complete

        MASK_STATUS_FRAME_START = BIT_MASK(REG_STATUS_BIT_POS_START),
        MASK_STATUS_FRAME_END   = BIT_MASK(REG_STATUS_BIT_POS_END)
        
    };

    // constanst;
    enum{
        ENABLE_TEST_PATTERN     = 1,
        DISABLE_TEST_PATTERN    = 0,

        // status;
        STATUS_FRAME_BUSY       = -1,
        STATUS_FRAME_IDLE       = 0,
        STATUS_FRAME_COMPLETE   = 1
    };

    public:
        video_core_test_pattern_gen(uint32_t core_base_addr);
        ~video_core_test_pattern_gen();

        // enable or disable the pattern generator;
        void set_state(int usr_sw); 

        // wrapper for the above;
        void enable(void);  
        void disable(void); 

        // is the test pattern enabled or not;
        // for sanity check;
        int get_state(void);  

        // get the frame status
        int get_frame_status(void);  

        // wrappers for the above;
        int is_frame_idle(void);
        int is_frame_complete(void);    
        
    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;

        int pcurr_state;    // keep track of the state: on or off?

};


// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_TEST_PATTERN_GEN_H