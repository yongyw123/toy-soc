#ifndef _CAM_OV7670_H
#define _CAM_OV7670_H

#include "io_reg_util.h"
#include "io_map.h"
#include "user_util.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "core_spi.h"
#include "core_i2c_master.h"
#include "cam_ov7670_reg.h"


/* ------------------------------------------------
Purpose     : app driver to configure Camera OV7670;
Protocol    : SCCB (i2C equivalent)
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/*-------------------------------
* constants 
-------------------------------*/
#define OV7670_HW_RSTN_PIN_JA07 0       // which gpio port index used for camera hw reset;

// slave device id if left shifted one-bit plus R/W bit, this translates to 0x42 for write and 0x43 for read;
#define OV7670_DEV_ID           0x21  

/*------------------------------
function prototype;
------------------------------*/
// basic ov7670 rw;
void ov7670_hw_reset(void); // hw reset using an gpio pin;
int ov7670_write(uint8_t reg_addr, uint8_t wr_data); 
int ov7670_read(uint8_t reg_addr, uint8_t *rd_buffer);
void ov7670_update_reg(uint8_t reg_addr, uint8_t bit_mask_field, uint8_t bit_mask_set);

// to deal with an array of camera control registers;
void ov7670_write_array(const uint8_t input_array[][2]);    // write to an array of the camera control registers; 
void ov7670_read_array(const uint8_t input_array[][2]);     // read an array of the camera control registers;

// test drivers;
void ov7670_test(void);



#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _CAM_OV7670_H

