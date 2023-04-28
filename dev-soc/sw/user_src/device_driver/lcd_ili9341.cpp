#include "lcd_ili9341.h"


/*---------------------------
* instantiate the video core
* LCD SW driver relies on
* lcd controller;
--------------------------*/
video_core_lcd_display obj_lcd_controller(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V0_DISP_LCD));

/*------------------------------
* function definition;
------------------------------*/
void lcd_ili9341_hw_reset(void){
	/*
    @brief      : to HW reset the LCD ILI9341;
    @param      : none
    @retval     : none
    @pinout     : PMOD JD07
    @assumption : gpio core class has been instantiated as global
    */

    // gpio core has been instantiated on device_directive.h
    obj_gpio.set_direction(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);
    
    // apply a reset pulse;
    // active low to reset;
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);
    delay_busy_ms(10);
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 0);
    delay_busy_ms(10);
    obj_gpio.write(LCD_ILI9341_HW_RSTN_PIN_JD07, 1);
    delay_busy_ms(1000); // take time to settle;
}

/*-------------------------------------------
* class definition;
-------------------------------------------*/

lcd_ili9341_sw_driver::lcd_ili9341_sw_driver(){
	/*
	@brief	: constructor;
	@param	: none;
	@retval	: none; 
	*/

	/* orientation */
	MY_p = 0;
	MX_p = 0;
	MV_p = 0;
	
	/* pixel order: RGB or BGR?*/
	BGR_order_p = 1;
	
	// enable the chip;
	enable();

	// update;
	set_orientation(MY_p, MX_p, MV_p); 
	set_BGR_order(BGR_order_p);    
}

// destructor; 
lcd_ili9341_sw_driver::~lcd_ili9341_sw_driver(){};

void lcd_ili9341_sw_driver::hw_reset(void){
	lcd_ili9341_hw_reset();
} 

void lcd_ili9341_sw_driver::enable(void){
	/*
	@brief	: chip select the lcd;
	@param	: none;
	@retval	: none;

	*/
	obj_lcd_controller.enable_chip();
}

void lcd_ili9341_sw_driver::disable(void){
	/*
	@brief	: chip deselect the lcd;
	@param	: none;
	@retval	: none;

	*/
	obj_lcd_controller.disable_chip();

}

void lcd_ili9341_sw_driver::disp_on(void){
	/*
	@brief	: turn on the display;
	@param	: none;
	@retval	: none;
	*/
	obj_lcd_controller.write_command(LCD_ILI9341_REG_DISP_ON);
	delay_busy_ms(200);
} 


void lcd_ili9341_sw_driver::disp_off(void){
	/*
	@brief	: turn off the display;
	@param	: none;
	@retval	: none;
	*/
	obj_lcd_controller.write_command(LCD_ILI9341_REG_DISP_OFF);
	delay_busy_ms(200);
} 

