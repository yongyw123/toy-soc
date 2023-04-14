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

void core_uart::print(uint8_t raw){
    /*
    @brief  : to transmit the input as it is;
    @param  : raw byte to transmit;
    @retval : none
    */
    
    // block until uart tx fifo to free up;
    while(check_tx_fifo_full()){}

    tx_byte(raw);

}

void core_uart::print_string(const char *str){
    /*
    @brief  : to print a string;
    @param  : str, pointer to the string;
    @retval : none
    */

   // require explicit cast since uart uses byte;
   uint8_t *ptr = (uint8_t *)str;

   // keep printing until the null terminator is hit;
   while(*ptr){
        // block until uart tx fifo to free up;
        while(check_tx_fifo_full()){}

        tx_byte(*ptr);

        // next byte;
        ptr++;
   }
}

void core_uart::print(const char *str){
    /*
    @brief  : this duplicates print_string();
    @param  : str, pointer to the string;
    @retval : none
    */

   print_string(str);
}


void core_uart::print(int number, int base){
    /*
    @brief  : to print a (signed) decimal as ASCII string;
    @param  :
        number  : number to print;
        base    : the base of the number: dec, octal or hex?
    @support    : supported base: {binary, octal, decimal, hexadecimal}
    @retval : none
    */

   uint8_t buffer[33];  // include the null terminator;
   uint8_t *ptr;        // pointer to store the converted number in ascii;
   uint8_t sign_ch;        // to indicate negative;
   uint8_t temp_ch;     // to hold converted ascii;


   uint8_t remainder;   // to determine the base; modulo;
   uint8_t quotient;    // for base conversion;
   uint8_t index;       // string index for tracking;
   
    // check;
    if(base != 2 && base != 8 && base != 16){
        base = 10;
    }
    
    // check negative;
    // negative only "make sense" in decimal;
    if(base == 10 && (number < 0)){
        // absolute value def;
        quotient = (unsigned)(-number);
        sign_ch = '-';
    }else{
        quotient = (unsigned)number;
        sign_ch = ' ';
    }

    // string conversion;
    // start from the end for convenience;
    ptr = &buffer[33];
    *ptr = '\0';
    index = 0;
    
    // base conversion;
    // standard formula:
    // conversion step;
    // divide the number by the base;
    // get the integer quotient for the next iteration;
    // the remainder is the current converted "digit" for print;
    // repeat until the integer quotient is zero;
    while(1){
        // to store the current converted digit;
        ptr--;
        
        remainder = quotient % base;
        quotient = quotient / base;
        
        /* ascii caution;
        need to consider
        if the current digit (remainder)
        is above 10 or not;
        
        e.g. 
        consider "10".
        "10" is represented by two ascii characters;
        
        */
        if(remainder < 10){
            // only one digit;
            // check the ascii table;
            // start offset is zero;
            temp_ch = (uint8_t)(remainder + '0');     
        }
        // more than one digits;
        else{
            // 
        }

        // update;
        *ptr = temp_ch;
        index++;

        // to break if base conversion is complete;
        if(quotient <= 0){
            break;
        }

    }

    // sign;
    
    if(sign_ch == '-'){
        ptr--;
        *ptr = sign_ch;
        index++;
    }
    // done;
    print_string((const char *)ptr);
}