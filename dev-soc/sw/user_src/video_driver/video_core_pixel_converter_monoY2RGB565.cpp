#include "video_core_pixel_converter_monoY2RGB565.h"


video_core_pixel_converter_monoY2RGB565::video_core_pixel_converter_monoY2RGB565(uint32_t core_base_addr){
    /*
    @brief  : constructor for this core: video_core_pixel_converter_monoY2RGB565;
    @param  : base address of the corresponding hw core;
    @retval : none
    */
   base_addr = core_base_addr;

   // by default; converter is disabled/bypassed;
   is_converter_enabled = 0;
   set_control(is_converter_enabled);

}

// destructor; not used;
video_core_pixel_converter_monoY2RGB565::~video_core_pixel_converter_monoY2RGB565(){}


int video_core_pixel_converter_monoY2RGB565::read_control(void){
    /*
    @brief  : read the current value of the HW register for sanity check;
    @param  : none;
    @retval : binary
            1: if the converter is enabled;
            0 otherwise
    */
   uint32_t rd_data;

   rd_data = REG_READ(base_addr, REG_CTRL_OFFSET);
   return (int)(rd_data & MASK_CTRL);

}
void video_core_pixel_converter_monoY2RGB565::set_control(int enable_converter){
    /*
    @brief  : enable or disable the pixel converter;
    @param  : enable_converter; HIGH to enable;
    @retval : none
    */

   uint32_t wr_data;

   // update the private var;
   is_converter_enabled = enable_converter;

    // read the current state to avoid overwritting;
    // even though, currently there is only one register with one bit control;
    // for good practice;
    wr_data = REG_READ(base_addr, REG_CTRL_OFFSET);
    wr_data &= ~MASK_CTRL;      // clear the control bit;    

   // set the control bit accordingly;
   if(enable_converter == ENABLE_PIXEL_CONVERTER){
        wr_data |= MASK_CTRL;
   }
   // update the register;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, wr_data);

}

void video_core_pixel_converter_monoY2RGB565::enable_converter(void){
    /*
    @brief  : to enable the pixel converter;
    @param  : none
    @retval : none 
    */
   set_control((int)ENABLE_PIXEL_CONVERTER);
}


void video_core_pixel_converter_monoY2RGB565::disable_converter(void){
    /*
    @brief  : to disable the pixel converter;
    @param  : none
    @retval : none 
    */
   set_control((int)DISABLE_PIXEL_CONVERTER);
}





