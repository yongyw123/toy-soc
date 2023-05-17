#ifndef _VIDEO_CORE_PIXEL_CONVERTER_MONOY2RGB565_H
#define _VIDEO_CORE_PIXEL_CONVERTER_MONOY2RGB565_H


/* ---------------------------------------------
Purpose: SW drivers for the following HW video core;
Core: core_video_pixel_converter_monoY2RGB565
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "user_util.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/******************************************************************
V4_PIXEL_COLOUR_CONVERTER
--------------------------
Purpose: if the camera output is in YUV422, then a conversion is needed
because LCD only accepts RGB565 format;

Construction:
1. for convenience, only the Y of the YUV422 is converted; 
2. hence, the LCD display will be grayscale;

Assumption:
1. the camera output YUV422 configuration is UYVY;
2. the Y appears as every second byte;
3. this could be configured on the camera OV7670 side;

------------
Register Map
1. register 0 (offset 0): control register;
        
Register Definition:
1. register 0: control register;
        bit[0] bypass the colour converter
        0: "disabled" to bypass the colour converter;
        1: "enabled" to go through the colour converter;
                    
Register IO access:
1. register 0: write and read;
******************************************************************/

class video_core_pixel_converter_monoY2RGB565{

    // register map;
    enum{
        REG_CTRL_OFFSET = V4_PIXEL_COLOUR_CONVERT_REG_CTRL        
    };

    // field and bit maskings;
    enum{        
        BIT_POS_CTRL = V4_PIXEL_COLOUR_CONVERT_REG_CTRL_BIT_POS,
        MASK_CTRL = BIT_MASK(BIT_POS_CTRL)
        
    };

    enum{
        ENABLE_PIXEL_CONVERTER = 1,
        DISABLE_PIXEL_CONVERTER = 0   
    };

    public:
        video_core_pixel_converter_monoY2RGB565(uint32_t core_base_addr);
        ~video_core_pixel_converter_monoY2RGB565();

        int read_control(void);
        void set_control(int enable_converter);
        // wrapper for the above;
        void enable_converter(void);
        void disable_converter(void);
        
    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;
        
        // current state; 
        int is_converter_enabled;   
};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_PIXEL_CONVERTER_MONOY2RGB565_H