void lcd_ili9341_sw_driver::read_id(void){
    /*
    @brief  : read LCD ID's
    @param  : none;
    @retval : none;
    @note   : uart serial to view the read ID's
    */

   // there are four ID's to read;
   // first three are associated with the LCD manufacturer's ID;
   // last one is the chip (ILI9341) IC;
   
   // read mechanism;
   // check the datasheet;
   // for each read;
   // need to issue a write command;
   // followed by a dummy byte read;
   // then actual read;

    int is_data;    // data or command;
    uint8_t rd_data;    // to store the data read from the lcd;    
    uint8_t dummy_data; // dummy read;

    // setting up;
    debug_str("\r\nto read the LCD ID's\r\n");
    obj_lcd_controller.enable_chip();
    
    /* ------- read id 01; */
    debug_str("LCD ILI9341: reading ID1 @ 0xDA\r\n");
    debug_str("Expected Read Value: 0x00\r\n");
    is_data = 0;    // it is a command;
    obj_lcd_controller.write(is_data, LCD_ILI9341_REG_RDID1);  // issue the command;
    
    dummy_data = obj_lcd_controller.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd_controller.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    /* ------- read id 02; */
    debug_str("LCD ILI9341: reading ID2 @ 0xDB\r\n");
    debug_str("Expected Read Value: 0x80\r\n");
    is_data = 0;    // it is a command;
    obj_lcd_controller.write(is_data, LCD_ILI9341_REG_RDID2);  // issue the command;
    
    dummy_data = obj_lcd_controller.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd_controller.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    /* ------- read id 03; */
    debug_str("LCD ILI9341: reading ID3 @ 0xDC\r\n");
    debug_str("Expected Read Value: 0x00\r\n");
    is_data = 0;    // it is a command;
    obj_lcd_controller.write(is_data, LCD_ILI9341_REG_RDID3);  // issue the command;
    
    dummy_data = obj_lcd_controller.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd_controller.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");


    /* ------- read id 04; */
    debug_str("LCD ILI9341: reading Chip ID @ 0xD3\r\n");
    // there are a few parameters to read;
    debug_str("Expected Read Values: 0x00, 0x93, 0x41\r\n");
    is_data = 0;    // it is a command;
    obj_lcd_controller.write(is_data, LCD_ILI9341_REG_RDID4);
    
    dummy_data = obj_lcd_controller.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd_controller.read();   // param 01;
    debug_str(" Param 01 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    rd_data = obj_lcd_controller.read();   // param 02;
    debug_str(" Param 02 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    rd_data = obj_lcd_controller.read();   // param 03;
    debug_str(" Param 03 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");


    // done;
    debug_str("finish reading the LCD\r\n");

}

void lcd_ili9341_sw_driver::read_status(void){
	/* 
	@bried	: read lcd display status @ lcd reg of 0x09;
	@param	: none
	@retval	: none
	*/

	uint8_t rd_data;
	
	// setting up;
    debug_str("\r\nto read the LCD display status \r\n");
    obj_lcd_controller.enable_chip();
    
	// issue command;
	debug_str("LCD ILI9341: reading reg 0x09\r\n");
    // there are a few parameters to read;
    debug_str("Expected Read Values: 0x00, 0x61, 0x00, 0x00\r\n");    
	obj_lcd_controller.write_command(LCD_ILI9341_REG_RDDST);

	// dummy read;
	obj_lcd_controller.read();

	// param 01
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 01 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    // param 02
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 02 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

	// param 03
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 03 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

	// param 04
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 04 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

   	// done;
    debug_str("done\r\n");

}

void lcd_ili9341_sw_driver::read_power_mode(void){
	/* 
	@brief	: read lcd display power mode @ lcd reg 0x0A;
	@param	: none
	@retval	: none
	*/	

	uint8_t rd_data;
	// setting up;
    debug_str("\r\nto read the LCD display power mode\r\n");
    obj_lcd_controller.enable_chip();
    
	// issue command;
	debug_str("LCD ILI9341: reading reg 0x0A\r\n");
    // there are a few parameters to read;
    debug_str("Expected Read Values: 0x08\r\n");    
	obj_lcd_controller.write_command(LCD_ILI9341_REG_RDDPM);

	// dummy read;
	obj_lcd_controller.read();

	// param 01
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 01 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

}

void lcd_ili9341_sw_driver::read_diagnostic(void){
	/*
	@brief	: read display self diagnostic result @ 0x0F lcd reg;
	@param	: none
	@retval	: none
	*/
	uint8_t rd_data;
	// setting up;
    debug_str("\r\nto read the LCD display self-diagnostic result\r\n");
    obj_lcd_controller.enable_chip();
    
	// issue command;
	debug_str("LCD ILI9341: reading reg 0x0F\r\n");
    // there are a few parameters to read;
    debug_str("Expected Read Values: Not sure\r\n");    
	obj_lcd_controller.write_command(LCD_ILI9341_REG_RDDSDR);

	// dummy read;
	obj_lcd_controller.read();

	// param 01
	rd_data = obj_lcd_controller.read();  
    debug_str(" Param 01 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

}
void lcd_ili9341_sw_driver::init(void){
    /* 
    @brief  	: basic initialization of the lcd ili9341
    @param  	: none
    @retval 	: none
	@assumption	: the LCD has been chip selected;
    */

   /*
	 * Main Settings:
	 * 0. Pixel Format      	: 16-bit;
	 * 1. Colour Format     	: RGB 565 (16-bit);
	 * 2. Dimension         	: 320 as Width and 240 as Height;
	 * 3. Interface Protocol    : MCU 8080-I series parallel interface
	 * 4. The rest are about setting timing, gamma and power which
	 * 		should be common regardless of the application of interest(?)
	 *
	 * Acknowledgment:
	 * 1. This is adapted from Adafruit initialization code with some settings twerked;
	 * 2. Author: Adafruit Github communities
	 * 3. URL: https://github.com/adafruit/Adafruit_ILI9341
	 *
	 * Datasheet:
	 * 1.  https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf
	 */

	//> soft reset to clear all register values to default;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_SW_RESET);
	delay_busy_ms(150); // take time to reset all lcd registers;

	// device timing control
	obj_lcd_controller.write_command(LCD_ILI9341_REG_DTC_A);
	obj_lcd_controller.write_data(0x85);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0x78);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_DTC_B);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0x00);

	// power control
	obj_lcd_controller.write_command(LCD_ILI9341_REG_POWCTR_B);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0xC1);
	obj_lcd_controller.write_data(0x30);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_POWCTR_SEQ);
	obj_lcd_controller.write_data(0x64);
	obj_lcd_controller.write_data(0x03);
	obj_lcd_controller.write_data(0x12);
	obj_lcd_controller.write_data(0x81);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_POWCTR_A);
	obj_lcd_controller.write_data(0x39);
	obj_lcd_controller.write_data(0x2C);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0x34);
	obj_lcd_controller.write_data(0x02);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_POWCTR_1);
	obj_lcd_controller.write_data(0x10);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_POWCTR_2);
	obj_lcd_controller.write_data(0x10);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_VCOM_1);
	obj_lcd_controller.write_data(0x45);
	obj_lcd_controller.write_data(0x15);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_VCOM_2);
	obj_lcd_controller.write_data(0x90);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_PRC);
	obj_lcd_controller.write_data(0x20);

	//> interface selection and control
	// RGB565 (16 bit)
	obj_lcd_controller.write_command(LCD_ILI9341_REG_FRMCTR_1);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0x1B);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_DFC);
	obj_lcd_controller.write_data(0x0A);
	obj_lcd_controller.write_data(0xA7);
	obj_lcd_controller.write_data(0x27);
	obj_lcd_controller.write_data(0x04);

	// set interface to use MCU (8080-I)
	// set MCU interface to use 16-bit;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_PIXEL_FORMAT);
	obj_lcd_controller.write_data(0x55);

	/*
	interface control @ 0xF6;
	first param:
	1. WEMODE = 1; wrap around after pixel written
					exceeds memory address;
	2. the rest is in default;

	second param;
	0. it mainly deals with colour mode data format 
	1. and mthod of display data transferring (MDT);
	2. this is only relevant to RGB interface;
	3. could leave to default;


	third param;
	1. set endianness to big endian;
	2. set display operation mode (DM) to use internal clock operation;
	3. set RM to use system interface
	4. RIM: dont care since RGB interface is not used;
	*/
	obj_lcd_controller.write_command(LCD_ILI9341_REG_INTERFACE_CTR);
	obj_lcd_controller.write_data(0x01);	// 1st param; wemode = 1
	obj_lcd_controller.write_data(0x00);	// 2nd param: all default;
	obj_lcd_controller.write_data(0x00);	// 3rd param: endianess; DM; RM; RIM

	//> gamma stuff
	obj_lcd_controller.write_command(LCD_ILI9341_REG_GAMMA_SET);
	obj_lcd_controller.write_data(0x01);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_GAMMA_THREE);
	obj_lcd_controller.write_data(0x00);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_GAMMA_POSITIVE);
	obj_lcd_controller.write_data(0x0F);
	obj_lcd_controller.write_data(0x29);
	obj_lcd_controller.write_data(0x24);
	obj_lcd_controller.write_data(0x0C);
	obj_lcd_controller.write_data(0x0E);
	obj_lcd_controller.write_data(0x09);
	obj_lcd_controller.write_data(0x4E);
	obj_lcd_controller.write_data(0x78);
	obj_lcd_controller.write_data(0x3C);
	obj_lcd_controller.write_data(0x09);
	obj_lcd_controller.write_data(0x13);
	obj_lcd_controller.write_data(0x05);
	obj_lcd_controller.write_data(0x17);
	obj_lcd_controller.write_data(0x11);
	obj_lcd_controller.write_data(0x00);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_GAMMA_NEGATIVE);
	obj_lcd_controller.write_data(0x00);
	obj_lcd_controller.write_data(0x16);
	obj_lcd_controller.write_data(0x1B);
	obj_lcd_controller.write_data(0x04);
	obj_lcd_controller.write_data(0x11);
	obj_lcd_controller.write_data(0x07);
	obj_lcd_controller.write_data(0x31);
	obj_lcd_controller.write_data(0x33);
	obj_lcd_controller.write_data(0x42);
	obj_lcd_controller.write_data(0x05);
	obj_lcd_controller.write_data(0x0C);
	obj_lcd_controller.write_data(0x0A);
	obj_lcd_controller.write_data(0x28);
	obj_lcd_controller.write_data(0x2F);
	obj_lcd_controller.write_data(0x0F);

	//> done configuring
	obj_lcd_controller.write_command(LCD_ILI9341_REG_SLEEP_OUT);
	delay_busy_ms(200);

	obj_lcd_controller.write_command(LCD_ILI9341_REG_DISP_ON);
	delay_busy_ms(200);

}

