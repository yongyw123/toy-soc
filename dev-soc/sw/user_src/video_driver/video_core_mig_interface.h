#ifndef _VIDEO_CORE_MIG_INTERFACE_H
#define _VIDEO_CORE_MIG_INTERFACE_H


/* ---------------------------------------------
Purpose: SW drivers for the following HW video core;
Core: core_video_mig_interface
---------------------------------------------*/

#include "io_map.h"
#include "io_reg_util.h"
#include "user_util.h"



// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif



/*****************************************************************
V5_MIG_INTERFACE
-----------------
Purpose: to select which source to interface with the DDR2 SDRAM via MIG;
It is either interfacing with:
1. CPU;
2. other video core: motion detection?
3. a HW testing circuit;

Construction:
1. DDR2 read/write transaction is 128-bit.
2. So this complicates stuffs since ublaze register is 32-bit wide only;
3. to facilitate the read/write operation, we use multiple registers;

3.1 note that each address (bit) covers one 128-bit;

4. For write:
    1. we shall have multiple write control register bits:
    2. before submitting write request, we need to shift in the ublaze 32-bit into 128-bit;
    3. each bit is to push a 32-bit from ublaze to the 128-bit DDR2 register;
    4. some bits to setup the write address;
    5. one bit to submit the write request;

5. For read;
    1. similarly, we need multiple read control register bits;
    2. after submitting the read request along with the read address, we check and wait for transaction complete status;
    3. this completion status indicates the data on the bus is ready to be read;
    4. it takes "4 times" to shift in the 128-bit into four registers of 32-bit each;
      

-----
Register Map
1. Register 0 (Offset 0): select register;
2. Register 1 (Offset 1): status register;
3. Register 2 (Offset 2): address, common for read and write;
3. Register 3 (Offset 3): write control register;
4. Register 4 (Offset 4): read control register;
5. Register 5 (Offset 5): read data batch 01;
6. Register 6 (Offset 6): read data batch 02;
7. Register 7 (Offset 7): read data batch 03;
8. Register 8 (Offset 8): read data batch 04;

Register Definition:
1. Register 0 (Offset 0): select register;
    bit[2:0] for multiplexing
        3'b000: NONE
        3'b001: CPU
        3'b010: Motion Detection Core
        3'b100: HW Testing Circuit;
        
2. Register 1 (Offset 1): Status Register
        bit[0]: MIG DDR2 initialization complete status; active high;
        bit[1]: MIG DDR2 app ready status (implies init complete status); active high;
        bit[2]: transaction completion status, 
                common for both read and write; 
                once asserted, it will remain as it is until new write/read strobe is requested;                
        bit[3]: MIG controller idle status; active high;
            
3. Register 2 (Offset 2): address common for read and write;
        bit[22:0] address;

4. Register 3 (Offset 3): Control Register;
        bit[0]: submit the write request; (Need to clear once submitting for a single write operation);
        bit[1]: submit the read request; (Need to clear once submitting for a single write operation);        
      
5. Register 4 (Offset 4): DDR2 Write Register - push the first 32-bit batch of the write_data[31:0]; active HIGH;
6. Register 5 (Offset 5): DDR2 Write Register - push the second 32-bit batch of the write_data[63:32]; active HIGH;
7. Register 6 (Offset 6): DDR2 Write Register - push the third 32-bit batch of the write_data[95:64]; active HIGH;
8. Register 7 (Offset 7): DDR2 Write Register -  push the forth 32-bit batch of the write_data[127:96]; active HIGH;
       
9. Register 8-11: to store the 128-bit read data as noted in the construction;

Register IO:
1. Register 0: read and write;
2. Register 1: read only;
3. Register 2: read and write;
4. Register 3: write only;
5. Register 4: write only;
6. Register 5: write only;
7. Register 6: write only;
8. Register 7: write only;
9. Register 8: read only;
10. Register 9: read only;
11. Register 10: read only;
12. Register 11: read only;
 
*****************************************************************/
class video_core_mig_interface{
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

    // register map;
    enum{
        // status and control;
        REG_SEL_OFFSET      = V5_MIG_INTERFACE_REG_SEL,
        REG_STATUS_OFFSET   = V5_MIG_INTERFACE_REG_STATUS,
        REG_ADDR_OFFSET     = V5_MIG_INTERFACE_REG_ADDR,
        REG_CTRL_OFFSET     = V5_MIG_INTERFACE_REG_CTRL,

        // write data registers;
        REG_WRDATA_01_OFFSET = V5_MIG_INTERFACE_REG_WRDATA_01,
        REG_WRDATA_02_OFFSET = V5_MIG_INTERFACE_REG_WRDATA_02,
        REG_WRDATA_03_OFFSET = V5_MIG_INTERFACE_REG_WRDATA_03,
        REG_WRDATA_04_OFFSET = V5_MIG_INTERFACE_REG_WRDATA_04,

        // read data registers;
        REG_RDDATA_01_OFFSET = V5_MIG_INTERFACE_REG_RDDATA_01,
        REG_RDDATA_02_OFFSET = V5_MIG_INTERFACE_REG_RDDATA_02,
        REG_RDDATA_03_OFFSET = V5_MIG_INTERFACE_REG_RDDATA_03,
        REG_RDDATA_04_OFFSET = V5_MIG_INTERFACE_REG_RDDATA_04

    };

