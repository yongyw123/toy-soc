#include "video_core_mig_interface.h"

/*
    
    Note on CPU communicating with the DDR2 via the MIG interface;
    1. the underlying DDR2 transaction is 128-bit;
    2. but CPU register is only 32-bit wide;
    3. so, preparations are needed;

    for write operation;
    1. setup the address;
    2. push 32-bit write data four times via Register 4 to 7;
    3. submit the write request;

    for read operation;
    1. setup the address;
    2. submit the read request;
    3. wait for transaction to complete;
    4. shift in the 128-bit data vua Register 8 to 11;
    
*/

video_core_mig_interface::video_core_mig_interface(uint32_t core_base_addr){
    /*
    @brief  : constructor for this core: video_core_mig_interface;
    @param  : base address of the corresponding hw core;
    @retval : none
    */
   base_addr = core_base_addr;

   // by default; cpu as the control;
   curr_source = REG_SEL_CPU;
   set_source(curr_source);

}

// destructor; not used;
video_core_mig_interface::~video_core_mig_interface(){}


void video_core_mig_interface::set_source(int source){
    /* 
    @brief  : to set which source to interface with the DDR2;
    @param  : int source
                1. none                     : REG_SEL_NONE
                2. CPU                      : REG_SEL_CPU
                3. Motion Detection Core    : V5_MIG_INTERFACE_REG_SEL_MOTION
                4. HW test                  : V5_MIG_INTERFACE_REG_SEL_TEST
    @retval : none            
    */

    uint32_t wr_data = (uint32_t)source;
    REG_WRITE(base_addr, REG_SEL_OFFSET, wr_data);       

    // update the private var;
    curr_source = source;
}

void video_core_mig_interface::set_none(void){
    /*
    @brief  : to set the DDR2 to interface with nothing;
    @param  : none;
    @retval : none;
    */
   set_source(REG_SEL_NONE);
}

void video_core_mig_interface::set_core_cpu(void){
    /*
    @brief  : to set the DDR2 to interface with the CPU;
    @param  : none;
    @retval : none;
    */
   set_source(REG_SEL_CPU);
}

void video_core_mig_interface::set_core_test(void){
    /*
    @brief  : to set the DDR2 to interface with the HW test;
    @param  : none;
    @retval : none;
    */
   set_source(REG_SEL_TEST);
}

void video_core_mig_interface::set_core_motion(void){
    /*
    @brief  : to set the DDR2 to interface with the motion detection core;
    @param  : none;
    @retval : none;
    */
   set_source(REG_SEL_MOTION);
}

uint32_t video_core_mig_interface::get_status(void){
    /* 
    @brief  : to retrieve the HW status register;
    @param  : none;
    @retval : 32-bit status register data; 
    */
   return (uint32_t)REG_READ(base_addr, REG_STATUS_OFFSET);
   
}

int video_core_mig_interface::is_mig_init_complete(void){
    /*
    @brief  : to retrieve the status of the MIG calibration completion status;
    @param  : none;
    @retval : 1 if completed; 0 otherwise;
    */

   uint32_t rd;
   rd = get_status();
   return (int)(rd & REG_STATUS_MIG_INIT_MASK);
}

int video_core_mig_interface::is_mig_app_ready(void){
    /*
    @brief  : to retrieve the readiness state of the MIG;
    @param  : none;
    @retval : 1 if ready; 0 otherwise;
    */

   uint32_t rd;
   rd = get_status();
   return (int)(rd & REG_STATUS_MIG_RDY_MASK);
}

int video_core_mig_interface::is_transaction_complete(void){
    /*
    @brief  : to check if the submitted read/write transaction is completed;    
    @param  : none;
    @retval : 1 if completed; 0 otherwise;
    @note   : this flag clears itself; this flag only lasts for one system clock period; 
    @note   : for write operation, this flag indicates that the write request has been accepted
                and acknowledged by the MIG controller; it does not imply that the write data
                has been written to the DDR2;
    @note   : for read operation, the assertion of this flag indicates that the read request
                has been accepted + acknowledged AND the data on the read bus is valid to read off;                
    */
   uint32_t rd;
   rd = get_status();
   return (int)(rd & REG_STATUS_OP_COMPLETE_MASK);
}

int video_core_mig_interface::is_mig_ctrl_idle(void){
    /*
    @brief  : to retrieve the state of the MIG controller;
    @param  : none;
    @retval : 1 if idle; 0 otherwise;
    */

   uint32_t rd;
   rd = get_status();
   return (int)(rd & REG_STATUS_CTRL_IDLE_MASK);
}

void video_core_mig_interface::set_addr(uint32_t addr){
    /*
    @brief  : set up the address for writing/reading to/from the DDR2;
    @param  : address;
    @retval : none;
    @note   : underlying DDR2 MIG address is 23 bit;    
    */

   REG_WRITE(base_addr, REG_ADDR_OFFSET, addr);
}

void video_core_mig_interface::submit_write(void){
    /* 
    @brief  : to submit a write request;
    @param  : none
    @retval : none
    @note   : user needs to ensure data and address line are already set up;        
    */

   uint32_t wr_data = (uint32_t)REG_CTRL_MASK_WRSTROBE;   
   REG_WRITE(base_addr, REG_CTRL_OFFSET, wr_data);

   // need to disable after one clock cycle; otherwise; it will keep 
   // on writing;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, (uint32_t) 0x00);
}

void video_core_mig_interface::submit_read(void){
    /* 
    @brief  : to submit a read request;
    @param  : none
    @retval : none
    @note   : user needs to ensure the address line is already set up;        
    */

   uint32_t wr_data = (uint32_t)REG_CTRL_MASK_RDSTROBE;   
   REG_WRITE(base_addr, REG_CTRL_OFFSET, wr_data);

   // need to disable after one clock cycle; otherwise; it will keep 
   // on reading;
   REG_WRITE(base_addr, REG_CTRL_OFFSET, (uint32_t) 0x00);
}

void video_core_mig_interface::push_wrdata_01(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[31:0];
    @param  : write data;
    @retval : none;    
    */
   REG_WRITE(base_addr, REG_WRDATA_01_OFFSET, wrdata);
}

void video_core_mig_interface::push_wrdata_02(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[63:32];
    @param  : write data;
    @retval : none;    
    */
   REG_WRITE(base_addr, REG_WRDATA_02_OFFSET, wrdata);
}

void video_core_mig_interface::push_wrdata_03(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[95:64];
    @param  : write data;
    @retval : none;    
    */
   REG_WRITE(base_addr, REG_WRDATA_03_OFFSET, wrdata);
}


void video_core_mig_interface::push_wrdata_04(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[127:96];
    @param  : write data;
    @retval : none;    
    */
   REG_WRITE(base_addr, REG_WRDATA_04_OFFSET, wrdata);
}


uint32_t video_core_mig_interface::get_rddata_01(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[31:0];
    @param  : none;
    @retval : 32-bit read data;
    */
   REG_READ(base_addr, REG_RDDATA_01_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_02(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[63:32];
    @param  : none;
    @retval : 32-bit read data;
    */
   REG_READ(base_addr, REG_RDDATA_02_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_03(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[95:64];
    @param  : none;
    @retval : 32-bit read data;
    */
   REG_READ(base_addr, REG_RDDATA_03_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_04(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[127:96];
    @param  : none;
    @retval : 32-bit read data;
    */
   REG_READ(base_addr, REG_RDDATA_04_OFFSET);
}