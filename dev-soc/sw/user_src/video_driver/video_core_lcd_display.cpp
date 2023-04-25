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

