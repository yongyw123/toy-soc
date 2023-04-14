#ifndef _CORE_UART_H
#define _CORE_UART_H

/* ---------------------------------------------
Purpose: SW drivers for uart core;
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "inttypes.h"

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

class core_uart{
    // register map;
    enum{
        REG_STATUS_OFFSET = S1_UART_REG_STATUS_OFFSET, 
        REG_BAUD_OFFSET = S1_UART_REG_BAUD_OFFSET,   
        REG_TX_WRITE_RQ_OFFSET = S1_UART_REG_TX_WRITE_REQUEST_OFFSET,
        REG_RX_READ_RQ_OFFSET = S1_UART_REG_RX_READ_REQUEST_OFFSET,
        REG_RX_READ_DATA_OFFSET = S1_UART_REG_RX_READ_DATA_OFFSET
    };

    // masking for the status flag of the status register;
    enum{
        MASK_STATUS_RX_EMPTY = BIT_MASK(S1_UART_REG_STATUS_BIT_POS_RX_EMPTY),
        MASK_STATUS_TX_FULL = BIT_MASK(S1_UART_REG_STATUS_BIT_POS_TX_FULL)
    };
    
    // codes: returned value constants;
    enum{
        // reminder: need to use signed type to use these codes;
        TX_FULL_ERROR   = -2,
        TX_OK           = 1,
        RX_EMPTY_ERROR  = -1
    };

    // misc; 
    enum{
        // by uart standard; this should be fixed (?)
        UART_OVERSAMPLING_NUM = 16,
        
        // there is some operations that require a write;
        // e.g. read a UART Rx FIFO to move the read pointer;
        UART_DUMMY_VAL = 0xFFFF     
    };
    
    public:
        // general;
        core_uart(uint32_t core_base_addr);    // constructor
        ~core_uart(); // destructor;
        
        // setting;
        void set_baud_rate(uint32_t baud_rate); // set baud rate;
        
        // status
        uint32_t check_rx_fifo_empty(void);
        uint32_t check_tx_fifo_full(void);
        
        // rw
        int tx_byte(uint8_t data);
        int rx_byte(void);

        // print;
        void print_string(const char *str);
        void print(uint8_t raw);
        void print(const char *str);
        void print(int number, int base);
    
    private:
        uint32_t base_addr;
        uint32_t baud_rate;
};


#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_CORE_UART_H