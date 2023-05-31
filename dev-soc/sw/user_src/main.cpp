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
    // signal declaration;
    uint32_t start_addr = 0;                        // starting address of DDR2 to test;
    uint32_t range_addr = 100;                      // how many DDR2 address to cover?
    uint32_t init_value = (uint32_t)0xFFFFFFFF;     // common value to populate the DDR2;
    uint32_t read_status;

    debug_str("Video Core DDR2 MIG Test\r\n");
    vid_mig.set_core_test();

    /*
    // set the ddr2 to interface with the cpu;
    vid_mig.set_core_cpu();

    read_status = vid_mig.get_status();
    debug_str("status register: ");
    debug_hex(read_status);
    debug_str("\r\n");
    */
    /*
    // block until the mig signals calibration complete;
    while(!vid_mig.is_mig_init_complete()){};
    
    // initialize the DDR2 to a common value;
    debug_str("Setting initial value to DDR2 ...\r\n");
    vid_mig.init_ddr2(init_value, start_addr, range_addr);
    debug_str("Done setting initial value to DDR2 ...\r\n");

    // check the initialization;
    debug_str("Checking if the value initialization is correct.\r\n");
    vid_mig.check_init_ddr2(init_value, start_addr, range_addr);
    */
    while(1){        
        ;
    }
}

