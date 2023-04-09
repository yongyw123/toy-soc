#ifndef _CORE_GPIO_H
#define _CORE_GPIO_H

/* ---------------------------------------------
Purpose: SW drivers for general purpose HW cores;
1. GPO for output;
2. GPI for input;
3. GPIO for inout;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif


/* --------------------------
core: general purpose output
----------------------------*/
class core_gpo{
    // register map;
    enum {
        REG_DATA_OFFSET = 0    // gpo core uses one register only;
    };

    public:
        core_gpo(uint32_t core_base_addr);  // constructor;
        ~core_gpo();                        // destructor;

        // overloaded method;
        void write(uint32_t data);                          // a word
        void write(uint32_t bit_pos, uint32_t bit_value);   // one bit;

    private:
        uint32_t base_addr;
        uint32_t wr_data;
};

/* --------------------------
core: general purpose input;
----------------------------*/
class core_gpi{
    enum {
        REG_DATA_OFFSET = 0    // gpo core uses one register only;
    };

    public:
        core_gpi(uint32_t core_base_addr);  // constructor;
        ~core_gpi();                        // destructor;

        // overloaded method;
        uint32_t read();                    // a word
        uint8_t read(uint32_t bit_pos);     // one bit;

    private:
        uint32_t base_addr;
};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_GPIO_H