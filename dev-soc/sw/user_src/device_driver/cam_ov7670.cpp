#include "cam_ov7670.h"

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

	uint8_t wr_buffer[1];	// i2c Tx buffer; only hold one byte;
	int i2c_no_repeat; 
    int status;

	/* ------------------------------------------
	 * Note
	 * To write into OV7670 register;
	 * In SCCB language, we could use 3-phase transmission cycle;
	 * Reference: SCCB Interface
	 * URL: https://www.waveshare.com/w/upload/1/14/OmniVision_Technologies_Seril_Camera_Control_Bus%28SCCB%29_Specification.pdf
	 ------------------------------------------*/

	wr_buffer[0] = wr_data;
    i2c_no_repeat = 0;         // no repeat;
    status = obj_i2c.write_transfer(OV7670_DEV_ID, wr_buffer, 1, i2c_no_repeat);
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


