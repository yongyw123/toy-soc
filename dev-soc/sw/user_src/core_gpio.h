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
        
        void write(uint32_t data);                          // write a word
        void write(uint32_t bit_pos, uint32_t bit_value);   // write one bit;

        // for convenience;
        void toggle(void);                  // toggle the entire word;
        void toggle(uint32_t bit_pos);  // toggle a bit;

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

        uint32_t read(void);                    // read a word
        uint8_t read(uint32_t bit_pos);     // read one bit;

    private:
        uint32_t base_addr;
};


/* -------------------------------------------------
core: general purpose input and output;

* Register Map;
* 1. three registers;
* 2. offset 0: register 0 - write_data 
* 3. offset 1: register 1 - read_data  
* 4. offset 2: register 2 - control register 
*               to set the direction of the port;
* Control Register:       
    HIGH for output direction;
    LOW for input directionl
*
* Register Access:
*   1. register 0 - write only;
*   2. register 1 - read only;
*   3. register 2 - write and read;
* 
---------------------------------------------------*/
class core_gpio{
    enum {
        REG_WRITE_DATA_OFFSET = 0,  
        REG_READ_DATA_OFFSET = 1,
        REG_CTRL_DIR_OFFSET = 2
    };

    enum{
        CTRL_DIRECTION_WRITE = 1,   // HIGH to set output direction;
        CTRL_DIRECTION_READ = 0
    }; 

    public:
        core_gpio(uint32_t core_base_addr); // constructor;
        ~core_gpio();  // destructor;

        void set_direction(uint32_t which_port, uint32_t direction);        // set direction
        uint32_t read(uint32_t which_port);             // read 
        void write(uint32_t which_port, uint32_t data); // write 
        uint32_t read_ctrl_reg(void);       // read the ctrl register;


        // access the enum constants and private var;
        int get_ctrl_dir_write(void);   
        int get_ctrl_dir_read(void);
        
        // for debugging; to compare against read_ctrl_reg();
        uint32_t debug_get_dir(void);   

    private:
        uint32_t base_addr;
        uint32_t wr_data;
        uint32_t direction_data;
};


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_GPIO_H