#include "lcd_ili9341.h"

video_core_lcd_display obj_lcd(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V0_DISP_LCD));

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


void lcd_ili9341_read_id(void){
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
    debug_str("to read the LCD ID's\r\n");
    obj_lcd.enable_chip();
    
    // hw reset;
    lcd_ili9341_hw_reset();
    
    /* ------- read id 01; */
    debug_str("LCD ILI9341: reading ID1 @ 0xDA\r\n");
    debug_str("Expected Read Value: 0x00\r\n");
    is_data = 0;    // it is a command;
    obj_lcd.write(is_data, LCD_ILI9341_RDID1);  // issue the command;
    
    dummy_data = obj_lcd.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    /* ------- read id 02; */
    debug_str("LCD ILI9341: reading ID2 @ 0xDB\r\n");
    debug_str("Expected Read Value: 0x80\r\n");
    is_data = 0;    // it is a command;
    obj_lcd.write(is_data, LCD_ILI9341_RDID2);  // issue the command;
    
    dummy_data = obj_lcd.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    /* ------- read id 03; */
    debug_str("LCD ILI9341: reading ID3 @ 0xDC\r\n");
    debug_str("Expected Read Value: 0x00\r\n");
    is_data = 0;    // it is a command;
    obj_lcd.write(is_data, LCD_ILI9341_RDID3);  // issue the command;
    
    dummy_data = obj_lcd.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd.read();   // actual read;
    debug_str("Actual Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");


    /* ------- read id 04; */
    debug_str("LCD ILI9341: reading Chip ID @ 0xD3\r\n");
    // there are a few parameters to read;
    debug_str("Expected Read Values: 0x00, 0x93, 0x41\r\n");
    is_data = 0;    // it is a command;
    obj_lcd.write(is_data, LCD_ILI9341_RDID4);
    
    dummy_data = obj_lcd.read(); // dummy read;
    debug_str("any value read from dummy read?: ");
    debug_hex(dummy_data);
    debug_str("\r\n");
    
    rd_data = obj_lcd.read();   // param 01;
    debug_str(" Param 01 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    rd_data = obj_lcd.read();   // param 02;
    debug_str(" Param 02 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");

    rd_data = obj_lcd.read();   // param 03;
    debug_str(" Param 03 - Read Value: ");
    debug_hex(rd_data);
    debug_str("\r\n");


    // done;
    debug_str("finish reading the LCD\r\n");

}

void lcd_ili9341_init(void){
    /* 
    @brief  : basic initialization of the lcd ili9341
    @param  : none
    @retval : none
    
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

	//> variable declarations for setting up the LCD and RGB orientation;
	uint8_t MY;	// row address order;
	uint8_t MX; // column address order;
	uint8_t MV; // row/columnn exchanged;
	uint8_t RGB_order; // RGB or BGR?

	//> soft reset to clear all register values to default;
	obj_lcd.write_command(LCD_ILI9341_REG_SW_RESET);
	delay_busy_ms(150); // take time to reset all lcd registers;

	// device timing control
	obj_lcd.write_command(LCD_ILI9341_REG_DTC_A);
	obj_lcd.write_data(0x85);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0x78);

	obj_lcd.write_command(LCD_ILI9341_REG_DTC_B);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0x00);

	// power control
	obj_lcd.write_command(LCD_ILI9341_REG_POWCTR_B);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0xC1);
	obj_lcd.write_data(0x30);

	obj_lcd.write_command(LCD_ILI9341_REG_POWCTR_SEQ);
	obj_lcd.write_data(0x64);
	obj_lcd.write_data(0x03);
	obj_lcd.write_data(0x12);
	obj_lcd.write_data(0x81);

	obj_lcd.write_command(LCD_ILI9341_REG_POWCTR_A);
	obj_lcd.write_data(0x39);
	obj_lcd.write_data(0x2C);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0x34);
	obj_lcd.write_data(0x02);

	obj_lcd.write_command(LCD_ILI9341_REG_POWCTR_1);
	obj_lcd.write_data(0x10);

	obj_lcd.write_command(LCD_ILI9341_REG_POWCTR_2);
	obj_lcd.write_data(0x10);

	obj_lcd.write_command(LCD_ILI9341_REG_VCOM_1);
	obj_lcd.write_data(0x45);
	obj_lcd.write_data(0x15);

	obj_lcd.write_command(LCD_ILI9341_REG_VCOM_2);
	obj_lcd.write_data(0x90);

	obj_lcd.write_command(LCD_ILI9341_REG_PRC);
	obj_lcd.write_data(0x20);

	//> interface selection and control
	// RGB565 (16 bit)
	obj_lcd.write_command(LCD_ILI9341_REG_FRMCTR_1);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0x1B);

	obj_lcd.write_command(LCD_ILI9341_REG_DFC);
	obj_lcd.write_data(0x0A);
	obj_lcd.write_data(0xA7);
	obj_lcd.write_data(0x27);
	obj_lcd.write_data(0x04);

	// set interface to use MCU (8080-I)
	// set MCU interface to use 16-bit;
	obj_lcd.write_command(LCD_ILI9341_REG_PIXEL_FORMAT);
	obj_lcd.write_data(0x55);

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
	obj_lcd.write_command(LCD_ILI9341_REG_INTERFACE_CTR);
	obj_lcd.write_data(0x01);	// 1st param; wemode = 1
	obj_lcd.write_data(0x00);	// 2nd param: all default;
	obj_lcd.write_data(0x00);	// 3rd param: endianess; DM; RM; RIM

	//> gamma stuff
	obj_lcd.write_command(LCD_ILI9341_REG_GAMMA_SET);
	obj_lcd.write_data(0x01);

	obj_lcd.write_command(LCD_ILI9341_REG_GAMMA_THREE);
	obj_lcd.write_data(0x00);

	obj_lcd.write_command(LCD_ILI9341_REG_GAMMA_POSITIVE);
	obj_lcd.write_data(0x0F);
	obj_lcd.write_data(0x29);
	obj_lcd.write_data(0x24);
	obj_lcd.write_data(0x0C);
	obj_lcd.write_data(0x0E);
	obj_lcd.write_data(0x09);
	obj_lcd.write_data(0x4E);
	obj_lcd.write_data(0x78);
	obj_lcd.write_data(0x3C);
	obj_lcd.write_data(0x09);
	obj_lcd.write_data(0x13);
	obj_lcd.write_data(0x05);
	obj_lcd.write_data(0x17);
	obj_lcd.write_data(0x11);
	obj_lcd.write_data(0x00);

	obj_lcd.write_command(LCD_ILI9341_REG_GAMMA_NEGATIVE);
	obj_lcd.write_data(0x00);
	obj_lcd.write_data(0x16);
	obj_lcd.write_data(0x1B);
	obj_lcd.write_data(0x04);
	obj_lcd.write_data(0x11);
	obj_lcd.write_data(0x07);
	obj_lcd.write_data(0x31);
	obj_lcd.write_data(0x33);
	obj_lcd.write_data(0x42);
	obj_lcd.write_data(0x05);
	obj_lcd.write_data(0x0C);
	obj_lcd.write_data(0x0A);
	obj_lcd.write_data(0x28);
	obj_lcd.write_data(0x2F);
	obj_lcd.write_data(0x0F);

	//> done configuring
	obj_lcd.write_command(LCD_ILI9341_REG_SLEEP_OUT);
	delay_busy_ms(200);

	obj_lcd.write_command(LCD_ILI9341_REG_DISP_ON);
	delay_busy_ms(200);


}