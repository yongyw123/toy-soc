#ifndef _CORE_VIDEO_LCD_DISPLAY_H
#define _CORE_VIDEO_LCD_DISPLAY_H

/* ---------------------------------------------
Purpose: SW drivers for video LCD display core;
Device: LCD-TFT (ILI9341)
Device Interface Protocol: MCU 8080-I Series;
---------------------------------------------*/
#include "io_map.h"
#include "io_reg_util.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/*------------------------------------------------------------------
core: video lcd display
--------------------
this core wraps this module: LCD display controller 8080;
this is for the ILI9341 LCD display via mcu 8080 (protocol) interface;

this has five (5) registers;

Register Map
1. register 0 (offset 0): read register 
2. register 1 (offset 1): program write clock period
3. register 2 (offset 2): program read clock period;
4. register 3 (offset 3): write register;
5. register 4 (offset 4): stream control register;

Register Definition:
1. register 0: status and read data register
        bit[7:0]    : data read from the lcd;
        bit[8]      : ready flag;  // the lcd controller is idle
                        1: ready;
                        0: not ready;
                 
        bit[9]      : done flag;   // [optional ??] when the lcd just finishes reading or writing;
                        1: done;
                        0: not done;
        
2. register 1: program the write clock period;
        bit[15:0] defines the clock counter mod for LOW WRX period;
        bit[31:16] defines the clock counter mod for HIGH WRX period;

2. register 2: program the read clock period;
        bit[15:0] defines the clock counter mod for LOW RDX period;
        bit[31:16] defines the clock counter mod for HIGH RDX period;

3. register 3: write data and data mode;
        bit[7:0]    : data to write to the lcd;
        bit[8]      : is the data to write a DATA or a COMMAND for the LCD?
                        0 for data;
                        1 for command;
        bit[9]      : chip select;
                        0: chip deselect;
                        1: chip select
        bit[11:10]  : to store user commands;
        
4. register 4: stream control register
            there are two flows:
            flow one is from thh processor (hence SW app/driver);
            flow two is from other video source stream such as the camera;
            flow two will be automatically completed through a feedback loop
            via handshaking mechanism without any user/processor intervention
            until this stream control is updated again;
             
        bit[0]: 
            1 for stream flow;
            0 for processor flow; 
            
Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;
4. register 3: write only;
5. register 4: stream control register;
--------------------------------------------------------------*/

class video_core_lcd_display{

    // register map;
    enum{
        REG_RD_DATA_OFFSET = 0,
        REG_CLOCKMOD_WR_OFFSET = 1,
        REG_CLOCKMOD_RD_OFFSET = 2,
        REG_WR_DATA_OFFSET = 3,
        REG_STREAM_CTRL_OFFSET = 4
    };

    // field and bit maskings;
    enum{
        // lcd display controller status;
        BIT_POS_REG_RD_DATA_STATUS_READY = V0_DISP_LCD_REG_STATUS_BIT_POS_READY,
        

        /* ------------------------------------
        the write register packed different data;
        so need to adjust the position;
        ------------------------------------ */

        /* hw pin control;
        data or command;
        chip select;
        */
        BIT_POS_REG_WR_DATA_DCX = V0_DISP_LCD_REG_WR_DATA_BIT_POS_DCX,
        BIT_POS_REG_WR_DATA_CSX = V0_DISP_LCD_REG_WR_DATA_BIT_POS_CSX,

        // user command start position;
        BIT_POS_REG_WR_DATA_CMD_OFFSET = 10,


        /*
        stream control;
        who has the control over the lcd display interface;
        the cpu or other video core (pixel src)?
        */
        BIT_POS_STREAM_CTRL = 0
    };

    // commands;
    enum{
        /* the write register packed different data;
        so need to adjust the position;
        */
       CMP_NOP = ((uint32_t)0x00 << BIT_POS_REG_WR_DATA_CMD_OFFSET),
       CMD_WR = ((uint32_t)0x01 << BIT_POS_REG_WR_DATA_CMD_OFFSET),
       CMD_RD = ((uint32_t)0x02 << BIT_POS_REG_WR_DATA_CMD_OFFSET)
    };

    public:
        

};


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_VIDEO_LCD_DISPLAY_H