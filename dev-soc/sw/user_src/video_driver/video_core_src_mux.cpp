#include "video_core_src_mux.h"

video_core_src_mux::video_core_src_mux(uint32_t core_base_addr){
    /*
	@brief  : constructor to instantiate an object of this class;
	@param  : core_base_addr
				- the base address of this video core resides
					on the microblaze IO bus address;
	@retval : none
	 */

    base_addr = core_base_addr;
    pselect = SEL_NONE;     // disable the pixel source by default;
    select_src(pselect);

}

// destructor;
video_core_src_mux::~video_core_src_mux(){};


void video_core_src_mux::select_src(int usr_select){
    /* 
    @brief      : select which pixel source to display to the LCD?
    @param      : usr_select; int type;
        1 for test pattern generator;
        2 for the camera;
        3 for nothing (disabled)        
    @retval     : none
    @assumption : param only takes this set: {1,2,3} and nothing else;
    */

   //update the private var;
   pselect = usr_select;
   // update the register;
   REG_WRITE(base_addr, REG_SEL_OFFSET, usr_select);
}

void video_core_src_mux::select_test(void){
    /* 
    @brief  : select the test pattern generator as the pixel source for 
                the lcd display;
    @param  : none
    @retval : none
    */
   select_src(SEL_TEST);
}

void video_core_src_mux::select_camera(void){
    /* 
    @brief  : select the camera as the pixel source for the lcd display;
    @param  : none
    @retval : none
    */
   select_src(SEL_CAM);
}

void video_core_src_mux::disable_pixel_src(void){
    /* 
    @brief  : disable any HW pixel source (generation) for the lcd display;
    @param  : none
    @retval : none
    */
   select_src(SEL_NONE);
}

int video_core_src_mux::read_curr_sel(void){
    /*
    @brief  : read the HW register to check which pixel source is selected;
    @param  : none
    @note   : this is for sanity check;
    @retval : the current selection:
        1 for test pattern generator;
        2 for the camera;
        3 for nothing (disabled)                    
    */

   return (int)REG_READ(base_addr, REG_SEL_OFFSET);
}