    // register 0 - multiplexing - field and bit maskings;
    enum{
        REG_SEL_NONE    = V5_MIG_INTERFACE_REG_SEL_NONE,
        REG_SEL_CPU     = V5_MIG_INTERFACE_REG_SEL_CPU,
        REG_SEL_MOTION  = V5_MIG_INTERFACE_REG_SEL_MOTION,
        REG_SEL_TEST    = V5_MIG_INTERFACE_REG_SEL_TEST
    };
    
    // register 1 - status - field and bit maskings;
    enum{
        // bit position;
        REG_STATUS_BIT_POS_MIG_INIT     = V5_MIG_INTERFACE_REG_BIT_POS_STATUS_MIG_INIT,
        REG_STATUS_BIT_POS_MIG_RDY      = V5_MIG_INTERFACE_REG_BIT_POS_STATUS_MIG_RDY,
        REG_STATUS_BIT_POS_OP_COMPLETE  = V5_MIG_INTERFACE_REG_BIT_POS_STATUS_COMPLETE,
        REG_STATUS_BIT_POS_CTRL_IDLE    = V5_MIG_INTERFACE_REG_BIT_POS_STATUS_CTRL_IDLE,

        // bit masking;
        REG_STATUS_MIG_INIT_MASK    = BIT_MASK(REG_STATUS_BIT_POS_MIG_INIT),
        REG_STATUS_MIG_RDY_MASK     = BIT_MASK(REG_STATUS_BIT_POS_MIG_RDY),
        REG_STATUS_OP_COMPLETE_MASK = BIT_MASK(REG_STATUS_BIT_POS_OP_COMPLETE),
        REG_STATUS_CTRL_IDLE_MASK   = BIT_MASK(REG_STATUS_BIT_POS_CTRL_IDLE)
    };

    // register 2 - address;
    enum{
        REG_MIG_ADDR_SIZE = 23  
    };

    // register 3 - control register;
    enum{
        REG_CTRL_BIT_POS_WRSTROBE = V5_MIG_INTERFACE_REG_BIT_POS_WRSTROBE,
        REG_CTRL_BIT_POS_RDSTROBE = V5_MIG_INTERFACE_REG_BIT_POS_RDSTROBE,

        REG_CTRL_MASK_WRSTROBE = BIT_MASK(REG_CTRL_BIT_POS_WRSTROBE),
        REG_CTRL_MASK_RDSTROBE = BIT_MASK(REG_CTRL_BIT_POS_RDSTROBE)        
    };

    
    public:
        video_core_mig_interface(uint32_t core_base_addr);
        ~video_core_mig_interface();

        /* select which core to interface with the DDR2 via MIG; */
        void set_source(int source);
        /// wrappers for the above;        
        void set_core_none(void);
        void set_core_cpu(void);    // communicate via cpu;
        void set_core_test(void);   // hw test;
        void set_core_motion(void); // with the motion detection core;

        /* check mig status */
        uint32_t get_status(void);
        // wrapper for the above;
        int is_mig_init_complete(void);
        int is_mig_app_ready(void);
        int is_transaction_complete(void);  // common for both read and write;
        int is_mig_ctrl_idle(void);

        /* set the address, common for read and write */
        void set_addr(uint32_t addr);

        /* set control */        
        void submit_write(void);
        void submit_read(void);

        /* setup the write data 
        underlying MIG DDR2 write transaction is 128-bit;
        but cpu register is only 32-bit wide;
        so need four cpu registers to hold one transaction ...
        
        note, need to push the write data and set up the addres
        before submitting the write request;
        */
        void push_wrdata_01(uint32_t wrdata);   // first batch;
        void push_wrdata_02(uint32_t wrdata);   // second batch;
        void push_wrdata_03(uint32_t wrdata);   // third batch;
        void push_wrdata_04(uint32_t wrdata);   // forth batch;

        /* setup the read data 
        underlying MIG DDR2 read transaction is 128-bit;
        but cpu register is only 32-bit wide;
        so need four cpu registers to hold one transaction ...    
        */
        uint32_t get_rddata_01(void);   // first batch;
        uint32_t get_rddata_02(void);   // second batch;
        uint32_t get_rddata_03(void);   // third batch;
        uint32_t get_rddata_04(void);   // forth batch;

        /* utility;
        the purpose of using cpu to communicate with the ddr2 
        is to initialize the ddr2 for other applications;

        also, for testing purposes;        
        */
        
        void write_ddr2(uint32_t addr, uint32_t wrbatch01, uint32_t wrbatch02, uint32_t wrbatch03, uint32_t wrbatch04);
        void read_ddr2(uint32_t addr, uint32_t *read_buffer);
        void init_ddr2(uint32_t init_value, uint32_t start_addr, uint32_t range_addr);
        void check_init_ddr2(uint32_t init_value, uint32_t start_addr, uint32_t range_addr); // sanity check for init_ddr2();

    private:
        // this video core base address in the user-address space;
        uint32_t base_addr;
        
        // current source;
        int curr_source;
        
};

#ifdef __cpluscplus
} // extern "C";
#endif


#endif //_VIDEO_CORE_MIG_INTERFACE_H