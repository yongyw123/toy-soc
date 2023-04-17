#ifndef _CORE_SPI_H
#define _CORE_SPI_H

/* ---------------------------------------------
Purpose: SW drivers for spi core;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"

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

    public:
        core_spi(uint32_t core_base_addr);
        ~core_spi();

        void set_transfer_mode(int user_cpol, int user_cpha);
        void set_sclk(int user_freq);

        void set_dc(int dcx);


    private:
        uint32_t base_addr;     
        uint32_t ss_n_vector;   // slave select confi;
        
        //uint32_t sclk_mod;      // spi clock setting;
        uint32_t sclk_freq;     // spi clock freq;
        
        // transfer mode;
        int cpol;       
        int cpha;

};

#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_SPI_H