void lcd_ili9341_sw_driver::set_area(uint16_t column_start, uint16_t page_start, uint16_t column_end, uint16_t page_end){
	/*
	 * @brief: To define the rectangular area (region) of display defined by the input positions.
	 * @input:
	 * 		column_start: start column position to write
	 * 		page_start	: start page position to write
	 * 		column_end	: end column position to write
	 * 		page_end	: end page position to write
	 * @retval: None
	 * @assumption	: the LCD has been chip selected;
	 *
	 * Reference:
	 * 		1. Datasheet: https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf
	 * 		2. Registers of interest:
	 * 			a. Column Address Set @2Ah
	 * 			b. Page Address Set @2Bh
	 */

	// column pointers;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_ADDR_COL_SET);
	obj_lcd_controller.write_data((uint8_t)(column_start >> 8));
	obj_lcd_controller.write_data((uint8_t)(column_start & 0xff));
	obj_lcd_controller.write_data((uint8_t)(column_end >> 8));
	obj_lcd_controller.write_data((uint8_t)(column_end & 0xff));

	// page pointers;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_ADDR_PAGE_SET);
	obj_lcd_controller.write_data((uint8_t)(page_start >> 8));
	obj_lcd_controller.write_data((uint8_t)(page_start & 0xff));
	obj_lcd_controller.write_data((uint8_t)(page_end >> 8));
	obj_lcd_controller.write_data((uint8_t)(page_end & 0xff));

}


