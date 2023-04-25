#include "video_core_lcd_display.h"

video_core_lcd_display::video_core_lcd_display(uint32_t core_base_addr){
    /*
    @brief  : constructor to instantiate an object of class: video_core_lcd_display()
    @param  : core_base_addr
                - the base address of this video core resides
                    on the microblaze IO bus address;
    @retval : none
     */

   base_addr = core_base_addr;

   /* wrx, rdx timing;
   read the lcd specs;

   brief definition;
   the host updates its data to send at high-to-low of WRX;
   the lcd samples this data at the low-to-high of WRX;
   this defines two periods;
   low period;
   high period;

   low period: how long should the WRX spend in this low period;
   high period: how long should the WRX spend in this high period;
   
   the data also has to hold until the high period;

   for rdx; it is similar;
   
   */
  
   wrx_l = 1;   // this corresponds to 20 ns;
   wrx_h = 1;   // this corresponds to 30 ns (including the done flag);
   
   // read is usually longer;
   rdx_l = 9;   // 100 ns;
   rdx_h = 39;  // 400 ns;

   set_clockmod(wrx_l, wrx_h, rdx_l, rdx_h);

}

// destructor; not used;
video_core_lcd_display::~video_core_lcd_display(){};

void video_core_lcd_display::set_clockmod(int usr_wrx_l, int usr_wrx_h, int usr_rdx_l, int usr_rdx_h){
    /*
    @brief  : setting the WRX and RDX period by setting the respective counter modulus;
    @param  :
        user_wrx_l  : how long should the WRX be LOW;
        user_wrx_h  : how long should the WRX be HIGH;
        user_rdx_l  : how long should the RDX be LOW;
        user_rdx_h  : how long should the RDX be HIGH;
    @retval : none
    */


   uint32_t set_wrx;
   uint32_t set_rdx;

    set_wrx = (uint32_t)(usr_wrx_l | ((uint32_t)usr_wrx_h << BIT_POS_REG_CLKMOD_SHALF));
    set_rdx = (uint32_t)(usr_rdx_l | ((uint32_t)usr_rdx_h << BIT_POS_REG_CLKMOD_SHALF));

    // write them into the registers;
    REG_WRITE(base_addr, REG_CLOCKMOD_WR_OFFSET , set_wrx);
    REG_WRITE(base_addr, REG_CLOCKMOD_RD_OFFSET , set_rdx);

}

void video_core_lcd_display::set_stream(int set_cpu_control){
    /*
    @brief  : to set the stream control;
    @note   : this means that which system is driving the lcd interface?
                the cpu (processor) 
                or other video cores (such as pixel generation)
    @param  : set_cpu_control 
                1: cpu takes over;
                0: otherwise;
    @retval : none
    */
   
   // unfortunately; the HW register uses the other way around;
   // low for cpu control;
   uint32_t wr = (uint32_t)(0x01);  // non-cpu control;
   if(set_cpu_control){
    wr = (uint32_t)0x00;
   }

   // update the register;
   REG_WRITE(base_addr, REG_STREAM_CTRL_OFFSET, wr);
}

int video_core_lcd_display::is_ready(void){
    /*
    @brief  : check whether the lcd display controller is ready/idle;
    @param  : none;
    @retval : 1 if ready; 0 otherwise;
    */

   uint32_t rd_data;
   rd_data = REG_READ(base_addr, REG_RD_DATA_OFFSET);
   return (int)((rd_data & MASK_REG_RD_DATA_STATUS_READY) >> BIT_POS_REG_RD_DATA_STATUS_READY);
}


void video_core_lcd_display::enable_chip(void){
    /*
    @brief  : assert CS (active low) to enable the LCD;
    @param  : none;
    @retval : none
    */
    uint32_t wr = (uint32_t)0x01;
   REG_WRITE(base_addr, REG_CSX_OFFSET, wr);

}

void video_core_lcd_display::disable_chip(void){
    /*
    @brief  : deassert the CS (active low) to the disable the LCD chip
    @param  : none;
    @retval : none
    */

   uint32_t wr = (uint32_t)0x00;
   REG_WRITE(base_addr, REG_CSX_OFFSET, wr);

}

void video_core_lcd_display::write(int is_data, uint8_t data){
    /*
    @brief  : Host transfers to the LCD
    @param  :
            is_data: how should the LCD interpret the host data?
                    1 for data;
                    0 for command
            data    : the data to transfer
    @retval : none
    @note   : this is a blocking method;
    */

   /*
   write register structure;
    bit[7:0]    : data to write to the lcd;
    bit[8]      : is the data to write a DATA or a COMMAND for the LCD?
                    0 for data;
                    1 for command;
    bit[10:9]  : to store user commands;

   */
    int hw_dcx; // different polarity with how the HW register is defined;

    uint32_t wr;

    if(is_data){
        hw_dcx = 0;
    }else{
        hw_dcx = 1;
    }

    uint32_t dcx = ((uint32_t)hw_dcx << BIT_POS_REG_WR_DATA_DCX);
    wr = (uint32_t)(dcx | CMD_WR | (uint32_t)data);

    // block until the lcd interface controller is ready;
    while(!is_ready()){};

    // update the register;
    REG_WRITE(base_addr, REG_WR_DATA_OFFSET, wr);

    // due to limitation;
    // need to issue a NOP command after a clock cyle;
    // otherwise, the controller will keep on writing;
    // careful not to override other setting;
    wr = (uint32_t)(CMD_NOP | dcx | (uint32_t)data);
    REG_WRITE(base_addr, REG_WR_DATA_OFFSET, wr);
    
}


uint8_t video_core_lcd_display::read(void){
    /* 
    @brief  : read a byte from the lcd;
    @param  : none;
    @retval : none;
    @note   : this is a blocking method;
    */

    /*
   write register structure;
    bit[7:0]    : data to write to the lcd;
    bit[8]      : is the data to write a DATA or a COMMAND for the LCD?
                    0 for data;
                    1 for command;
    bit[10:9]  : to store user commands;

   */

    // signal declaration;
    uint32_t req_rd;    // for issuing a read request;
    uint32_t rd_data;   // after reading from the lcd;

    // issue a read command;
    uint32_t dcx = ((uint32_t)0x00 << BIT_POS_REG_WR_DATA_DCX);
    uint32_t dummy_data = (uint32_t)0x00;
    req_rd = (uint32_t)(CMD_RD | dcx | dummy_data);

    // update the reg;
    REG_WRITE(base_addr, REG_WR_DATA_OFFSET, req_rd);

    // due to limitation;
    // need to issue a NOP command after a clock cyle;
    // otherwise, the controller will keep on 
    // signalling to the lcd that it wants to read;
    // careful not to override other setting;
    req_rd = (uint32_t)(CMD_NOP | dcx | dummy_data);
    REG_WRITE(base_addr, REG_WR_DATA_OFFSET, req_rd);

    // block until the lcd is ready;
    while(!is_ready()){};

    // read;
    rd_data = REG_READ(base_addr, REG_RD_DATA_OFFSET);
    return (uint8_t)(rd_data & 0xFF);

}


