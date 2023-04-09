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
        BIT_SET(wr_data, bit_pos);
    }else{
        BIT_CLEAR(wr_data, bit_pos);
    }

    REG_WRITE(base_addr, REG_DATA_OFFSET, wr_data);
}

void core_gpo::toggle(){
    wr_data ^= (uint32_t)(0xFFFFFFFF);
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
uint32_t core_gpi::read(){
    return REG_READ(base_addr, REG_DATA_OFFSET);
}

uint8_t core_gpi::read(uint32_t bit_pos){
    uint32_t rd_data = REG_READ(base_addr, REG_DATA_OFFSET);
    return (uint8_t)((rd_data >> bit_pos) & 0xFF);   
}