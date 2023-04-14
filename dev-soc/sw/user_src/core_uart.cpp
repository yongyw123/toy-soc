#include "core_uart.h"

core_uart::core_uart(uint32_t core_base_addr){
    /*
    @brief  : constructor to instantiate an object of class: core_uart;
    @param  : core_base_addr
                - the base address of the UART core resides
                    on the microblaze IO bus address;
    @retval : none
     */
    base_addr = core_base_addr;
    baud_rate = 9600;   // by default;
    
    // set the baud rate by default;
    set_baud_rate(baud_rate);
}

// destructor;
// not used;
core_uart::~core_uart() {}

void core_uart::set_baud_rate(uint32_t baud_rate){
    /*
    @brief  : set the baud rate for both UART Tx, Rx;
    @param  : baud_rate to be set (must be in integer)
    @retval : none
    */

    // update the private;
    baud_rate = baud_rate;

    // need to convert baud rate to the 
    // counter mod threshold within the baud rate generator;
    uint32_t conv;

    /*
    formula;

    assume oversampling takes 16 ticks;

    take;
    baud_rate, b;
    system freq, f;
    mod_threshold, t;

    t = f/(16*b)

    however, it is coded such that the count starts from
    zero and up to (mod threshold);
    so, there is an extra one;
    need to offset this; hence we have;

    t = f / (16*b) - 1;
    */ 

    conv = ((SYS_CLK_FREQ_HZ/(UART_OVERSAMPLING_NUM*baud_rate)) - 1);
    REG_WRITE(base_addr, REG_BAUD_OFFSET, conv);
}

uint32_t core_uart::check_rx_fifo_empty(void){
    /* 
    @brief  : check if there is any incoming uart data;
    @param  : none
    @retval : uint32_t binary (only the LSB of the retval)
        HIGH if there is data;
        LOW otherwise
    */
   uint32_t retval;
   retval = REG_READ(base_addr, REG_STATUS_OFFSET);
   return (uint32_t)((retval & MASK_STATUS_RX_EMPTY)>>S1_UART_REG_STATUS_BIT_POS_RX_EMPTY);
}

uint32_t core_uart::check_tx_fifo_full(void){
    /* 
    @brief  : check if there is any room to UART transmit;
    @param  : none
    @retval : uint32_t binary (only the LSB of the retval)
        HIGH if it is already full; no room;
        LOW otherwise
    */
   uint32_t retval;
   retval = REG_READ(base_addr, REG_STATUS_OFFSET);
   return (uint32_t)((retval & MASK_STATUS_TX_FULL)>>S1_UART_REG_STATUS_BIT_POS_TX_FULL);
}

int core_uart::tx_byte(uint8_t data){
    /*
    @brief  : UART transmit a byte;
    @param  : data (to transmit)
    @retval : 
            -2 if there is an error in transmitting;
            1 otherwise
    @note   : this is non-blocking; 
                user to check for the error;
    */
   
   // this will block the tx if there is no room to transmit;
   // flag it;
   if(check_tx_fifo_full()){
        return TX_FULL_ERROR;
   }
   REG_WRITE(base_addr, REG_TX_WRITE_RQ_OFFSET, (uint8_t) data);
   return TX_OK;
}

int core_uart::rx_byte(void){
    /*
    @brief  : to read from UART Rx;
    @param  : none
    @retval : 
            -1 if there is an error in reading from UART Rx;
            the actual data read otherwise;
    @note   : this is non-blocking; 
                user to check for the error;
    */

   // there is nothing to read if it is empty;
   if(check_rx_fifo_empty()){
        return RX_EMPTY_ERROR;
   }
   
   uint32_t retval;
   retval = (uint8_t)REG_READ(base_addr, REG_RX_READ_DATA_OFFSET);

   // move the uart fifo read pointer to the next slot;
   // this essentially removes the current read_data (retval);
   REG_WRITE(base_addr, REG_RX_READ_RQ_OFFSET, UART_DUMMY_VAL);
   
   // done
   // this is ok;
   // because uart supported data bit range will
   // not include 32-bit? if so, it is ok to give one
   // away for the signed bit;
   return (int)retval;
}