void lcd_ili9341_sw_driver::set_orientation(uint16_t MY, uint16_t MX, uint16_t MV){
	/*
	 * @brief: Set LCD display orientations.
	 * @input:
	 * 		MY: Row Address Order
	 * 		MX: Column Address Order
	 * 		MV: Row/Column Exchange
	 * @retval:
	 * 		None
	 * @assumption	: the LCD has been chip selected;
	 * @assumption:
	 * 		1. The image to be displayed has to conform to the intended LCD display
	 * 		orientation as specified. Otherwise, the display image will be
	 * 		distorted.
	 * Note:
	 * 		1. This function also setup the page and column write address to
	 * 			setup up the area of interest to align with the orientation.
	 * 			Otherwise, the image will be distorted as well.
	 * Reference:
	 *		1. Datasheet: https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf
	 *		2. See page 127 and 209 of the datasheet/
	 *
	 */

	// dummy 8-bit placeholder to aggregate the input bits into one byte;
	uint8_t data_placeholder = 0x00;

	// update the private variables;
	MY_p = MY;
	MX_p = MX;
	MV_p = MV;
	
	
	//> note
	// ideally we should read the existing data from the LCD;
	// and change the data accordingly (by bit masking for rigour);

	// set the bits according to the inputs;
	// leave the rest in default;
	// (Vertical and Horizontal Refresh Order are zero by default);
	data_placeholder |= (MY << 7);
	data_placeholder |= (MX << 6);
	data_placeholder |= (MV << 5);

	// be careful not to override the RGB setting;
	data_placeholder |= (BGR_order_p << 3);

	// memory access control register @36h dictates the orientation;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_MAC);
	obj_lcd_controller.write_data(data_placeholder);

	// to ensure the display area aligns with the memory orientation above;
	// if X-Y exchange, we should swap between column and page address as well;
	if(MV == 1){
		set_area(0, 0, LCD_ILI9341_DIMENSION_HIGH_320-1 , LCD_ILI9341_DIMENSION_LOW_240-1);
	}else{
		set_area(0, 0, LCD_ILI9341_DIMENSION_LOW_240-1, LCD_ILI9341_DIMENSION_HIGH_320-1);
	}
}

