#ifndef _VIDEO_CORE_SRC_MUX_H
#define _VIDEO_CORE_SRC_MUX_H

/* ---------------------------------------------
Purpose : SW drivers for HW module as follows
Module  : core_video_src_mux.sv
---------------------------------------------*/
#include "io_map.h"
#include "io_reg_util.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/**************************************************************
* V2_DISP_SRC_MUX
-----------------------

purpose:
1. direct which pixel source to the LCD: test pattern generator(s) or from the camera?
2. allocate 6 pixel sources for future purposes;
3. in actuality; should be only between the test pattern generators and the camera;

important note:
1. all pixel sources (inc camera) are mutually exclusive;

Register Map
1. register 0 (offset 0): select register; 
        bit[2:0] for multiplexing;
        3'b001: test pattern generator;
        3'b010: camera ov7670;
        3'b100: none;
        
Register Definition:
1. register 0: control register;
        
Register IO access:
1. register 0: write and readl
******************************************************************/


class video_core_src_mux{

    // register map;
    enum{
        // there is only one reg;
        REG_SEL_OFFSET = 0  
    };

    // source selection;
    enum{
        SEL_TEST  = 1,  //   3'b001  // from the test pattern generator;
        SEL_CAM   = 2,  //  3'b010  // from the camera OV7670;
        SEL_NONE  = 4   //   3'b100  // nothing;
    };

    public:
        video_core_src_mux(uint32_t core_base_addr);
        ~video_core_src_mux();

        // select which pixel source to display on the lcd?
        void select_src(int usr_select);

        // wrapper for the above;
        void select_test(void);         // hw test pattern generator;
        void select_camera(void);       // from the camera ov7670;
        void disable_pixel_src(void);   // none;

        // read the hw register to check for which source is being selected;
        // this is for sanity check;
        int read_curr_sel(void);    

    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;

        int pselect;    // keep track of the source selection;

};


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_SRC_MUX_H