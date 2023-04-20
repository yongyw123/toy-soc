#include "cam_ov7670.h"

/* required hw core for camera ov7670;
gpio for hw reset pin;
i2c to configure the camera;
*/
core_gpio obj_gpio(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));
core_i2c_master obj_i2c(GET_IO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S6_I2C_MASTER));

void ov7670_hw_reset(void){
    /*
    @brief  : to HW reset the camera using PIN @ JA07;
    @param  : none
    @retval : none
    @note   : gpio core class has been instantiated as global
    */
    obj_gpio.set_direction(OV7670_HW_RSTN_PIN_JA07, 1);
    
    // apply a reset pulse;
    // active low to reset;
    obj_gpio.write(OV7670_HW_RSTN_PIN_JA07, 1);
    delay_busy_ms(10);
    obj_gpio.write(OV7670_HW_RSTN_PIN_JA07, 0);
    delay_busy_ms(10);
    obj_gpio.write(OV7670_HW_RSTN_PIN_JA07, 1);
}

int ov7670_write(uint8_t reg_addr, uint8_t wr_data){
    /*
	 @brief : write to a ov7670 register;
	 @param :
            reg_addr: which camera register?
	        wr_data : what value to write?
     @retval: status of the i2c transfer;
	 */

	uint8_t wr_buffer[2];	// i2c Tx buffer; only hold one byte;
	int i2c_no_repeat; 
    int status;

	/* ------------------------------------------
	 * Note
	 * To write into OV7670 register;
	 * In SCCB language, we could use 3-phase transmission cycle;
	 * Reference: SCCB Interface
	 * URL: https://www.waveshare.com/w/upload/1/14/OmniVision_Technologies_Seril_Camera_Control_Bus%28SCCB%29_Specification.pdf
	 ------------------------------------------*/

	wr_buffer[0] = reg_addr;
    wr_buffer[1] = wr_data;
    i2c_no_repeat = 0;         // no repeat;
    status = obj_i2c.write_transfer(OV7670_DEV_ID, wr_buffer, 2, i2c_no_repeat);
    return status;
}

int ov7670_read(uint8_t reg_addr, uint8_t *rd_buffer){
	/*
	 @brief : read value from a register of OV7670l
	 @param :
            reg_addr    : which camera register?
	        rd_buffer   : pointer to a buffer to store the read data;
     @retval: status of the i2c transfer;
	 */

	uint8_t wr_buffer[1];	// i2c Tx buffer; only hold one byte;
	int status; 		// return value (status) from HAL function;
    int i2c_no_repeat;         // i2c repeat start?

	/* ------------------------------------------
	 * Note
	 * To read from OV7670 register;
	 * In SCCB language, it involves two steps;
	 * 1. 2-Phase Write Transmission Cycle followed by
	 * 2. 2-Phase Read Transmission Cycle
	 * Reference: SCCB Interface
	 * URL: https://www.waveshare.com/w/upload/1/14/OmniVision_Technologies_Seril_Camera_Control_Bus%28SCCB%29_Specification.pdf
	 ------------------------------------------*/
    
    // 2-phase write transmission cycle;
	wr_buffer[0] = reg_addr;
    i2c_no_repeat = 0;         // no repeat;
    status = obj_i2c.write_transfer(OV7670_DEV_ID, wr_buffer, 1, i2c_no_repeat);

    // 2-phase read transmission cycle;
    status = obj_i2c.read_transfer(OV7670_DEV_ID, rd_buffer, 1, i2c_no_repeat);
    return status;
}

