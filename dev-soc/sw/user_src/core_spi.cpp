#include "core_spi.h"


core_spi::core_spi(uint32_t core_base_addr){
    /*
    @brief  : constructor to instantiate an object of class: core_spi;
    @param  : core_base_addr
                - the base address of the SPI core resides
                    on the microblaze IO bus address;
    @retval : none
     */
    base_addr = core_base_addr;
    
    // by default; deselect all connected slave;
    ss_n_vector = (uint32_t) 0xFFFFFFFF;

    // spi clock;
    sclk_freq = 10000000; // default: 10MHz;
    // please see the set_sclk() method on the formula;
    //sclk_mod = 4;   // this gives 10Mhz SPI clock freq;
    set_sclk(sclk_freq);

    // transfer mode; usually this combo?
    cpol = 0;
    cpha = 0;
}

// destructor;
// not used;
core_spi::~core_spi() {}


