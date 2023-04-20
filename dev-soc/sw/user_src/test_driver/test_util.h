#ifndef _TEST_UTIL_H
#define _TEST_UTIL_H

#include "io_reg_util.h"
#include "io_map.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "user_util.h"
#include "core_spi.h"

/* ------------------------------------------------
Purpose: test functions to check each HW IO cores;
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* function prototypes */

/*---------------------------------------------------
* IO cores to test:
* 1. general purpose output (gpo);
* 2. general purpose input (gpi);
*
* Method:
* 1. map led to gpo;
* 2. map sw to gpi;
* 3. map sw state to led state;
---------------------------------------------------*/
void test_led_sw(core_gpi *sw, core_gpo *led);  


/*---------------------------------------------------
* IO cores to test:
* 1. timer;
* 
* Method:
* use in conjunction with led;
---------------------------------------------------*/
void test_timer(core_gpo *led);


/*---------------------------------------------------
* IO core to test;
1. uart;

method;
1. connect the board to any PC;
2. open any serial console;
3. e.g. tera term;

uart default settings;
1. baud rate; 9600;
2. number of data bits; 8;
3. number of stop bits; 1;
4. parity bits; none;

---------------------------------------------------*/
void test_uart(void);

/*
* IO core to test;
1. gpio 

Feature to test:
1. gpio pin control direction manipulation;
*/
void test_gpio_ctrl_direction(core_gpio *gpio_obj);


/* ---------------------------------------------------
* IO core to test;
1. gpio 

Feature to test:
1. gpio pin - read 
2. gpio pin - write;

note that at the time of this writing;
PMOD JD0 to JD3 are configured as GPIO pins;

note that this requires some external HW connections
for testing

METHOD
for safety;
1. for pins configured as inputs; setup switches
    and connect the output of the switches to the LEDs;
2. for pins configured as outputs;
    generate a square wave and use logic analyzer
    to observe;
3. caution: DO NOT connect pins configured as outputs
    to pins configured as inputs;
    this is to reduce the incident of shorting the board!!

-----------------------------------------------------------*/
void test_gpio_read(core_gpio *gpio_obj, core_gpo *led_obj)__attribute__((noreturn)); 
void test_gpio_write(core_gpio *gpio_obj)__attribute__((noreturn));


/*-----------------------------------------------------------
IO core to test: SPI
background:
1. spi is a full duplex with the board being the master;
2. intended spi slave is the ILI9341 LCD;

test method:
before trying the spi core on the lcd;
we shall use logic analyser;
in this setting,
we could test the sclk, mosi, dcx lines;
for miso line; we could loop it back BUT we wont do this
out of fear that it may short the board;

what to test;
1. spi clock rate;
-----------------------------------------------------------*/
void test_spi_mosi(core_spi *spi_obj);

/*
IO core to test: SPI;
1. SPI core is tested by using an actual external SPI device;
2. Device: LCD (chip: ILI9341);
3. Method: This could test MOSI and MISO lines;
4. 
*/
void test_spi_device_lcd_ili9341(core_spi *spi_obj);

/*-----------------------------------------------------------
IO core to test: i2c
Note:
1. the test files are in cam_ov7670

Test Method:
1. to communicate with an actual i2c device; 

Device:
1. Camera OV7670;
-----------------------------------------------------------*/



#ifdef __cpluscplus
} // extern "C";
#endif


    
    


#endif // _TEST_UTIL_H
