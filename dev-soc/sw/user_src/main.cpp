#include "main.h"

/* global instance of each class representation of the IO cores*/
// mmio system;
core_gpo obj_led(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S2_GPO_LED));
core_gpi obj_sw(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S3_GPI_SW));
core_spi obj_spi(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S5_SPI));

// video system;
video_core_src_mux vid_src_mux(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V2_DISP_SRC_MUX));
video_core_dcmi_interface vid_dcmi(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V3_CAM_DCMI_IF));
video_core_test_pattern_gen vid_test_pattern(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V1_DISP_TEST_PATTERN));
video_core_pixel_converter_monoY2RGB565 vid_grayscale(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V4_PIXEL_COLOUR_CONVERTER));
video_core_mig_interface vid_mig(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V5_MIG_INTERFACE));

int main(){
    //////////////////////////////////////////
    // signal declaration;
    /////////////////////////////////////////

    // for reporting;
    int read_status;
    uint32_t read_reg;

    int count; // count;
    int check_OK;   

    // for reading;
    uint32_t read_buffer[4];

    //// for sequential testing;
    uint32_t seq_j; // loop  
    uint32_t seq_range = 50;
    
    //// for burst testing;
    uint32_t start_addr = 0;                        // starting address of DDR2 to test;
    uint32_t range_addr = 20;                      // how many DDR2 address to cover?
    uint32_t init_value = (uint32_t)0xFAFBFCF0;     // common value to populate the DDR2;

    // some test data;
    uint32_t test_address = (uint32_t)0x1F;        
    uint32_t test_wrdata01 = (uint32_t)0x12ABCDEF;
    uint32_t test_wrdata02 = (uint32_t)0x12345678;
    uint32_t test_wrdata03 = (uint32_t)0xAFBFCFDF;
    uint32_t test_wrdata04 = (uint32_t)0x10203040;
    uint32_t test_wrarray[4] = {test_wrdata01, test_wrdata02, test_wrdata03, test_wrdata04};

    debug_str("Video Core DDR2 MIG Test\r\n");
    debug_str("///////////////////////////////////\r\n");
    /////////////// test: selecting the interface core ;

    //vid_mig.set_core_none();
    //vid_mig.set_core_test();    
    // set the ddr2 to interface with the cpu;
    vid_mig.set_core_cpu();
    debug_str("Setting to cpu interface for MIG.\r\n");
    
    ///////////// test: reading the status register;
    // block until the mig signals calibration complete;
    debug_str("///////////////////////////////////\r\n");
    debug_str("test: reading the status register\r\n\r\n");
    while(!vid_mig.is_mig_init_complete()){};
    debug_str("MIG calibration is ok\r\n");

    // block until the mig signals its app is ready;
    while(!vid_mig.is_mig_app_ready()){};
    debug_str("MIG is ready\r\n");

    // read the entire status register;
    read_reg = vid_mig.get_status();
    debug_str("status register: ");
    debug_hex(read_reg);
    debug_str("\r\n");

    // print out the individual status
    read_status = vid_mig.is_mig_init_complete();
    debug_str("calibration status: ");
    debug_hex(read_status);
    debug_str("\r\n");

    read_status = vid_mig.is_mig_app_ready();
    debug_str("app ready status: ");
    debug_hex(read_status);
    debug_str("\r\n");

    read_status = vid_mig.is_transaction_complete();
    debug_str("ctrl transaction status: ");
    debug_hex(read_status);
    debug_str("\r\n");

    read_status = vid_mig.is_mig_ctrl_idle();
    debug_str("ctrl idle status: ");
    debug_hex(read_status);
    debug_str("\r\n");

    //////// test: simple read from just-initialized DDR2;
    // expect the read data to be gibberish;  

    debug_str("///////////////////////////////////\r\n");
    debug_str("Test: start simple reading from uninitialized (value) DDR2\r\n");
    debug_str("Expect gibberish data\r\n");
    vid_mig.read_ddr2(test_address, read_buffer);
    count = 0;
    for(int i = 0; i < 4; i++){
        debug_str("Read Data Batch 01: ");
        debug_hex(read_buffer[i]);
        debug_str("\r\n");
    }
    
    //////// test: simple write 
    debug_str("///////////////////////////////////\r\n");
    debug_str("Test: start simple writing\r\n");
    vid_mig.write_ddr2((uint32_t)test_address, test_wrdata01, test_wrdata02, test_wrdata03, test_wrdata04);
    debug_str("Test: done simple writing\r\n");

    //////// test: simple read;
    debug_str("Test: start simple reading\r\n");
    vid_mig.read_ddr2(test_address, read_buffer);
    count = 0;
    for(int i = 0; i < 4; i++){
        debug_str("Read Data Batch "); 
        debug_dec(i+1);
        debug_str(" : ");
        debug_hex(read_buffer[i]);
        debug_str("\r\n");
        if(read_buffer[i] != test_wrarray[i]){
            debug_str("test reading and writing FAILED; abort\r\n");
            break;
        }else{
            count++;
        }   
    }
    debug_str("Passed test count: ");
    debug_dec(count);
    debug_str("\r\n");


    //////////////////////////////////////////////////////////////////////
    /// test: sequential write->read;
    /// use the address as the write data;
    ////////////////////////////////////////////////////////////////////
    debug_str("///////////////////////////////////\r\n");
    debug_str("Test: sequential write->read\r\n");    
    count = 0;
    for(seq_j = 0; seq_j < seq_range; seq_j++){
        // write; 
        vid_mig.write_ddr2((uint32_t)seq_j, seq_j, seq_j, seq_j, seq_j);
        vid_mig.read_ddr2((uint32_t)seq_j, read_buffer);
                
        debug_str("Index: ");
        debug_dec(seq_j);
        debug_str(" ; ");        
        check_OK = 0;
        debug_str("Unpacked read data: "); 
        // read in 32-bit batch data from a 128-bit DDR2 read transaction;
        for(int i = 0; i < 4; i++){                                                
            debug_hex(read_buffer[i]);
            debug_str(" | ");
            if(read_buffer[i] != seq_j){
                debug_str("ERROR: Read does not match with write.\r\n");                    
            }else{
                check_OK++;
            }   
        }
        
        // all batches within 128-bit data match?
        if(check_OK == 4){
            count++;
            debug_str(" ; Status: OK\r\n");
        }           
    }
    debug_str("Test: Sequential write->read ends\r\n");
    debug_str("Stats: ");
    debug_dec(count);
    debug_str(" matched \r\n");
    if(count == seq_range){
        debug_str("Status: PASSED\r\n");
    }else{
        debug_str("Status: FAILED\r\n");

    }

    //////////////////////////////////////////////////////////////////////

    debug_str("///////////////////////////////////\r\n");
    debug_str("Test: Burst write using a common write value; followed by a burst read\r\n");
    debug_str("Setup: \r\n");
    debug_str("Start Address: "); debug_hex(start_addr); debug_str("\r\n");
    debug_str("Test Range: "); debug_dec(range_addr); debug_str("\r\n");
    debug_str("Common Write Value: "); debug_hex(init_value); debug_str("\r\n");
    
    // initialize the DDR2 to a common value;
    debug_str("Burst Write starts.\r\n");
    vid_mig.init_ddr2(init_value, start_addr, range_addr);
    debug_str("Burst Write ends.\r\n");

    // check the initialization;
    debug_str("Burst Read starts\r\n");
    vid_mig.check_init_ddr2(init_value, start_addr, range_addr);
    debug_str("Burst Read ends\r\n");    
    

    while(1){        
        ;
    }
}

