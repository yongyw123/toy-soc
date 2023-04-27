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
