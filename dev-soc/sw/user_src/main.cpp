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

int main(){
    /* signal declarations */
    fifo_status_t dcmi_fifo_status;
    int dcmi_sys_ready_status;
    
    /*---------------------------------
    * Camera OV7670 init;
    ---------------------------------*/
    debug_str("start initializing camera ov7670; \r\n");
    //ov7670_init(OV7670_OUTPUT_FORMAT_RGB565);
    ov7670_init(OV7670_OUTPUT_FORMAT_YUV422);
    
    //ov7670_set_test_pattern(OV7670_TEST_PATTERN_NONE);
    ov7670_set_test_pattern(OV7670_TEST_PATTERN_COLOUR_BAR);
    
    debug_str("done initializing camera ov7670; \r\n\r\n");
    
    /*---------------------------------
    * LCD init via the processor    
    ---------------------------------*/
    // hand the control to the cpu;
    obj_lcd_controller.set_cpu_stream();

    // construct a sw driver for lcd;
    lcd_ili9341_sw_driver obj_lcd;

    // hw reset;
    obj_lcd.hw_reset();
    
    // to read LCD ILI9341 ids;
    obj_lcd.read_id();
    
    // read lcd display status;
    obj_lcd.read_status();

    // read lcd display power mode;
    obj_lcd.read_power_mode();

    // read self-diagnostic report;
    obj_lcd.read_diagnostic();
        
    // initialize the lcd;
    debug_str("initializing ... \r\n");
    obj_lcd.init();
    
    // orientation;
    debug_str("setting orientation ... \r\n");
    obj_lcd.set_orientation(0,1,1);

    // set pixel arrangement;
    obj_lcd.set_BGR_order(1);

    // turn it on;
	obj_lcd.disp_on();
	delay_busy_ms(100);

    /*---------------------------------------------
    * LCD display from HW pixel generation core(s)
    * not from the cpu;
    -------------------------------------------*/
    obj_lcd_controller.set_clockmod(2, 2, 50, 50);	    // ok
    
    /* !!!!!! IMPORTANT !!!!!!
	Need to issue the following command to the
	LCD in order to display anything;
	otherwise, it wont work;
	this command enables the transfer
	the pixel data from the host (board)
	to the LCD memory;
	*/
	// enable LCD memory write mode prior to switching the stream mode;
	obj_lcd.enable_memwr();
	delay_busy_ms(100);

	// hand over the control to the hw pixel generation cores;
	obj_lcd_controller.set_video_stream();


    /*-------------------------------------------------
    * Set up Pixel Converter (Grayscale)
    -------------------------------------------------*/
    vid_grayscale.enable_converter();
    //vid_grayscale.disable_converter();

    /*-----------------------------------------------
    * Note:
    * select which pixel source to use for the display;
    * the actual camera?
    * or the HW test pattern generator;
    -----------------------------------------------*/    
    debug_str("\r\n\r\n");
	debug_str("selecting the HW DCMI emulator \r\n");
    vid_src_mux.select_camera();

    // enable the hw test pattern generator;
    //vid_test_pattern.enable();
    //vid_src_mux.select_test();

    /*-----------------------------------------------
    * DCMI decoder;
    * before starting any capture;
    * check the status and states;
    -----------------------------------------------*/
    
    debug_str("\r\n\r\n");
    // check the system boot up state;

    // block until it becomes ready?
    while(!(vid_dcmi.is_sys_ready())){};

    dcmi_sys_ready_status = vid_dcmi.is_sys_ready();
    debug_str("checking dcmi sys init state ... \r\n");
    debug_str("sys init status: ");
    debug_hex(dcmi_sys_ready_status);
    debug_str("\r\n");

    // check the internal fifo status;
    dcmi_fifo_status = vid_dcmi.get_fifo_status();
    debug_str("checking dcmi internal fifo status\r\n");
    debug_str("almost_empty: ");
    debug_hex(dcmi_fifo_status.almost_empty);
    debug_str("\r\n");
    
    debug_str("empty: ");
    debug_hex(dcmi_fifo_status.empty);
    debug_str("\r\n");
    
    debug_str("almost_full: ");
    debug_hex(dcmi_fifo_status.almost_full);
    debug_str("\r\n");
    
    debug_str("full: ");
    debug_hex(dcmi_fifo_status.full);
    debug_str("\r\n");
    
    debug_str("read error: ");
    debug_hex(dcmi_fifo_status.rd_error);
    debug_str("\r\n");
    
    debug_str("write error: ");
    debug_hex(dcmi_fifo_status.wr_error);
    debug_str("\r\n");
    
    // dcmi snapshot;
    //debug_str("take a DCMI snapshot \r\n");
    //vid_dcmi.snapshot();



    /* "real-time" streaming */
    
    // continuous grabbing the frames from the camera and display them;
    vid_dcmi.cont_grab();
    
    debug_str("check done\r\n");
    
    while(1){        
        ;
    }
}

