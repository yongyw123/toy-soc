#ifndef _CORE_I2C_MASTER_H
#define _CORE_I2C_MASTER_H


/* ---------------------------------------------
Purpose: SW drivers for I2C core;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"
#include "math.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

class core_i2c_master{
        // register map;
    enum{
        REG_READ_OFFSET   = S6_I2C_REG_READ_OFFSET,
        REG_CLKMOD_OFFSET =  S6_I2C_REG_CLKMOD_OFFSET,
        REG_WRITE_OFFSET = S6_I2C_REG_WRITE_OFFSET
    };

    // fields and maskings
    enum{
       BIT_POS_CMD_OFFSET =  S6_I2C_REG_WRITE_BIT_POS_CMD_OFFSET,
       BIT_POS_READ_ACK = S6_I2C_REG_READ_BIT_POS_ACK,
       BIT_POS_READ_READY = S6_I2C_REG_READ_BIT_POS_READY,
       
       MASK_READ_ACK = BIT_MASK(BIT_POS_READ_ACK),
       MASK_READ_READY = BIT_MASK(BIT_POS_READ_READY)

    };

    // i2c user commands;
    enum{
        /*
        // command constants;
        localparam CMD_NOP      = 3'b000;   // no operation;
        localparam CMD_START    = 3'b001;   // generate start condition;
        localparam CMD_WR       = 3'b010;   // master write to slave;
        localparam CMD_RD       = 3'b011;   // master reads from slave;
        localparam CMD_STOP     = 3'b100;   // generate stop condition;
        localparam CMD_REPEAT   = 3'b101;   // generate repeated_start condition;
        
        */
        CMD_NOP = ((uint32_t)0x00 << BIT_POS_CMD_OFFSET),
        CMD_START = ((uint32_t)0x01 << BIT_POS_CMD_OFFSET),
        CMD_WR = ((uint32_t)0x02 << BIT_POS_CMD_OFFSET),
        CMD_RD = ((uint32_t)0x03 << BIT_POS_CMD_OFFSET),
        CMD_STOP = ((uint32_t)0x04 << BIT_POS_CMD_OFFSET),
        CMD_REPEAT = ((uint32_t)0x05 << BIT_POS_CMD_OFFSET),
    };
    
    // protocol between the master and the slave ack/nack;
    // specs: https://web.eecs.umich.edu/~prabal/teaching/resources/eecs373/NXP-I2C-Specification.pdf
    enum{

        // used when master still wants to read more from the slave;
        MASTER_ACK_SLAVE = 0, 

        // used when master stops reading from the slave;
        MASTER_NACK_SLAVE = 1,

        // to process where the slave returns ack or not;
        SLAVE_ACK = 0,
        SLAVE_NACK = 1
        
    };

    // codes: returned value constants;
    enum{
        // i2c master controller is ready to accept user commands;
        STATUS_I2C_MASTER_READY = 1,        
        // slave does not return ack in master write op;
        STATUS_I2C_SLAVE_ACK_ERROR = -1,   

        // error in setting the frequency;
        // usually when the user-specified scl freq is such 
        // that 4*user_freq > system_clk_freq;
        STATUS_SET_FREQ_ERROR = -1,
        STATUS_SET_FREQ_OK = 1
    };
    
    public:
        core_i2c_master(uint32_t core_base_addr);
        ~core_i2c_master();

        // setting;
        int set_freq(int user_freq);

        // status;
        int check_ready(void);

        // basic commands;
        void send_start(void);          // send a start condition;
        void send_repeat_start(void);   // send a repeat start condition;
        void send_stop(void);           // send a stop condition;

        // rw;
        int write_byte(uint8_t data);   // master writes a byte to the slave;
        int read_byte(int terminate);   // master reads a byte from teh slave

        /*
        wrapper to start a complete transfer between
        the master and the slave;
        */ 
        int write_transfer(uint8_t dev, uint8_t *wr_buffer, int num, int restart);
        int read_transfer(uint8_t dev, uint8_t *rd_buffer, int num, int restart);


    private:
        // i2c core base address in the user address space;
        uint32_t base_addr;
        int scl_freq;       // scl rate;

};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_I2C_MASTER_H