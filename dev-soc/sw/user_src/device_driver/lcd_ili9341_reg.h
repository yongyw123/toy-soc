/*
 * LCD ILI9341 control registr;
 *  Reference:
 *  1. Datasheet: https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf
 */

#ifndef LCD_ILI9341_REG_H
#define LCD_ILI9341_REG_H

/* no operation / dummy */
#define LCD_ILI9341_REG_NOP	0x00				// NOP; useful to end "ongoing ILI9341 operations" ;
#define LCD_ILI9341_OP_END LCD_ILI9341_REG_NOP 	// just a wrapper by above;

/* reset */
#define LCD_ILI9341_REG_SW_RESET 0x01			// soft reset;

/* LCD pixel format: 16-bit or 18-bit? */
#define LCD_ILI9341_REG_PIXEL_FORMAT 0x3A    	// COLMOD: pixel format set

/* display */
#define LCD_ILI9341_REG_DISP_OFF 0x28  			// display off;
#define LCD_ILI9341_REG_DISP_ON 0x29   			// display on;
#define LCD_ILI9341_REG_DISP_INV_OFF 0x20   	// display inversion off;
#define LCD_ILI9341_REG_DISP_INV_ON 0x21    	// display inversion on;

/* mode */
#define LCD_ILI9341_REG_SLEEP_IN 0x10  			// enter sleep
#define LCD_ILI9341_REG_SLEEP_OUT 0x11 			// exit sleep
#define LCD_ILI9341_REG_NORMAL_DISP_ON 0x13  	// normal display mode on;

/* memory addressing */
#define LCD_ILI9341_REG_ADDR_COL_SET 0x2A 	// column address set;
#define LCD_ILI9341_REG_ADDR_PAGE_SET 0x2B 	// page address set;
#define LCD_ILI9341_REG_MEM_WRITE 0x2C 		// memory write;
#define LCD_ILI9341_REG_MAC 0x36			// memory access control;

/* frame rate control */
#define LCD_ILI9341_REG_FRMCTR_1 0xB1 // frame rate control (normal mode/full colors);
#define LCD_ILI9341_REG_FRMCTR_2 0xB2 // frame rate control (idle mode/8 colors);
#define LCD_ILI9341_REG_FRMCTR_3 0xB3 // frame rate control (partial mode/full colors);

/* power control */
#define LCD_ILI9341_REG_POWCTR_SEQ 0xED // power on control sequence;
#define LCD_ILI9341_REG_POWCTR_A 0xCB 	// power control A
#define LCD_ILI9341_REG_POWCTR_B 0xCF 	// power control B
#define LCD_ILI9341_REG_POWCTR_1 0xC0 	// power control 1
#define LCD_ILI9341_REG_POWCTR_2 0xC1 	// power control 2
#define LCD_ILI9341_REG_POWCTR_3 0xC2 	// power control 3
#define LCD_ILI9341_REG_POWCTR_4 0xC3 	// power control 4
#define LCD_ILI9341_REG_POWCTR_5 0xC4 	// power control 5
#define LCD_ILI9341_REG_PRC 0xF7		// pump ratio control;
#define LCD_ILI9341_REG_VCOM_1 0xC5 	// VCOM 1
#define LCD_ILI9341_REG_VCOM_2 0xC7 	// VCOM 2

/* driver timing control */
#define LCD_ILI9341_REG_DTC_A 0xE8	// driver timing control A;
#define LCD_ILI9341_REG_DTC_B 0xEA	// driver timing control B;

/* gamma (curve) control */
#define LCD_ILI9341_REG_GAMMA_SET 0x26		// to select the desired Gamma curve for the current display
#define LCD_ILI9341_REG_GAMMA_THREE	0xF2	// enable 3 gamma;
#define LCD_ILI9341_REG_GAMMA_POSITIVE 0xE0 // positive gamma correction;
#define LCD_ILI9341_REG_GAMMA_NEGATIVE 0xE1 // negative gamma correction;

/* interface control */
#define LCD_ILI9341_REG_DFC 0xB6				// display function control;
#define LCD_ILI9341_REG_RGB_INTERFACE_CTR 0xB0	// RGB interface control
#define LCD_ILI9341_REG_INTERFACE_CTR 0xF6		// interface control;

/* read id */
// read manufacturer id;
#define LCD_ILI9341_RDID1   0xDA    // read id 1;
#define LCD_ILI9341_RDID2   0xDB    // read id 2;
#define LCD_ILI9341_RDID3   0xDC    // read id 3;

// read ic device code;
#define LCD_ILI9341_RDID4   0xD3  

#endif // LCD_ILI9341_REG_H
