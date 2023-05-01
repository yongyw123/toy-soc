#include "video_core_test_pattern_gen.h"

video_core_test_pattern_gen::video_core_test_pattern_gen(uint32_t core_base_addr){
    /*
	@brief  : constructor to instantiate an object of this class;
	@param  : core_base_addr
				- the base address of this video core resides
					on the microblaze IO bus address;
	@retval : none
	 */

    base_addr = core_base_addr;
    pcurr_state = DISABLE_TEST_PATTERN; // disabled by default;     
    set_state(pcurr_state);
}

// destructor;
video_core_test_pattern_gen::~video_core_test_pattern_gen(){};

void video_core_test_pattern_gen::set_state(int usr_sw){
    /*
    @brief  : to enable or disable the test pattern generator?
    @param  : binary
            HIGH to enable
            LOW otherwise
    @retval : none
    */

   uint32_t placeholder = 0x00;
   if(usr_sw){
        placeholder = BIT_MASK(REG_WR_BIT_POS_WR);
   }

   // update the private var;
   pcurr_state = usr_sw;
   REG_WRITE(base_addr, REG_WR_OFFSET, placeholder);

}

void video_core_test_pattern_gen::enable(void){
    /*
    @brief  : enable the test pattern generator;
    @param  : none
    @retval : none
    */
   set_state(ENABLE_TEST_PATTERN);

}

void video_core_test_pattern_gen::disable(void){
    /*
    @brief  : disable the test pattern generator;
    @param  : none
    @retval : none
    */
   set_state(DISABLE_TEST_PATTERN);
}

int video_core_test_pattern_gen::get_state(void){
    /*
    @brief  : read the HW register to check
            whether the generator is ON or not;
    @param  : none
    @note   : this is for sanity check;
    @retval : integer indicator
        HIGH if on;
        LOW otherwise;
    */

   return (int)REG_READ(base_addr, REG_WR_OFFSET);
}

int video_core_test_pattern_gen::get_frame_status(void){
    /*
    @brief  : get the current status of the frame generation;
    @param  : none
    @retval : codes
        -1  if the frame generation is ongoing (busy);
        0   if the frame generation is idle (at the start);
        1   if the frame generation is complete;
    @note   :        
    */

   uint32_t rd_data;
   int status;
   rd_data = REG_READ(base_addr, REG_STATUS_OFFSET);
   
   // check for completion;
   status = (int)(rd_data & MASK_STATUS_FRAME_END);
   if(status == 1){
        return STATUS_FRAME_COMPLETE;
   }

   // check for busy or idle?
   status = (int)(rd_data & MASK_STATUS_FRAME_START);
   if(status == 1){
        return STATUS_FRAME_IDLE;
   }else{
    return STATUS_FRAME_BUSY; 
   }
}

int video_core_test_pattern_gen::is_frame_idle(void){
    /*
    @brief  : is the frame generation idle?
    @param  : none
    @retval : binary; HIGH if idle; LOW otherwise;
    */
    int status;
    status = get_frame_status();
    if(status != STATUS_FRAME_IDLE){
        return 0;
    }else{
        return 1;
    }
}

int video_core_test_pattern_gen::is_frame_complete(void){
    /*
    @brief  : is the frame generation idle?
    @param  : none
    @retval : binary; HIGH if completed; LOW otherwise;
    */
    int status;
    status = get_frame_status();
    if(status != STATUS_FRAME_COMPLETE){
        return 0;
    }else{
        return 1;
    }
}