void ov7670_test(void){
    /*
    @brief  : to test   
            0. ov7670_hw_reset();
            1. ov7670_write();
            2. ov7670_read();
    @method : logic analyser and uart;
    */

    /*
    1. choose a camera register to read and write;
    2. apply a reset to set all camera reg to default;
    3. read the cam reg; compare against the specs;
    4. write the cam reg; compare against the specs;
    5. read the cam reg; check against (4);

    */ 
    
    uint8_t chosen_reg = 0x00;
    uint8_t test_register_addr_set_00[1] = {chosen_reg};
	uint8_t test_register_value_set_00[1] = {0x11};

	uint8_t read_buffer[1];	// to store the register value read from OV7670;


    // HW reset to clear all registers to default;
    ov7670_hw_reset();
    delay_busy_ms(1);

    // read to make sure reg value is at default;
    ov7670_read(test_register_addr_set_00[0], read_buffer);
    debug_str("reset val: ");
    debug_hex(read_buffer[0]);
    debug_str("\r\n");

    delay_busy_ms(1);

    // change the register values;
    ov7670_write(test_register_addr_set_00[0], test_register_value_set_00[0]);
    debug_str("write val: ");
    debug_hex(test_register_value_set_00[0]);
    debug_str("\r\n");
    
    delay_busy_ms(1);

    // read if the reg val has been updated;
    ov7670_read(test_register_addr_set_00[0], read_buffer);
    debug_str("read val after write: ");
    debug_hex(read_buffer[0]);
    debug_str("\r\n");
    
    delay_busy_ms(1);
}

void ov7670_update_reg(uint8_t reg_addr, uint8_t bit_mask_field, uint8_t bit_mask_set){
	/*
	 @brief: A utility tool to update certain bit of the control register in OV7670 camera;
	 @param:
	 	    reg_addr        : which control register address to update?
	  		bit_mask_field  : for masking;
	  		bit_mask_set    : for setting;
	 @output: none
	 
	 @usage:
	 reg_addr		= 0x00 			// the control register is located at 0x00;
	 bit_mask_field	= 0b0010_0010	// the user want to change the second and sixth bit;
	 bit_mask_set	= 0b0010_0000 	// the user want to set the second to LOW and the sixth to HIGH;
	 
	 */
	uint8_t rd_buffer[1]; // to read from the camera register;
	uint8_t wr_reg_val;

	// read the existing config to avoid changing other bit fields;
	ov7670_read(reg_addr, rd_buffer);
	wr_reg_val = rd_buffer[0];

	// clear the bit fields of interest;
	wr_reg_val &= ~bit_mask_field;

	// update the bit of interest;
	wr_reg_val |= bit_mask_set;
	ov7670_write(reg_addr, wr_reg_val);
}

void ov7670_write_array(const uint8_t input_array[][2]){
	/*
	 @brief   : initializing the OV7670 configurations based on a given array sequence;
	 @input   : an array of arrays: {reg_address, reg_value}
	 @output  : None
	 @assumption: input_array has a end-of-marker: OV7670_REG_LAST; otherwise it will stuck in a loop.
	 */

	// variable declarations;
	uint8_t row;
	uint8_t reg_address;
	uint8_t reg_value;

	// start the machinery;
	reg_address = OV7670_REG_LAST - 1; // dummy initialized;
	while(reg_address != OV7670_REG_LAST){
		reg_address = input_array[row][0];
		reg_value = input_array[row][1];

		// send the command to the camera via SCCB (i2c);
		ov7670_write(reg_address, reg_value);
		
		// soft reset (SCCB register reset)takes longer settling time;
		if((reg_address == OV7670_REG_COM7)&&(reg_value == OV7670_COM7_SOFT_RESET)){
			delay_busy_ms(1000); // one second; arbitrarily defined;
		}

        // next;
		row++;

		// setting time; not strictly required;
		delay_busy_ms(10);
	}
}

