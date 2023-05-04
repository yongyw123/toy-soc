#ifndef _VIDEO_CORE_DCMI_INTERFACE_H
#define _VIDEO_CORE_DCMI_INTERFACE_H

/* ---------------------------------------------
Purpose: SW drivers for DCMI interface core
Device: Camera OV7670
Device Interface Protocol:  DCMI synchronization signals
---------------------------------------------*/
#include "io_map.h"
#include "io_reg_util.h"
#include "user_util.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif
/**************************************************************
* V3_CAM_DCMI_IF
-----------------------
Camera DCMI Interface

Purpose:
1. Mainly, to interface with camera OV7670 which drives the synchronization signals;
2. Note that this is asynchronous since this module is driven by OV7670 24MHz PCLK;

Constituent Block:
1. A dual-clock BRAM FIFO for the cross time domain;
      
Assumptions:
1. The synchronization signal settings are fixed; 
    thus; require the camera to be configured apriori;
    
Issue + Constraint:
1. The DUAL-CLOCK BRAM FIFO is a MACRO;
2. there are conditions to meet before this FIFO could operate;
3. Mainly, its RESET needs to satisfy the following:  
    Condition: A reset synchronizer circuit has been introduced to 7 series FPGAs. RST must be asserted
    for five cycles to reset all read and write address counters and initialize flags after
    power-up. RST does not clear the memory, nor does it clear the output register. When RST
    is asserted High, EMPTY and ALMOSTEMPTY are set to 1, FULL and ALMOSTFULL are
    reset to 0. The RST signal must be High for at least five read clock and write clock cycles to
    ensure all internal states are reset to correct values. During Reset, both RDEN and WREN
    must be deasserted (held Low).
    
        Summary: 
            // read;
            1. RESET must be asserted for at least five read clock cycles;
            2. RDEN must be low before RESET is active HIGH;
            3. RDEN must remain low during this reset cycle
            4. RDEN must be low for at least two RDCLK clock cycles after RST deasserted
            
            // write;
            1. RST must be held high for at least five WRCLK clock cycles,
            2. WREN must be low before RST becomes active high, 
            3. WREN remains low during this reset cycle.
            4. WREN must be low for at least two WRCLK clock cycles after RST deasserted;
    
4. as such, this core will have a FSM just for the above;
    this FSM will use the reset_system to create a reset_FIFO
    that satisfies the conditions above;
    once satistifed, the FSM will assert that the entire system is ready to use;
    the SW is responsible to check this syste readiness;
    the SW should not start the DCMI decoder until the system is ready!

5. by above, a register shall be created to store the system readiness;            
6. reference: "7 Series FPGAs Memory Resources User Guide (UG473);

------------
Register Map
1. register 0 (offset 0): control register;
2. register 1 (offset 1): status register;
3. register 2 (offset 2): frame counter read register;
4. register 3 (offset 3): BRAM FIFO status register;
5. register 4 (offset 4): BRAM FIFO read and write counter;  
6. register 5 (offset 5): BRAM FIFO (and system) readiness state
        
Register Definition:
1. register 0: control register;
    bit[0] start the decoder;
            0 to disable the decoder;
            1 to enable the decoder;
            *SW may need to apply a pulse: HIGH then LOW otherwise 
            the decoder will run forever;
            
    bit[1] synchronously clear decoder frame counter;
            1 yes;
            0 no;
            *SW needs to apply a pulse: HIGH then LOW otherwise 
            this clearing will forever in effect;
            
    bit[2] reset the internal fifo in case if the fifo has unresolved errors;
            1 to reset;
            0 otherwise;
            *SW needs to apply a pulse: HIGH then LOW otherwise it will
            be forever in reset-state;
             
2. register 1: status register;
    bit[0] detect the start of a frame
        1 yes; 
        0 otherwise
        *this will clear by itself;
    bit[1] detect the end of a frame (finish decoding);
        1 yes;
        0 otherwise;
        *this will clear by itself;
        
3. register 2: frame counter read register;
        bit[31:0] to store the number of frame detected;
        *note: 
            - this will overflow and wrap around;
            - will clear to zero after a system reset;

4. register 3: BRAM FIFO status register;
        bit[0] - almost empty;
        bit[1] - almost full;
        bit[2] - empty;
        bit[3] - full;
        bit[4] - read error;
        bit[5] - write error;

5. register 4: BRAM FIFO read and write counter;
        bit[15:0]   - read count;
        bit[31:16]  - write count;      
       
6. register 5: BRAM FIFO (and system) readiness state
        bit[0] 
            1 - system is ready to use;
            0 - otheriwse            

Register IO access:
1. register 0: write and read;
2. register 1: read only;
3. register 2: read only;
4. register 3: read only;
5. register 4: read only;
6. register 5: read only;
******************************************************************/
typedef struct{
    int empty;
    int almost_empty;
    int full;
    int almost_full;
    int rd_error;
    int wr_error;
}fifo_status_t;


