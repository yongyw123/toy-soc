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

void video_core_mig_interface::set_core_none(void){
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
   return (int)((rd & REG_STATUS_MIG_INIT_MASK) >> REG_STATUS_BIT_POS_MIG_INIT);
}

int video_core_mig_interface::is_mig_app_ready(void){
    /*
    @brief  : to retrieve the readiness state of the MIG;
    @param  : none;
    @retval : 1 if ready; 0 otherwise;
    */

   uint32_t rd;
   rd = get_status();
   return (int)((rd & REG_STATUS_MIG_RDY_MASK) >> REG_STATUS_BIT_POS_MIG_RDY);
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
   return (int)((rd & REG_STATUS_OP_COMPLETE_MASK) >> REG_STATUS_BIT_POS_OP_COMPLETE);
}

int video_core_mig_interface::is_mig_ctrl_idle(void){
    /*
    @brief  : to retrieve the state of the MIG controller;
    @param  : none;
    @retval : 1 if idle; 0 otherwise;
    */

   uint32_t rd;
   rd = get_status();
   return (int)((rd & REG_STATUS_CTRL_IDLE_MASK) >> REG_STATUS_BIT_POS_CTRL_IDLE);
}

void video_core_mig_interface::set_addr(uint32_t addr){
    /*
    @brief  : set up the address for writing/reading to/from the DDR2;
    @param  : address;
    @retval : none;
    @note   : underlying DDR2 MIG address is 23 bit;    
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */

   REG_WRITE(base_addr, REG_ADDR_OFFSET, addr);
}

void video_core_mig_interface::submit_write(void){
    /* 
    @brief  : to submit a write request;
    @param  : none
    @retval : none
    @note   : user needs to ensure data and address line are already set up;        
    @note   : this is a blocking method;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */

   // block until  the mig is ready to accept a new request;
   while(!is_mig_app_ready()){};   

   uint32_t wr_data = (uint32_t)REG_CTRL_MASK_WRSTROBE;   
   REG_WRITE(base_addr, REG_CTRL_OFFSET, wr_data);

   /*-------------------------------------------------------------
   * ??? LIMITATION ???
   * need to ensure the wrstrobe is two system clock periods wide;
   * this is due to the HW synchronization issue;
   --------------------------------------------------------------*/
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
    @note   : this is a blocking method;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */

   // block until  the mig is ready to accept a new request;
   while(!is_mig_app_ready()){};

   uint32_t wr_data = (uint32_t)REG_CTRL_MASK_RDSTROBE;   
   REG_WRITE(base_addr, REG_CTRL_OFFSET, wr_data);

    /*-------------------------------------------------------------
   * ??? LIMITATION ???
   * need to ensure the rdstrobe is two system clock periods wide;
   * this is due to the HW synchronization issue;
   --------------------------------------------------------------*/
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
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   REG_WRITE(base_addr, REG_WRDATA_01_OFFSET, wrdata);
}

void video_core_mig_interface::push_wrdata_02(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[63:32];
    @param  : write data;
    @retval : none;    
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   REG_WRITE(base_addr, REG_WRDATA_02_OFFSET, wrdata);
}

void video_core_mig_interface::push_wrdata_03(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[95:64];
    @param  : write data;
    @retval : none;    
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   REG_WRITE(base_addr, REG_WRDATA_03_OFFSET, wrdata);
}