void ov7670_read_array(const uint8_t input_array[][2]){
	/*
	 @brief     : read OV7670 register value and check them against a given input array;
	 @input     : an array of arrays: {reg address, expected reg value}
	 @output    : None
	 @note      : This function will serial print the result via UART. Connect to a PC to view them.
	 @assumption: input_array has a end-of-marker: OV7670_REG_LAST; otherwise it will stuck in a loop.
	 */

	//> variable declarations;
	uint8_t read_buffer[1];							// to read from the camera register;
	uint8_t read_reg_address;						// which register address?
	uint8_t read_reg_value;							// = read_buffer[0];
	uint8_t expected_reg_value;						// compared against the expected reg value;
	uint8_t match_status;							// read reg value == expected reg value?
	uint8_t index;									// loop index;

	//> check the register of interest;
	index = 0;
	read_reg_address = OV7670_REG_LAST - 1; // dummy initialized;

	while(read_reg_address != OV7670_REG_LAST){
		// setting up;
		read_reg_address = input_array[index][0];
		expected_reg_value = input_array[index][1];

		// read from the camera register;
		ov7670_read(read_reg_address, read_buffer);
		read_reg_value = read_buffer[0];

		// compare;
		match_status = (read_reg_value == expected_reg_value);
		
        // serial print out;
        debug_str("addr: "); debug_hex(read_reg_address);
        debug_str("rd val: "); debug_hex(read_reg_value);
        debug_str("ex val: "); debug_hex(expected_reg_value);
        debug_str("matched?: "); debug_hex(match_status);
        
		// settling time;
		delay_busy_ms(10);

		// next;
		index++;
	}
}


