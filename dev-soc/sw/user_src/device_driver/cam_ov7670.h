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
#include "device_directive.h"


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

#define OV7670_OUTPUT_FORMAT_RGB565 0 // set the camera output to RGB565
#define OV7670_OUTPUT_FORMAT_YUV422 1 // set the camera output to YUV422

#define MASK_TOGGLE_BIT_B0 0b00000001
#define MASK_TOGGLE_BIT_B1 0b00000010
#define MASK_TOGGLE_BIT_B2 0b00000100
#define MASK_TOGGLE_BIT_B3 0b00001000
#define MASK_TOGGLE_BIT_B4 0b00010000
#define MASK_TOGGLE_BIT_B5 0b00100000
#define MASK_TOGGLE_BIT_B6 0b01000000
#define MASK_TOGGLE_BIT_B7 0b10000000

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

// constants;
extern const uint8_t ov7670_basic_init_array[][2];    // array of initial values to set the basic control register of the camera;

// specific camera config;
void ov7670_set_pixel_clock(void);  // used only when the MCO is 36Mhz;
void ov7670_set_QVGA_size(void);    // set to QVGA: 240 x 320;
void ov7670_set_output_format(uint8_t output_format);   // YUV422 or RGB565?
void ov7670_set_flip(uint8_t hflip, uint8_t vflip);
void ov7670_set_test_pattern(uint8_t test_pattern);
void ov7670_init(uint8_t output_format); // wrapper of the above;

// test drivers;
void ov7670_test(void);



#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _CAM_OV7670_H

