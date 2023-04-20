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