const uint8_t ov7670_basic_init_array[][2] = {
		/*-----------------------------------------------------------
		 * @Purpose: Defining OV7670 camera common/general initialization array sequence;
         * @note    : this is used with function: ov7670_write_array();
		 * @Setting: Main config specific to the application is the synchronization signals.
		 * 			The rest are about image-related stuffs such as gamma, power etc.
		 * @Synchronization Signal:
		 * 		1. MCLK: Input Clock to operate the Camera is 24 MHz
		 * 		2. PCLK: Pixel Clock generated by the camera to synchronize is 1:1 with MCLK.
		 * 		3. VSYNC: LOW during idle.
		 * @Assumption: This array DOES NOT configure the following
		 * 		1. resolution size (VGA, QVGA, etc)
		 * 		2. pixel clock: default at 1:1 with the input MCLK;
		 * 		3. output format: default RGB565;
		 * @Acknowlegment:
		 * 		1. The majority of the configuration is based on Adafruit with some settings tweaked.
		 * 		2. Author: Adafruit Communities
		 * 		3. URL: https://github.com/adafruit/Adafruit_OV7670/blob/master/src/ov7670.c
		 * @Reference:
		 * 		1. Datasheet: http://web.mit.edu/6.111/www/f2016/tools/OV7670_2006.pdf
		 * 		2. Implementation Guide: https://www.haoyuelectronics.com/Attachment/OV7670%20+%20AL422B(FIFO)%20Camera%20Module(V2.0)/OV7670%20Implementation%20Guide%20(V1.0).pdf
		 ----------------------------------------------------------*/

		/*==========================
		 *  setting output format;
		 *  RGB565;
		 *  full range: [0,255]
		 =========================*/
		{OV7670_REG_COM7, 0x14}, 	// RGB format with QVGA resolution;
		{OV7670_REG_RGB444, 0x00},	// must be disabled since RGB 565 is used;
		{OV7670_REG_COM15, OV7670_COM15_RGB565 | OV7670_COM15_R00FF},// choose full 00 to FG range using RGB565;

		{OV7670_REG_TSLB, 0x00},  	// no auto window

		/*==========================
		 * magical register;
		 * important? from the internet;
		 * without this, the colour
		 * displayed is slightly off;
		 * not that significant though?
		 ==========================*/
		{0xB0, 0x84},

		/* ===========================
		 * Synchronization Clock
		 * 1. VSYNC is HIGH during valid data; LOW during idle;
		 * 2. HREF and HSYNC are similar, so HREF is used;
		 * 3. Data update on PCLK rising edge;
		 * 4. PCLK free running regardless;
		 ============================*/
		{OV7670_REG_COM10, OV7670_COM10_VS_NEG}, // -VSYNC

		/*======================
		 * Gamma Curve Stuffs;
         ======================*/
		{OV7670_REG_COM13, 0x80},   // gamma enable
		{OV7670_REG_COM16, 0x38},   // YUV edge enhancement, de-noise, AWG gain enabled
		{OV7670_REG_SLOP, 0x20},	// gamma curve hight segment slope;
		{OV7670_REG_GAM_BASE, 0x1C},
		{OV7670_REG_GAM_BASE + 1, 0x28},
		{OV7670_REG_GAM_BASE + 2, 0x3C},
		{OV7670_REG_GAM_BASE + 3, 0x55},
		{OV7670_REG_GAM_BASE + 4, 0x68},
		{OV7670_REG_GAM_BASE + 5, 0x76},
		{OV7670_REG_GAM_BASE + 6, 0x80},
		{OV7670_REG_GAM_BASE + 7, 0x88},
		{OV7670_REG_GAM_BASE + 8, 0x8F},
		{OV7670_REG_GAM_BASE + 9, 0x96},
		{OV7670_REG_GAM_BASE + 10, 0xA3},
		{OV7670_REG_GAM_BASE + 11, 0xAF},
		{OV7670_REG_GAM_BASE + 12, 0xC4},
		{OV7670_REG_GAM_BASE + 13, 0xD7},
		{OV7670_REG_GAM_BASE + 14, 0xE8},

		/*====================
		 *  Setting AEC/AGC
		=====================*/
		{OV7670_REG_GAIN, 0x00},	//AGC gain control; default;
		{OV7670_REG_COM4, 0x00},	// full window
		{OV7670_REG_COM9, 0x20}, 	// Max AGC value
		{OV7670_REG_BD50MAX, 0x05},	// 50Hz Banding Step Limit;
		{OV7670_REG_BD60MAX, 0x07},	// 60Hz Banding Step Limit;
		{OV7670_REG_AEW, 0x75},		// AGC/AEC Stable Operating Region Upper limit; default;
		{OV7670_REG_AEB, 0x63}, 	// AGC/AEC Stable Operating Region lower limit; default;
		{OV7670_REG_VPT, 0xA5},		// AGC/AEC Fast mode operating region;

		/*======================
		 *  histogram control
		 ======================*/
		{OV7670_REG_HAECC1, 0x78},
		{OV7670_REG_HAECC2, 0x68},
		{OV7670_REG_RSVD_XA1, 0x03},   	// reserved; dont care;
		{OV7670_REG_HAECC3, 0xDF}, 		// Histogram-based AEC/AGC setup
		{OV7670_REG_HAECC4, 0xDF},
		{OV7670_REG_HAECC5, 0xF0},
		{OV7670_REG_HAECC6, 0x90},
		{OV7670_REG_HAECC7, 0x94},

		//enable AEC|enable banding filter|set AEC step size|enable AEC algorithm;
		{OV7670_REG_COM8, OV7670_COM8_FASTAEC|OV7670_COM8_AECSTEP|OV7670_COM8_BANDING|OV7670_COM8_AGC|OV7670_COM8_AEC},
		{OV7670_REG_COM5, 0x61},		//reserved register but default value is at 0x01?
		{OV7670_REG_COM6, 0x4B},		// enable HREF at optical black and reset timing when format changes;
		{OV7670_REG_RSVD_X16, 0x02},	// reserved register; dont care;
		{OV7670_REG_MVFP, 0x07},		// normal image (no flip; no mirror);

		{OV7670_REG_ADCCTR1, 0x02},		// reserved; default at 0x21;
		{OV7670_REG_ADCCTR2, 0x91},		// reserved; default at 0x01;
		{OV7670_REG_RSVD_X29, 0x07}, 	// reserved register; dont care;
		{OV7670_REG_CHLF, 0x0B},		// array current control; reserved; default at 0x08;
		{0x35, 0x0B}, 					// Reserved register?

		/*=====================
		 * ADC control;
		 =====================*/
		{OV7670_REG_ADC, 0x1D},		// ADC control; reserved; default at 0x3F;
		{OV7670_REG_ACOM, 0x71},	// Analog common mode control; reserved; default at 0x01;
		{OV7670_REG_OFON, 0x2A},	// ADC offset control; reserved; default at 0x00;

		/*=====================
		* IMPORTANT
		* No HREF when VSYNC is LOW;
		* Otherwise, it won't work;
		 =====================*/
		{OV7670_REG_COM12, 0x78},
		{0x4D, 0x40}, // Reserved register?
		{0x4E, 0x20}, // Reserved register?

		/*==============================
		 *  fix gain control;
		 *  0x5D;
		 *  1.25x gain for GR channel;
		 *  1.25x gain for GB channel;
		 *	1.5x gain for R channel;
		 *	1.75x gain for B channel;
		 ==============================*/
		{OV7670_REG_GFIX, 0x5D},

		/*===============================
		 * Digital Gain controlled by REG74;
		 * digital gain manual control by 1x;
		 ===============================*/
		{OV7670_REG_REG74, 0x19},
		{0x8D, 0x4F}, // Reserved register?
		{0x8E, 0x00}, // Reserved register?
		{0x8F, 0x00}, // Reserved register?
		{0x90, 0x00}, // Reserved register?
		{0x91, 0x00}, // Reserved register?

		{OV7670_REG_DM_LNL, 0x00},	// dummy line low 8 bits; default;
		{0x96, 0x00},				// Reserved register?
		{0x9A, 0x80}, 				// Reserved register?
		{0xB0, 0x84},				// Reserved register?

		{OV7670_REG_ABLC1, 0x0C},	// disable ABLC function;
		{0xB2, 0x0E},				// Reserved register?
		{OV7670_REG_THL_ST, 0x82},	// ABLC target; default at 0x80;
		{0xB8, 0x0A}, 				// reserved register;

		/* =================================
		 * registers with reserved values;
		 =================================*/
		{OV7670_REG_AWBC1, 0x14},
		{OV7670_REG_AWBC2, 0xF0},
		{OV7670_REG_AWBC3, 0x34},
		{OV7670_REG_AWBC4, 0x58},
		{OV7670_REG_AWBC5, 0x28},
		{OV7670_REG_AWBC6, 0x3A},

		{0x59, 0x88}, // Reserved register?
		{0x5A, 0x88}, // Reserved register?
		{0x5B, 0x44}, // Reserved register?
		{0x5C, 0x67}, // Reserved register?
		{0x5D, 0x49}, // Reserved register?
		{0x5E, 0x0E}, // Reserved register?

		/*============================
		 * Lens correction option;
		 ===========================*/
		{OV7670_REG_LCC3, 0x04},
		{OV7670_REG_LCC4, 0x20},
		{OV7670_REG_LCC5, 0x05},
		{OV7670_REG_LCC6, 0x04},
		{OV7670_REG_LCC7, 0x08},

		/*============================
		 * AWB control;
		 ===========================*/
		{OV7670_REG_AWBCTR3, 0x0A},
		{OV7670_REG_AWBCTR2, 0x55},

		/*============================
		 * matrix coefficient;
		 ===========================*/
		{OV7670_REG_MTX1, 0x80},
		{OV7670_REG_MTX2, 0x80},
		{OV7670_REG_MTX3, 0x00},
		{OV7670_REG_MTX4, 0x22},
		{OV7670_REG_MTX5, 0x5E},
		{OV7670_REG_MTX6, 0x80}, 	// 0x40?
		//{OV7670_REG_MTX6, 0x40}, 	// 0x80?
		{OV7670_REG_MTXS, 0x9e},	// with auto contrast center enabled;
		//{OV7670_REG_MTXS, 0x1e},	// with auto contrast center disabled;

		{OV7670_REG_AWBCTR1, 0x11},
		{OV7670_REG_AWBCTR0, 0x9F}, // Or use 0x9E for advance AWB

		/*============================
		 * brightness and contrast
		 ===========================*/
		{OV7670_REG_BRIGHT, 0x00},			// default;
		{OV7670_REG_CONTRAS, 0x40},			// default;
		//{OV7670_REG_CONTRAS_CENTER, 0x80}, 	// 0x40? default;
		{OV7670_REG_CONTRAS_CENTER, 0x40}, 	// 0x40? default;

		/*============================
		 * Clock
		 * 1. MCLK input to the camera is 24MHz
		 * 2. PCLK is 1:1 with MCLK
		 * 3. There is a separate function to change the pclk;
		 * 4. see user_OV7670_set_pixel_clock();
		 ===========================*/
		{OV7670_REG_DBLV, 0x39}, // bypass PLL;

		//> done;
		// dummy terminator;
		{OV7670_REG_LAST, OV7670_REG_LAST},
};

