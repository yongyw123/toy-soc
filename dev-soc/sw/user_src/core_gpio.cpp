#include "core_gpio.h"

/* ----------------------------------------
* general purpose output (only)
------------------------------------------*/
core_gpo::core_gpo(uint32_t core_base_addr){
    base_addr = core_base_addr;
    wr_data = 0;
}

// destructor; null;
core_gpo::~core_gpo()   {}

// methods;
void core_gpo::write(uint32_t data){
    wr_data = data;
    REG_WRITE(base_addr, REG_DATA_OFFSET, wr_data);
}

void core_gpo::write(uint32_t bit_pos, uint32_t bit_val){
    if(bit_val == 1){
        BIT_CLEAR(wr_data, bit_pos);
        BIT_SET(wr_data, bit_pos);
    }else{
        BIT_CLEAR(wr_data, bit_pos);
    }

    REG_WRITE(base_addr, REG_DATA_OFFSET, wr_data);
}

void core_gpo::toggle(void){
    wr_data = (uint32_t)(wr_data ^ (uint32_t)(0xFFFFFFFF));
    REG_WRITE(base_addr, REG_DATA_OFFSET, wr_data);
}

void core_gpo::toggle(uint32_t bit_pos){
    wr_data ^= ((1UL) << bit_pos);
    REG_WRITE(base_addr, REG_DATA_OFFSET, wr_data);
}



/* ----------------------------------------
* general purpose input (only)
------------------------------------------*/
core_gpi::core_gpi(uint32_t core_base_addr){
    base_addr = core_base_addr;
}

// destructor; null;
core_gpi::~core_gpi()   {}

// methods;
uint32_t core_gpi::read(void){
    return REG_READ(base_addr, REG_DATA_OFFSET);
}

uint8_t core_gpi::read(uint32_t bit_pos){
    uint32_t rd_data = REG_READ(base_addr, REG_DATA_OFFSET);
    return (uint8_t)((rd_data >> bit_pos) & 0xFF);   
}



/* ----------------------------------------
* general purpose input and output;
------------------------------------------*/
// constructor;
core_gpio::core_gpio(uint32_t core_base_addr){
    base_addr = core_base_addr;
    direction_data = (uint32_t)CTRL_DIRECTION_READ; // by default after reset;
    wr_data = (uint32_t)0x00000000;
}

// destructor; null;
core_gpio::~core_gpio()   {}

// methods;
void core_gpio::set_direction(int which_port, uint32_t direction){
    /*
    * @brief: set the port direction;
    * @param:
    *   which_port  : which port to set the direction? 
    *   direction   : HIGH to set output direction; LOW otherwise;
    * @retval       : none
    *
    */
   
    /* update the given bit of the direction data
    corresponding to the port;*/
    if(direction == CTRL_DIRECTION_WRITE){
        BIT_CLEAR(direction_data, which_port);  // clear first;
        BIT_SET(direction_data, which_port);    
    }
    
    // read direction;
    else{
        BIT_CLEAR(direction_data, which_port);  // clear == LOW:
    }
    
    // update the ctrl register;
    REG_WRITE(base_addr, REG_CTRL_DIR_OFFSET, direction_data);
}

int core_gpio::read(int which_port){
    /*
    @brief  : read the data from a specified port;
    @param  : which port?
    @retval : the read data;
    */
    uint32_t rd_data = REG_READ(base_addr, REG_READ_DATA_OFFSET);
    return (int)((rd_data & BIT_MASK(which_port)) >> which_port);
    
    //return ((int)(rd_data >> which_port) & 0xFF);   
    
}

uint32_t core_gpio::read(void){
    /*
    @brief  : read from the entire gpio pins (regardless of the direction set)
    @param  : none
    @retval : a vector of the read data status of the entire gpio pins;
    */
    
    uint32_t rd_data = REG_READ(base_addr, REG_READ_DATA_OFFSET);
    return (uint32_t)(rd_data);   
}


void core_gpio::write(int which_port, uint32_t data){
    /*
    @brief      : write a data to a specified port;
    @param      : which port?
    @retval     : none
    @assumption : the specified port has its direction set to out;
    */
    
    if(data == 1){
        BIT_CLEAR(wr_data, which_port);
        BIT_SET(wr_data, which_port);
    }else{
        BIT_CLEAR(wr_data, which_port);
    }

    REG_WRITE(base_addr, REG_WRITE_DATA_OFFSET, wr_data);
}

uint32_t core_gpio::read_ctrl_reg(void){
    /*
    @brief  : to read the control register;
    @param  : none
    @retval : 32-bit control register data;
    */

    return (uint32_t)(REG_READ(base_addr, REG_CTRL_DIR_OFFSET));
}

int core_gpio::read_ctrl_reg(int which_port){
    /*
    @brief  : to read the direction set for a specified port;
    @param  : which port to read?
    @retval : the direction status of the port
    */
   uint32_t read_data = (uint32_t)(REG_READ(base_addr, REG_CTRL_DIR_OFFSET));
   return (int)((read_data & BIT_MASK(which_port)) >> which_port);
   //return (int)((read_data >> which_port) & 0xFF);
}


int core_gpio::get_ctrl_dir_read(void){
    return CTRL_DIRECTION_READ;
}

int core_gpio::get_ctrl_dir_write(void){
    return CTRL_DIRECTION_WRITE;
}

uint32_t core_gpio::debug_get_dir(void){
    /*
    @brief  : to get the object current private direction setting; 
    @note   : compare against the data read from the control register;
    @param  : none
    @retval : class object current private direction setting;
    */
    return direction_data;
}