void lcd_ili9341_sw_driver::set_BGR_order(int BGR_order){
	/* 
	@brief	: set pixel order BGR or RGB?
	@param	: BGR_order  - 1 to set to BGR; otherwise to RGB
	@retval	: none
	*/

	uint8_t data_placeholder = 0x00;
	
	
	// this requires lcd register at 0x36;
	// this register packs other stuffs as well;
	// becareful not to override the orientation settings;

	// read from the private variable;

	data_placeholder |= (MY_p << 7);
	data_placeholder |= (MX_p << 6);
	data_placeholder |= (MV_p << 5);

	if(BGR_order){
		data_placeholder |= (1 << 3);
		BGR_order_p = 1; // update the private var;

	}else{
		data_placeholder |= (0 << 3);
		BGR_order_p = 0; // update the private var;
	}

	// update the lcd register;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_MAC);
	obj_lcd_controller.write_data(data_placeholder);

}


void lcd_ili9341_sw_driver::write_pixel(uint16_t pixel){
	/*
	 * @brief		: Write Pixel in 16-bit using "8-bit function";
	 * @note		: the LCD only has 8 (parallel) pins for the data;
	 * @param		: pixel - 16-bit data to be written to the LCD as data;
	 * @retval		: None
	 * @note		: this is a blocking method;
	 * @assumption	: the LCD has been chip selected;
	 */


	// unpacking since only 8-bit can be sent at a time;
	uint8_t upper_data = (uint8_t)(pixel >> 8);		// upper 8-bit;
	uint8_t lower_data = (uint8_t)(pixel & 0x00FF); 	// lower 8-bit by masking out the upper 8-bit

	// assumme big endian;
	obj_lcd_controller.write_data(upper_data);
	obj_lcd_controller.write_data(lower_data);
}

void lcd_ili9341_sw_driver::fill_colour(uint16_t mono_colour){
	/*
	 * @brief		: To paint the entire LCD with a single colour;
	 * @param		: mono_colour - 16-bit RGB565 format
	 * @retval		: None
	 * @note		: this is a blocking method;
	 * @assumption	: the LCD has been chip selected;
	 */

	// variable declarations;
	//uint32_t index;
	uint32_t i;	// loop index;
	uint32_t j;	// loop index;
	
	// terminate any existing operations;
	obj_lcd_controller.write_command(LCD_ILI9341_OP_END);


	// command the LCD to accept write before writing the pixels;
	obj_lcd_controller.write_command(LCD_ILI9341_REG_MEM_WRITE);

	// start filling up the entire LCD with the given colour;
	//for(index = 0; index < LCD_ILI9341_PIXEL_NUM; index++){
	for(i = 0; i < LCD_ILI9341_DIMENSION_LOW_240; i++){
		for(j = 0; j < LCD_ILI9341_DIMENSION_HIGH_320; j++)
			write_pixel(mono_colour);
	}
	
	// terminate the memory write operation;
	obj_lcd_controller.write_command(LCD_ILI9341_OP_END);

}


void lcd_ili9341_sw_driver::disp_inv(int to_invert){
	/*
	@brief	: to invert the display or not?
	@param	: to_invert: binary: 1 to invert; 0 otherwise;
	@retval	: none
	*/

	// registers of interest: 0x20, 0x21;
	if(to_invert){
		obj_lcd_controller.write_command(LCD_ILI9341_REG_DISP_INV_ON);
	}else{
		obj_lcd_controller.write_command(LCD_ILI9341_REG_DISP_INV_OFF);
	}
}   

