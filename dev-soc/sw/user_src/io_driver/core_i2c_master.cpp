#include "core_i2c_master.h"


core_i2c_master::core_i2c_master(uint32_t core_base_addr){
    /*
    @brief  : constructor to instantiate an object of class: core_i2c_master;
    @param  : core_base_addr
                - the base address of the SPI core resides
                    on the microblaze IO bus address;
    @retval : none
     */
    base_addr = core_base_addr;
    scl_freq = 10000; // default: 10kHz;
}


// empty destructor;
core_i2c_master::~core_i2c_master(){};


int core_i2c_master::set_freq(int user_freq){
    /*
    @brief  : to set i2c master scl clock rate (Hz);
    @param  : user_freq, user-specified;
    @retval : none
    */

   /* background;
   1. the scl clock rate is determined by its clock
   counter modulus;
   
   formula;

   scl_mod = (sys_freq)/(4*scl_freq) - 1;

   */

    // if this condition is true;
    // then the calculated mode will be <= 0;
    // this is not desirable;
    if(user_freq >= 4*SYS_CLK_FREQ_HZ){
        return STATUS_SET_FREQ_ERROR;
    }

    // update the private var;
    scl_freq = user_freq;

    uint32_t scl_mod = (uint32_t)ceil(SYS_CLK_FREQ_HZ/(4*user_freq) - 1);
    REG_WRITE(base_addr, REG_CLKMOD_OFFSET, scl_mod);
    return STATUS_SET_FREQ_OK;
}

