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
    set_freq(scl_freq);
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

   // block until the master controller is ready;
   while(!is_ready()){};
   REG_WRITE(base_addr, REG_WRITE_OFFSET, CMD_START);
}

void core_i2c_master::send_repeat_start(void){
     /*
    @brief  : to send a repeat start condition (as a master)
    @param  : none
    @note   : this is a blocking method;
    */

   // block until the master controller is ready;
   while(!is_ready()){};
   REG_WRITE(base_addr, REG_WRITE_OFFSET, CMD_REPEAT);
}


void core_i2c_master::send_stop(void){
     /*
    @brief  : to send a stop condition (as a master)
    @param  : none
    @note   : this is a blocking method;
    */

   // block until the master controller is ready;
   while(!is_ready()){};
   REG_WRITE(base_addr, REG_WRITE_OFFSET, CMD_STOP);
}

int core_i2c_master::write_byte(uint8_t data_byte){
    /*
    @brief  : to transfer a data byte from master to the slave;
    @param  : data_byte to write;
    @retval :   binary error indication
        +1 if the slave returns a valid ACK;
        -1 otherwise;
    @note   : this is a blocking method;
    */


   /* var declar*/
   uint32_t rd_data;
   int ack;

   // there is only one write register for sending data;
   // this register also packs other stuffs as well;
   // so need to pack or unpack;
    uint32_t packed;
   
   // blocked until ready;
   while(!is_ready()){};

    // start writing;
    packed = (CMD_WR | (uint32_t)data_byte);
    REG_WRITE(base_addr, REG_WRITE_OFFSET, packed);

   // blocked until ready;
   while(!is_ready()){};

    // read and check the ack from the slave;
   rd_data = (uint32_t)REG_READ(base_addr, REG_READ_OFFSET);
   ack = (int) ((rd_data & MASK_READ_ACK) >> BIT_POS_READ_ACK);
   if(ack == SLAVE_ACK_MASTER){
        return STATUS_I2C_SLAVE_ACK_OK;
   }
   return STATUS_I2C_SLAVE_ACK_ERROR;

}