void video_core_mig_interface::push_wrdata_04(uint32_t wrdata){
    /*
    @brief  : to push a 32-bit data into the DDR2 128-bit wr_data[127:96];
    @param  : write data;
    @retval : none;    
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   REG_WRITE(base_addr, REG_WRDATA_04_OFFSET, wrdata);
}


uint32_t video_core_mig_interface::get_rddata_01(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[31:0];
    @param  : none;
    @retval : 32-bit read data;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   return REG_READ(base_addr, REG_RDDATA_01_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_02(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[63:32];
    @param  : none;
    @retval : 32-bit read data;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   return REG_READ(base_addr, REG_RDDATA_02_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_03(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[95:64];
    @param  : none;
    @retval : 32-bit read data;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   return REG_READ(base_addr, REG_RDDATA_03_OFFSET);
}

uint32_t video_core_mig_interface::get_rddata_04(void){
    /*
    @brief  : to read off the 32-bit of the DDR2 128-bit data at addr[127:96];
    @param  : none;
    @retval : 32-bit read data;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   return REG_READ(base_addr, REG_RDDATA_04_OFFSET);
}

void video_core_mig_interface::write_ddr2(uint32_t addr, uint32_t wrbatch01, uint32_t wrbatch02, uint32_t wrbatch03, uint32_t wrbatch04){
    /*
    @brief  : to write to the DDR2;
    @param  :
           1. addr      : the address to write to;
           2. wrbatch01 : forms the DDR2 128-bit wr data[31:0];
           3. wrbatch02 : forms the DDR2 128-bit wr data[63:32];
           4. wrbatch03 : forms the DDR2 128-bit wr data[95:64];
           5. wrbatch04 : forms the DDR2 128-bit wr data[127:96];
    @retval : none
    @note   : This is a blocking method; waiting for the MIG to acknowledge.
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
    
    // one needs to setup the address and data before submitting the write request;
    set_addr(addr);
    push_wrdata_01(wrbatch01);
    push_wrdata_02(wrbatch02);
    push_wrdata_03(wrbatch03);
    push_wrdata_04(wrbatch04);

    // submit;
    submit_write();

    //debug_str("waiting for transaction to complete.\r\n");
    // block until the MIG has accepted and acknowledged the write request;
    //while(!is_transaction_complete()){};
    //debug_str("write transaction is complete.\r\n");
}

void video_core_mig_interface::read_ddr2(uint32_t addr, uint32_t *read_buffer){
    /*
    @brief  : to get the data read from the DDR2;
    @param  : 
        1. address to read from;
        2. pointer to an array to store the data read;
    @retval : none;
    @note   : this is a blocking method;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */
   
   // prepare the address;
   set_addr(addr);
   
   // submit the read request;
   submit_read();
   
   // debugging 
   delay_busy_ms(1000);

   //debug_str("waiting for read transaction to complete.\r\n");
   // block until the MIG says the data is valid to read;
   //while(!is_transaction_complete()){};
   //debug_str("read transaction is complete.\r\n");

   // data is valid to ready;
   // store it to the pointed array;
   // there are four batches to read to make the entire 128-bit DDR2 transaction;
    *(read_buffer + 0) = get_rddata_01();
    *(read_buffer + 1) = get_rddata_02();
    *(read_buffer + 2) = get_rddata_03();
    *(read_buffer + 3) = get_rddata_04();   
}

void video_core_mig_interface::init_ddr2(uint32_t init_value, uint32_t start_addr, uint32_t range_addr){
    /*
    @brief  : to initialize the DDR2 with common initial value;
    @param  :
        1. init_value   : the value to populate the DDR2;
        2. start_addr   : start address of the DDR2 to write to;
        3. range_addr   : the address range of the DDR2 to write to;
    @retval : none    
    @note   : each address represents a 128-bit transaction;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */

   uint32_t i;  // loop index;
   for(i = 0; i < range_addr; i++){
        write_ddr2((start_addr + i), init_value, init_value, init_value, init_value);
   }        
}

void video_core_mig_interface::check_init_ddr2(uint32_t init_value, uint32_t start_addr, uint32_t range_addr){
    /*
    @brief  : sanity check of init_ddr2();    
    @param  :
        1. init_value   : the expected value written to the DDR2 to check against;
        2. start_addr   : start address of the DDR2 to read from ;
        3. range_addr   : the address range of the DDR2 to read from;
    @retval : none;
    @assumption : CPU is controlling the MIG interface (set it apriori);
    */

   uint32_t i; // loop index;
   uint32_t read_buffer[4]; // buffer to store the entire "128-bit" DDR2 data;
   uint32_t read_data;
   uint32_t address;
   uint32_t check_status = 0;
   debug_str("Checking DDR2 initialization ... \r\n");
   for(i = 0; i < range_addr; i++){
        address = (start_addr + i);
        read_ddr2(address, read_buffer);
        // iterate each 32-bit read data and check against the expected val;
        for(int j = 0; j < 4; j++){
            read_data = read_buffer[i];
            if(read_data != init_value){
                debug_str("Address: ");
                debug_hex(address);
                debug_str("; Status: NOT OK; Actual Read Data: ");                                                
                debug_hex(read_data);
                debug_str("\r\n");
            }
            else{
                debug_str("Address: ");
                debug_hex(address);
                debug_str("; Status: OK\r\n");
                check_status++;
            }
        }
   }
   debug_str("Done checking DDR2 initialization ... \r\n");
   if(check_status == (range_addr-1)){
        debug_str("Result: OK\r\n");
   }else{
        debug_str("Result: NOT OK\r\n");
   }
}