class video_core_dcmi_interface{
    // register map;
    enum{
        REG_CTRL_OFFSET             = V3_CAM_DCMI_IF_REG_CTRL_OFFSET,
        REG_DECODER_STATUS_OFFSET   = V3_CAM_DCMI_IF_REG_DECODER_STATUS_OFFSET,
        REG_FRAME_RD_OFFSET         = V3_CAM_DCMI_IF_REG_FRAME_RD_OFFSET,
        REG_FIFO_STATUS_OFFSET      = V3_CAM_DCMI_IF_REG_FIFO_STATUS_OFFSET,
        REG_FIFO_CNT_OFFSET         = V3_CAM_DCMI_IF_REG_FIFO_CNT_OFFSET,
        REG_SYS_READY_STATUS_OFFSET = V3_CAM_DCMI_IF_REG_SYS_READY_STATUS_OFFSET
    };

    // bit positions;
    enum{        
        // decoder enable/disable
        BIT_POS_DEC_START = V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_START,
        // decoder frame counter clear;
        BIT_POS_DEC_FRAME_RST = V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_FRAME_RST,
        // reset the fifo;
        BIT_POS_FIFO_RST = V3_CAM_DCMI_IF_REG_CTRL_BIT_POS_DEC_FIFO_RST,

        // decoder start status;
        BIT_POS_DECODER_STATUS_START = V3_CAM_DCMI_IF_REG_DECODER_STATUS_BIT_POS_START,
        // decoder completion status;
        BIT_POS_DECODER_STATUS_END = V3_CAM_DCMI_IF_REG_DECODER_STATUS_BIT_POS_END,

        // macro dual-clock fifo status;
        BIT_POS_FIFO_STATUS_AEMPTY = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_AEMPTY, // almost empty;
        BIT_POS_FIFO_STATUS_AFULL  = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_AFULL, // almost full;
        BIT_POS_FIFO_STATUS_EMPTY  = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_EMPTY,  
        BIT_POS_FIFO_STATUS_FULL   = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_FULL,  
        BIT_POS_FIFO_STATUS_RDERR  = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_RD_ERROR,
        BIT_POS_FIFO_STATUS_WRERR  = V3_CAM_DCMI_IF_REG_FIFO_STATUS_BIT_POS_WR_ERROR,

        // macro dual-clock fifo counters;
        START_BIT_POS_FIFO_RD_CNT = 0,  // read count start position;
        START_BIT_POS_FIFO_WR_CNT = 16,  // write count start position;

        // system ready status;
        BIT_POS_SYS_READY_STATUS = 0
    

    };

    // masking and fields;
    enum{
        // control;
        MASK_CTRL_DEC_START = BIT_MASK(BIT_POS_DEC_START),
        
        
        // decoder status;
        MASK_DEC_STATUS_START   = BIT_MASK(BIT_POS_DECODER_STATUS_START),
        MASK_DEC_STATUS_END     = BIT_MASK(BIT_POS_DECODER_STATUS_END),

        // fifo status;
        MASK_FIFO_STATUS_AEMPTY = BIT_MASK(BIT_POS_FIFO_STATUS_AEMPTY),
        MASK_FIFO_STATUS_AFULL  = BIT_MASK(BIT_POS_FIFO_STATUS_AFULL),
        MASK_FIFO_STATUS_EMPTY  = BIT_MASK(BIT_POS_FIFO_STATUS_EMPTY),
        MASK_FIFO_STATUS_FULL   = BIT_MASK(BIT_POS_FIFO_STATUS_FULL),
        MASK_FIFO_STATUS_RDERR  = BIT_MASK(BIT_POS_FIFO_STATUS_RDERR),
        MASK_FIFO_STATUS_WRERR  = BIT_MASK(BIT_POS_FIFO_STATUS_WRERR),

        // system ready status;
        MASK_SYS_READY_STATUS = BIT_MASK(BIT_POS_SYS_READY_STATUS)

    };

    // constants/code;
    enum{
        SYS_READY = 1,        
        ENABLE_DEC = 1,
        DISABLE_DEC = 0
    };

    public:
        video_core_dcmi_interface(uint32_t core_base_addr);
        ~video_core_dcmi_interface();
        
        // to wait for the macro fifo to steady before using this dcmi interface system;
        int is_sys_ready(void); 
        
        // decoder specific;
        void set_decoder(int to_enable);
        // wrapper for the above;
        void enable_decoder(void);
        void disable_decoder(void);

        // other command;s
        void clear_decoder_counter(void);   // resetting the decoder frame counter;
        void reset_fifo(void); // manual resetting the internal fifo if all goes wrong;

        /* decoder status */
        int detect_frame_start(void);   // detect the start of a frame;
        int detect_frame_end(void); // detect the completion of a frame;

        /* check the macro fifo status; */
        fifo_status_t get_fifo_status(void);

        // wrapper for the above;    
        // almost full, almost empty not constructed;
        int is_fifo_full(void);     // fully full?;
        int is_fifo_empty(void);    // fully empty?
        int is_fifo_ok(void);       // any errors reported?

        
        

        /* check fifo counters */
        uint16_t get_fifo_rd_count(void);
        uint16_t get_fifo_wr_count(void);
    

    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;
        
        // readiness state; if fifo is not ready; the entire system
        // will break down;
        int system_ready_p;

        // state of the control register;
        int ctrl_state_p;  

        // state of the fifo:  any errors, etc?
        fifo_status_t fifo_status_p;

};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_DCMI_INTERFACE_H