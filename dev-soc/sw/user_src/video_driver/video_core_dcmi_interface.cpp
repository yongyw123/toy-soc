#include "video_core_dcmi_interface.h"
video_core_dcmi_interface::video_core_dcmi_interface(uint32_t core_base_addr){
	/*
	@brief  : constructor to instantiate an object of class: video_core_dcmi_interface()
	@param  : core_base_addr
				- the base address of this video core resides
					on the microblaze IO bus address;
	@retval : none
	 */

   base_addr = core_base_addr;

   // expect that the system (fifo) is already ready
   // by the time the board is booted up;
   system_ready_p = is_sys_ready();
   debug_str("dcmi system is failing ... \r\n!!!");   
   
   // future;
   // need to have a timeout mechanism;
   // and a way to reset the system if something goes wrong;
   // currently, there is a register to manually reset the fifo;
   // but not roboust;
   // also, may need to have an physical error indication;
   // such as flashing a LED?

   fifo_status_p = get_fifo_status();
   
   // by default; everything is disabled;
   ctrl_state_p = 0;

}

// destructor; not used;
video_core_dcmi_interface::~video_core_dcmi_interface(){};


int video_core_dcmi_interface::is_sys_ready(void){
    /*
    @brief  : check if the system is ready before enabling the decoder itself;
    @param  : none;
    @retval : integer codes:
            1 if OK
            0 otherwise
    */

   return (int)REG_READ(base_addr, REG_SYS_READY_STATUS_OFFSET);   
}


void video_core_dcmi_interface::set_decoder(int to_enable){
    /*
    @brief  : to enable or disable the decoder?
    @param  : to_enable
                1 to enable; 
                0 otherwise
    @retval : none;
    */

    // get the current setting;
   uint32_t get_curr;   
   get_curr = REG_READ(base_addr, REG_CTRL_OFFSET);

   // to avoid overwritting other setting in the same hw reg;
   get_curr &= ~MASK_CTRL_DEC_START;    // clear the bit;
   
   if(to_enable){
        get_curr |= MASK_CTRL_DEC_START;
   }

   // update the private var;
   ctrl_state_p = get_curr;

   // update the register;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, get_curr);
}

void video_core_dcmi_interface::enable_decoder(void){
    /*
    @brief  : to enable the decoder;
    @param  : none
    @retval : none;
    */

   set_decoder(ENABLE_DEC);   
   
}

void video_core_dcmi_interface::disable_decoder(void){
    /*
    @brief  : to disable the decoder;
    @param  : none
    @retval : none;
    */

   set_decoder(DISABLE_DEC);   
}

void video_core_dcmi_interface::clear_decoder_counter(void){
    /*
    @brief  : to clear the internal decoder frame counter;
    @param  : none
    @retval : none
    @note   : the internal frame counter will overflow and wrap around;
    */
   
   // get the current setting;
   uint32_t get_curr;   
   get_curr = REG_READ(base_addr, REG_CTRL_OFFSET);

   // to avoid overwritting other setting in the same hw reg;
   get_curr &= ~MASK_CTRL_FRAME_RST;    // clear the bit;
   
   // apply a pulse; otherwise, it will keep on clearing;
   // HIGH;
   get_curr |= MASK_CTRL_FRAME_RST;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, get_curr);

   // LOW;
   get_curr &= ~MASK_CTRL_FRAME_RST;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, get_curr);

    // update the private var;
    ctrl_state_p = get_curr;       
}


void video_core_dcmi_interface::reset_fifo(void){
    /*
    @brief  : to reset the fifo;
    @param  : none
    @retval : none
    @note   : this method will block until the fifo is reset successfully;
    */
   
   // get the current setting;
   uint32_t get_curr;   
   get_curr = REG_READ(base_addr, REG_CTRL_OFFSET);

   // to avoid overwritting other setting in the same hw reg;
   get_curr &= ~MASK_CTRL_FIFO_RST;    // clear the bit;
   
   // apply a pulse; otherwise, it will keep on resetting;
   // HIGH;
   get_curr |= MASK_CTRL_FIFO_RST;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, get_curr);

   // LOW;
   get_curr &= ~MASK_CTRL_FIFO_RST;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, get_curr);

    // update the private var;
    ctrl_state_p = get_curr;       
}


int video_core_dcmi_interface::detect_frame_start(void){
    /*
    @brief  : to see if the dcmi detects the start of a frame from the dcmi device;
    @param  : none
    @retval : integer code;
            1 if detected;
            0 otherwise
    */
   return (int) ((REG_READ(base_addr, REG_DECODER_STATUS_OFFSET) & MASK_DEC_STATUS_START) >> BIT_POS_DECODER_STATUS_START);
}

int video_core_dcmi_interface::detect_frame_start(void){
    /*
    @brief  : to see if the dcmi detects the start of a frame from the dcmi device;
    @param  : none
    @retval : integer code;
            1 if detected;
            0 otherwise
    */
   return (int) ((REG_READ(base_addr, REG_DECODER_STATUS_OFFSET) & MASK_DEC_STATUS_START) >> BIT_POS_DECODER_STATUS_START);
}