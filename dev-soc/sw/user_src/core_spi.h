#ifndef _CORE_SPI_H
#define _CORE_SPI_H

/* ---------------------------------------------
Purpose: SW drivers for spi core;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"
#include "math.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

class core_spi{
    // register map;
    enum{
        REG_STATUS_OFFSET   = S5_SPI_REG_STATUS_OFFSET, 
        REG_SS_OFFSET       = S5_SPI_REG_SS_OFFSET,
        REG_MOSI_WR_OFFSET   = S5_SPI_REG_MOSI_WR_OFFSET,
        REG_MISO_RD_OFFSET = S5_SPI_REG_MISO_RD_OFFSET,
        REG_CTRL_OFFSET = S5_SPI_REG_CTRL_OFFSET,
        REG_SCLK_MOD_OFFSET = S5_SPI_REG_SCLK_MOD_OFFSET,
        REG_DC_OFFSET = S5_SPI_REG_DC_OFFSET
    };

    // masking 
    enum{
        FIELD_MISO_RD_BYTE = 0x000000FF,
        BIT_POS_CTRL_CPOL = S5_SPI_REG_CTRL_BIT_POS_CPOL,
        BIT_POS_CTRL_CPHA = S5_SPI_REG_CTRL_BIT_POS_CPHA,
        BIT_POS_STATUS_READY = S5_SPI_REG_STATUS_BIT_POS_READY,
        BIT_POS_DC = S5_SPI_REG_DC_BIT_POS_DC,
        
        MASK_CTRL_CPOL = BIT_MASK(BIT_POS_CTRL_CPOL),
        MASK_CTRL_CPHA = BIT_MASK(BIT_POS_CTRL_CPHA),
        MASK_STATUS_READY = BIT_MASK(BIT_POS_STATUS_READY),
        MASK_POS_DC = BIT_MASK(BIT_POS_DC)
    };
    
    // codes: returned value constants;
    enum{
        STATUS_SPI_READY = 1
    };

    // misc;
    enum{

        // extra external (optional) SPI pin to signal
        // to the slave whether the current mosi
        // byte is data or command?
        SPI_MOSI_BYTE_IS_DATA = 1,  // zero for command;

        // slave select signal;
        SPI_SS_ASSERT = 0,  // recall; active low
        SPI_SS_DEASSERT = 1 
    

    };

    public:
        core_spi(uint32_t core_base_addr);
        ~core_spi();

        // SPI settings;
        void set_transfer_mode(int user_cpol, int user_cpha);
        void set_sclk(uint32_t user_freq);
        
        // extra HW SPI pin to indicate to the slave whether the current MOSI data byte is a command or data;
        void set_dc(int dcx);  

        // slave select;
        // note it is active low (to select a given slave)
        // there could be multiple slave;
        void set_ss_n(uint32_t user_vector);                    // set up the initial SS status for all slaves;
        void set_ss_n(int ss_signal, int which_slave);   // overloaded; individual control;
        void assert_ss(int which_slave);
        void deassert_ss(int which_slave);

        // status;
        int check_ready(void);  // HIGH means free;

        // start the spi transaction;
        uint8_t full_duplex_transfer(uint8_t wr_mosi_data);
        uint8_t full_duplex_transfer(uint8_t wr_mosi_data, int dc);

    private:
        uint32_t base_addr;     
        uint32_t ss_n_vector;   // slave select confi;
        
        uint32_t sclk_mod;      // for debugging purpose;
        uint32_t sclk_freq;     // spi clock freq;
        
        // transfer mode;
        int cpol;       
        int cpha;

};

#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_SPI_H