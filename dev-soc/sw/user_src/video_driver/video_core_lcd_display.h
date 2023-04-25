#ifndef _VIDEO_CORE_LCD_DISPLAY_H
#define _VIDEO_CORE_LCD_DISPLAY_H

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

/**************************************************************
* V0_DISP_LCD
--------------------
this core wraps this module: LCD display controller 8080;
this is for the ILI9341 LCD display via mcu 8080 (protocol) interface;

this has six (6) registers;

Register Map
1. register 0 (offset 0): read register 
2. register 1 (offset 1): program write clock period
3. register 2 (offset 2): program read clock period;
4. register 3 (offset 3): write register;
5. register 4 (offset 4): stream control register;
6. register 5 (offset 5): chip select register

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
        bit[10:9]  : to store user commands;
        
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

5. register 5: chip select;
            this is probably not necessary;
            since this could be done using general purpose pin;
            and emulated through SW;
            bit[0]  
                0: chip deselect;
                1: chip select
            
Register IO access:
1. register 0: read only;
2. register 1: write only;
3. register 2: write only;
4. register 3: write only;
5. register 4: write only;
6. register 5: write only;
******************************************************************/

class video_core_lcd_display{

    // register map;
    enum{
        REG_RD_DATA_OFFSET = 0,
        REG_CLOCKMOD_WR_OFFSET = 1,
        REG_CLOCKMOD_RD_OFFSET = 2,
        REG_WR_DATA_OFFSET = 3,
        REG_STREAM_CTRL_OFFSET = 4,
        REG_CSX_OFFSET = 5
    };

    // field and bit maskings;
    enum{
        // lcd display controller status;
        BIT_POS_REG_RD_DATA_STATUS_READY = V0_DISP_LCD_REG_STATUS_BIT_POS_READY,
        MASK_REG_RD_DATA_STATUS_READY = BIT_MASK(BIT_POS_REG_RD_DATA_STATUS_READY),

        /* ------------------------------------
        the write register packed different data;
        so need to adjust the position;
        ------------------------------------ */

        // hw pin control: data or command;
        BIT_POS_REG_WR_DATA_DCX = V0_DISP_LCD_REG_WR_DATA_BIT_POS_DCX,
        

        // clock mod;
        BIT_POS_REG_CLKMOD_SHALF = 16,  // second half;

        // user command start position;
        BIT_POS_REG_WR_DATA_CMD_OFFSET = 9,


        /*
        stream control;
        who has the control over the lcd display interface;
        the cpu or other video core (pixel src)?
        */
        BIT_POS_STREAM_CTRL = 0,

        // csx;
        BIT_POS_CSX = 0
    };

    // commands;
    enum{
        /* the write register packed different data;
        so need to adjust the position;
        */
       CMD_NOP = ((uint32_t)0x00 << BIT_POS_REG_WR_DATA_CMD_OFFSET),
       CMD_WR = ((uint32_t)0x01 << BIT_POS_REG_WR_DATA_CMD_OFFSET),
       CMD_RD = ((uint32_t)0x02 << BIT_POS_REG_WR_DATA_CMD_OFFSET)
    };

    public:
        video_core_lcd_display(uint32_t core_base_addr);
        ~video_core_lcd_display();

        // config;
        void set_clockmod(int usr_wrx_l, int usr_wrx_h, int usr_rdx_l, int usr_rdx_h);
        void set_stream(int set_cpu_control);

        // status;
        int is_ready(void);

        // communication setting;
        void enable_chip(void); // chip select; active low;
        void disable_chip(void); 
        
        // rw;
        void write(int is_data, uint8_t data); // write to the lcd;
        uint8_t read(void);        // read from the lcd;

    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;

        // the clock mod setting;
        int wrx_l;
        int wrx_h;
        int rdx_l;
        int rdx_h;

};


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_LCD_DISPLAY_H