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
    // set the register;
    REG_WRITE(base_addr, REG_CLKMOD_OFFSET, scl_mod);
    return STATUS_SET_FREQ_OK;
}

int core_i2c_master::is_ready(void){
    /*
    @brief  : to see if the i2c master controller is ready to accept any user command;
    @param  : none;
    @retval :
        HIGH if ready;
        LOW otherwise;
    */
   uint32_t rd_data;
   rd_data = REG_READ(base_addr, BIT_POS_READ_READY);
   return (int)((rd_data & MASK_READ_READY) >> BIT_POS_READ_READY);
}


void core_i2c_master::send_start(void){
     /*
    @brief  : to send a start condition (as a master)
    @param  : none
    @note   : this is a blocking method;
    */

   // there is only one HW register to send the command;
   // this register also packs other non-command data as well;
   // bit[7:0] packs the master write data byte;
   // bit[10:8] packs the user commands;
   
   uint32_t temp = ((uint32_t)CMD_START << BIT_POS_CMD_OFFSET);
   uint32_t packed = temp | DUMMY_DATA_BYTE;
   
   // block until the master controller is ready;
   while(!is_ready()){};

   REG_WRITE(base_addr, REG_WRITE_OFFSET, packed);

}

void core_i2c_master::send_repeat_start(void){
     /*
    @brief  : to send a repeat start condition (as a master)
    @param  : none
    @note   : this is a blocking method;
    */

   // there is only one HW register to send the command;
   // this register also packs other non-command data as well;
   // bit[7:0] packs the master write data byte;
   // bit[10:8] packs the user commands;
   
   uint32_t temp = ((uint32_t)CMD_REPEAT << BIT_POS_CMD_OFFSET);
   uint32_t packed = temp | DUMMY_DATA_BYTE;
   
   // block until the master controller is ready;
   while(!is_ready()){};

   REG_WRITE(base_addr, REG_WRITE_OFFSET, packed);

}


void core_i2c_master::send_stop(void){
     /*
    @brief  : to send a stop condition (as a master)
    @param  : none
    @note   : this is a blocking method;
    */

   // there is only one HW register to send the command;
   // this register also packs other non-command data as well;
   // bit[7:0] packs the master write data byte;
   // bit[10:8] packs the user commands;
   
   uint32_t temp = ((uint32_t)CMD_STOP << BIT_POS_CMD_OFFSET);
   uint32_t packed = temp | DUMMY_DATA_BYTE;
   
   // block until the master controller is ready;
   while(!is_ready()){};

   REG_WRITE(base_addr, REG_WRITE_OFFSET, packed);

}
