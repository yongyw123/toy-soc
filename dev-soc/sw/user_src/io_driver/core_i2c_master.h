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

    // masking 
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
    
    // codes: returned value constants;
    enum{
        STATUS_I2C_MASTER_READY = 1,
        STATUS_I2C_SLAVE_ACK_ERROR = -1     // slave does not return ack;
    };
    

    




    


};



#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_I2C_MASTER_H