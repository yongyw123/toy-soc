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

void core_spi::set_transfer_mode(int user_cpol, int user_cpha){
    /*
    @brief  : to set the spi transfer mode;
    @param  :
        user_cpol for cpol;
        user_cpha for cpha;
    @retval : none
    */

    uint32_t placeholder;

    // update the data;
    if(user_cpol == 1){
        placeholder = MASK_CTRL_CPOL;

    }else{
        placeholder &= ~MASK_CTRL_CPOL;
    }

    if(user_cpha == 1){
        placeholder |= MASK_CTRL_CPHA;
    }else{
        placeholder &= ~MASK_CTRL_CPHA;
    }

    // update the register;
    REG_WRITE(base_addr, REG_CTRL_OFFSET, placeholder);

}

void core_spi::set_sclk(uint32_t user_freq){
    /*
    @brief  : to set spi clock rate;
    @param  : user_freq - frequency (Hz)
    @retval : none
    */

   /* background;
   HW spi clock is essentially a counter
   that wraps around (mod);

   so, need to program this mod to reflect the user_freq;

   formula;
   say;
   mod, m 
   system freq; fsys;
   spi freq;    user_freq;

   m = fsys(2*user_freq) - 1; 
   */

    uint32_t sclk_mod;
    sclk_mod = (uint32_t) ceil(SYS_CLK_FREQ_MHZ/(2*user_freq) - 1);
    // update the register;
    REG_WRITE(base_addr, REG_SCLK_MOD_OFFSET, sclk_mod);
}






