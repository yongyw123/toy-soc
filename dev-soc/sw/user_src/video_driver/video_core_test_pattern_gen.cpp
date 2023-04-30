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
        placeholder = BIT_MASK(BIT_POS_WR);
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