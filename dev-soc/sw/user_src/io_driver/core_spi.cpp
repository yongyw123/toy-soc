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
    sclk_mod = 4;   // for debugging; this gives 10Mhz SPI clock freq;
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

    uint32_t placeholder = 0x00000000;
    
    // update the private variable;
    cpol = user_cpol;
    cpha = user_cpha;

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

    uint32_t user_mod;

    // update the private variable;
    sclk_freq = user_freq;
    sclk_mod = user_mod;

    // compute;
    user_mod = (uint32_t) ceil(SYS_CLK_FREQ_MHZ/(2*user_freq) - 1);
    
    // update the register;
    REG_WRITE(base_addr, REG_SCLK_MOD_OFFSET, user_mod);
}

void core_spi::set_dc(int dcx){
    /*
    @brief  : to set the extra (optional) SPI HW pin
                to indicate to the slave whether the current mosi
                data byte is a data or command;
    @param  : dcx - HIGH for data; LOW otherwise;
    @retval : none
    */

   uint32_t placeholder = 0x00000000;
   if(dcx == SPI_MOSI_BYTE_IS_DATA){
        // set the bit;
        placeholder |= (uint32_t)MASK_POS_DC;
   }else{
        // clear the bit;
        placeholder &= ~(uint32_t)MASK_POS_DC;
   }
   // update the reg;
   REG_WRITE(base_addr, REG_DC_OFFSET, placeholder);
}

void core_spi::set_ss_n(uint32_t user_vector){
    /*
    @brief  : to set the initial value of the slave select status of the slaves;
    @param  : user_vector, a vector where each element corresponds to a slave;
    @retval : none
    @note   : slave select is active low;
    */

   // update the private vari;
   ss_n_vector = user_vector;

   // update the register;
   REG_WRITE(base_addr, REG_SS_OFFSET, user_vector);
}


void core_spi::set_ss_n(int ss_signal, int which_slave){
    /*
    @brief  : to set an individual slave;
    @param  : 
            ss_signal: HIGH to assert the slave; LOW otherwise;
            which_slave: which slave to set the ss_signal
    @retval : none
    @note   : slave select is active low;
    */

   // get the existing ss_vector;
   uint32_t placeholder = ss_n_vector;

    // bit clear first;
    placeholder &= ~BIT_MASK(which_slave);

    // the slave is selected;
    if(ss_signal == SPI_SS_ASSERT){
        // recall; it is active low;
       placeholder &= ~BIT_MASK(which_slave);
    }else{
        placeholder |= BIT_MASK(which_slave);
    }
    
    // update the private variable;
    ss_n_vector = placeholder;

    // update the reg;
    REG_WRITE(base_addr, REG_SS_OFFSET, ss_n_vector);
}

void core_spi::assert_ss(int which_slave){
    /*
    @brief  : to select which slave?
    @param  : 
        which_slave - this corresponds to which port the slave is connected to;
    @retval : none
    @note   : slave select is active low;
    */
   set_ss_n(SPI_SS_ASSERT, which_slave);

}

void core_spi::deassert_ss(int which_slave){
    /*
    @brief  : to deselect which slave?
    @param  : 
        which_slave - this corresponds to which port the slave is connected to;
    @retval : none
    @note   : slave select is active low;
    */
   set_ss_n(SPI_SS_DEASSERT, which_slave);
}

int core_spi::check_ready(void){
    /* 
    @bried  : check whether the SPI is busy or ready (free);
    @param  : none;
    @retval : status of the SPI: HIGH if ready;

    */

   uint32_t status;
   status = REG_READ(base_addr, REG_STATUS_OFFSET);
   
   // the status is at LSB;
   return (int)((status >> BIT_POS_STATUS_READY) & (uint32_t)0xF);
}

uint8_t core_spi::full_duplex_transfer(uint8_t wr_mosi_data){
    /*
    @brief  : to start the SPI with the connected (asserted) slave;
    @param  : wr_mosi_data: data byte to transfer to the slave;
    @note   : this is a blocking method;
    @note   : MSB is first transmitted on the MOSI line;
    @note   : supported data size is 8-bot
    @note   : this assumes a full duplex transfer;

    */

    uint32_t wr_data;
    uint32_t rd_data;

    /* initiate write, hence spi */
    // register write assumes 32-bit wide;
    // clear the rest that is not part of the data byte;
    
    wr_data = (((uint32_t) wr_mosi_data) & FIELD_MISO_RD_BYTE);
    // block until spi is free;
    while(!check_ready());
    REG_WRITE(base_addr, REG_MOSI_WR_OFFSET, wr_data);

    /* read */
    // block until spi is free;
    while(!check_ready());
    rd_data = (uint32_t)REG_READ(base_addr, REG_MISO_RD_OFFSET);
    return (uint8_t)(rd_data & FIELD_MISO_RD_BYTE);
}

uint8_t core_spi::full_duplex_transfer(uint8_t wr_mosi_data, int dc){
    /*
    @brief  : to start the SPI with the connected (asserted) slave;
    @param  : 
        wr_mosi_data: data byte to transfer to the slave;
        dc          : is the data byte a data or command for the slave;
    @retval : the miso data byte received;
    @note   : MSB is first transmitted on the MOSI line;
    @note   : this is a blocking method;
    @note   : this assumes a full duplex transfer;
    */

   // set the dc;
   set_dc(dc);

    uint32_t wr_data;
    uint32_t rd_data;

    /* initiate write, hence spi */
    // register write assumes 32-bit wide;
    // clear the rest that is not part of the data byte;

    wr_data = (((uint32_t) wr_mosi_data) & FIELD_MISO_RD_BYTE);
    // block until spi is free;
    while(!check_ready());
    REG_WRITE(base_addr, REG_MOSI_WR_OFFSET, wr_data);

    /* read */
    // block until spi is free;
    while(!check_ready());
    rd_data = (uint32_t)REG_READ(base_addr, REG_MISO_RD_OFFSET);
    return (uint8_t)(rd_data & FIELD_MISO_RD_BYTE);
}