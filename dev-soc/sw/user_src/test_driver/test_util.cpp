#include "test_util.h"


/* function definition */


void test_led_sw(core_gpi *sw_obj, core_gpo *led_obj){
    /*
    * @brief        : to test HW GPO and GPI core by using led for gpo, sw for gpi;
    * @param        :
    *       sw_obj  : pointer to the (instantiated) core_gpi object;
    *       led_obj : pointer to the (instantiated) core_gpo object;s
    * @retval       : none
    * @test         : map switch state to led state;
    */

   // led output to correspond to the switch state;
   uint32_t sw_state = sw_obj->read();
   led_obj->write(sw_state);
}

void test_timer(core_gpo *led){
    /*
    * @brief    : to test timer core and gpo core;
    * @param    : led - pointer to the instantiated core_gpi object;
    * @note     : core_timer obj has been instantiated;
    * @retval   : none
    * @test     : blink the LED every X second with different toggling patterns;
    */
   uint32_t i;
   uint32_t led_num = 16;   // board has 16 leds;

   // test toggle as well;
   led->write(0xAAAA);  // alternate pattern;
   led->toggle();       // toggle the entire data;
    delay_busy_ms(2000); // two seconds;
    
    // test toggling individual bit;
    for(i = 0; i < led_num; i++){
        led->toggle(i);
        delay_busy_ms(1000); // one seconds;
    }
}

void test_uart(void){
    /*
    @brief      : to test uart core for serial debugging;
    @param      : none
    @retval     : none
    @assumption : class core_uart has been instantiated as global in user_util
    @method     :
        1. put this function in a while main loop and insert one noticeable delay,
            say at least two seconds (in the main while loop);
        2. program the board;
        3. open a serial console/terminal; e.g. tera term;
        4. set the serial setting to:
            baud rate: 9600 (default) if not changed by the user in the application code;
            #data bits: 8
            #stop bits: 1
            #parity bit: none
    */

   // how many times it has been called?
   static int index_called_p = 0; 
   
   // negative; to see whether the print method actually prints negative sign;
   static int index_called_n = 0;   

   // main uart methods have been wrapped as debug function;
   debug_str("uart called has been called ");
   debug_dec(index_called_p);
   debug_str(" times\r\n");
   debug_str("uart could display negative number: ");
   debug_dec(index_called_n);
   debug_str("\r\n");
   
   index_called_p++;
   index_called_n--;

    debug_str("pause for 2 seconds\r\n");
    delay_busy_ms(2000);
}

void test_gpio_ctrl_direction(core_gpio *gpio_obj){
    /*
    @brief  : test control direction register manipulation
    @param  : pointer to the instantiated gpio core class;
    @retval : none
    @setup  : use UART to debug; 
    
    @pin setup:
    1. PMOD JD00 to JD03 are configured as GPIO PINS;
    2. PMOD JD00 and JD01 directions are input;
    3. PMOD JD02 and JD03 directions are output;
    
    @test + expectation:
    
    1. check whether control direction is configured accordingly
    2. after reset, by default, all ports (pins) are set to input;
    3. and read_data will sample whatever is on the port, by construction;
    4. if pins set to inputs, the pins will have high impedance;
        until it is being fed externally;
    5. if not, rd_data of that particular pin will be HIGH due
        as it samples the high impedance by point (4);
    6. if pins set to outputs; by default, it will be LOW
        if there is a wr_data set by the user to the pins;

    */
    
    debug_str("background-------");
    debug_str("\r\n");

    /* just after a CPU reset */  
    // apply a cpu reset here;
    debug_str("if pin set to read, the direction status will be LOW\r\n");
    debug_str("otherwise, it will be HIGH\r\n");
    
    debug_str("example status direction read: ");
    debug_dec(gpio_obj->get_ctrl_dir_read());
    debug_str("\r\n");
    debug_str("example status direction write: ");
    debug_dec(gpio_obj->get_ctrl_dir_write());
    
    debug_str("\r\n");
    debug_str("test start-------");
    debug_str("\r\n");
    debug_str("after reset, the direction data\r\n");
    
    debug_str("from the control reg: "); 
    debug_bin(gpio_obj->read_ctrl_reg());
    debug_str("\r\n");
    debug_str("from obj priv var: ");
    debug_bin(gpio_obj->debug_get_dir());
    
    debug_str("\r\n");
    debug_str("from the data reg: "); 
    debug_bin(gpio_obj->read());
    
    /* setting the gpio */  
    
    debug_str("\r\n");
    debug_str("after setting, the direction data\r\n");

    gpio_obj->set_direction(PIN_GPIO_PMOD_JD0, gpio_obj->get_ctrl_dir_read()); 
    gpio_obj->set_direction(PIN_GPIO_PMOD_JD1, gpio_obj->get_ctrl_dir_read());
    gpio_obj->set_direction(PIN_GPIO_PMOD_JD2, gpio_obj->get_ctrl_dir_write());
    gpio_obj->set_direction(PIN_GPIO_PMOD_JD3, gpio_obj->get_ctrl_dir_write());
    
    debug_str("from the control reg: "); 
    debug_bin(gpio_obj->read_ctrl_reg());
    
    debug_str("\r\n");
    debug_str("from obj priv var: ");
    debug_bin(gpio_obj->debug_get_dir());

    debug_str("\r\n");
    debug_str("from the data reg: "); 
    debug_bin(gpio_obj->read());
    
    debug_str("\r\n");
    debug_str("test done-------");
}


void test_gpio_read(core_gpio *gpio_obj, core_gpo *led_obj){
    /*
    @brief  : test gpio read;
    @param  : 
        gpio_obj    : pointer to the instantiated gpio core class;
        led_obj     : pointer to the instantiated gpo core class for LED;
    @retval : none
    
    @pin setup:
    1. PMOD JD00 to JD03 are configured as GPIO PINS;
    2. PMOD JD00 and JD01 directions are input;
    3. PMOD JD02 and JD03 directions are output;
    
    @ hw setup  :
    0. switches with pull-up resistor to 3.3V Power;
    1. switch: SPST where if pressed; connect to ground;
        otherwise, it will pulled up to the Power;
    2. connect the output of the read result to the corresponding LED;
    
        switch A @ pin JD0 <-> LED 00;
        switch B @ pin JD1 <-> LED 01;

    @test + expectation:
    1. without pressed, LED turns ON;
    2. pressed -> LED should turn OFF


    */
    
    // set the pin direction;
    test_gpio_ctrl_direction(gpio_obj);

    // start testing;

    int input_00;
    int input_01;
    // loop forever;
    while(1){
        input_00 = gpio_obj->read(PIN_GPIO_PMOD_JD0);
        input_01 = gpio_obj->read(PIN_GPIO_PMOD_JD1);
        
        led_obj->write(PIN_GPO_LED_00, input_00);
        led_obj->write(PIN_GPO_LED_01, input_01);
    }
}

void test_gpio_write(core_gpio *gpio_obj){
    /*
    @brief  : test gpio read;
    @param  : 
        gpio_obj    : pointer to the instantiated gpio core class;
    @retval : none
    
    @pin setup:
    1. PMOD JD00 to JD03 are configured as GPIO PINS;
    2. PMOD JD00 and JD01 directions are input;
    3. PMOD JD02 and JD03 directions are output;

    @test setup:
    1. output a square wave on the pins configured as output;
    2. use logic analyser to measure and check against the expectation;
    */    

   // set the pin direction;
   test_gpio_ctrl_direction(gpio_obj);

   // loop forever;
   while(1){
        // JD3 and JD2 output should be out of phase;
        gpio_obj->write(PIN_GPIO_PMOD_JD2, 1);
        gpio_obj->write(PIN_GPIO_PMOD_JD3, 0);

        // set to 20 ms period;
        delay_busy_ms(10);

        // toggle;
        gpio_obj->write(PIN_GPIO_PMOD_JD2, 0);
        gpio_obj->write(PIN_GPIO_PMOD_JD3, 1);

        // set to 20 ms period;
        delay_busy_ms(10);

   }

}

void test_spi_mosi(core_spi *spi_obj){
    /*
    @brief  : to test spi core (except miso line);
    @param  : spi_obj - pointer to an instantiated spi core object;
    @retval : none
    @method : logic analyser;
    @assumption : board pmod jumpers are used for the spi hw signals;
    
    */

   int cpol = 0;
   int cpha = 0;
   uint32_t sclk_freq = 100000; // 100 kHz;
   uint32_t ss_vector = (uint32_t)0xFFFFFFFF;
   // there is only one slave connected by the constraint map;
   int which_slave = 0; 
   
   // setup;
   spi_obj->set_transfer_mode(cpol, cpha);
   spi_obj->set_sclk(sclk_freq);
   spi_obj->set_ss_n(ss_vector);

    uint8_t wr_data;

    // start;
    for(int i = 0; i  < 100; i++){
        // assert;
        spi_obj->assert_ss(which_slave);

        // interchange between data and command;
        // high for data;
        // low for command;
        spi_obj->set_dc(i%2);

        // start;
        wr_data = (uint8_t)i;
        debug_str("\r\n");
        debug_str("mosi data: ");
        debug_dec(wr_data);
        debug_str("\r\n");

        spi_obj->full_duplex_transfer(wr_data);

        // deassert;
        spi_obj->deassert_ss(which_slave);
    
    }
}

void test_spi_device_lcd_ili9341(core_spi *spi_obj){
    /*
    @brief  : to test spi core with an actual SPI device;
    @param  : spi_obj - pointer to an instantiated spi core object;
    retval  : none

    Test:
    IO core to test: SPI;
    1. SPI core is tested by using an actual external SPI device;
    2. Device: LCD (chip: ILI9341);
    3. Method: This could test MOSI and MISO lines;

    datasheet:
    https://cdn-shop.adafruit.com/datasheets/ILI9341.pdf

    Background;
    1. the spi core here corresponds to 4-wire Serial (SPI) interface
        specified in the datasheet;

    What to read:
    1. from the datasheet, we shall read the following
    because the slave will only return one byte after a read command is issued;
    the rest of the information returns multiple bytes, which, is not 
    supported by the spi core here; why? spi core assummes full duplex single-byte 
    transaction only;

    how to read;
    1. first master issues a command to read a specific slave register address;
    2. then master issues a second dummy data write; which when the slave will respond
        from the (1) command;
    slave register (info) to read;
    1. display power mode @ 0x0A (slave register address);
        expect it to return 0x8 after power on reset;
    2. display MADCTL @ 0x0B
        expected returned value: 0x00
    3. display pixel format @ 0x0C
        expected returned value: 8'b0000_0110;
    4. display image format @ 0x0D;
        expected returned value: 0x00;


    */

   /* 
   setup 
   1. sclk rate: 1Mhz;
   2. cpol: 0;
   3. cpha: 0
   */
    int cpol = 0;
    int cpha = 0;
    int which_slave = 0;    // only one slave;
    uint32_t ss_vector = (uint32_t)0xFFFFFFFF;
    uint32_t sclk_freq = 1000000;   // 1MHz;
    int is_data = 1;
    int is_command = 0;
    uint8_t dummy_data = 0x00;
    uint8_t wr_data;
    uint8_t rd_data;

    spi_obj->set_transfer_mode(cpol, cpha);
    spi_obj->set_sclk(sclk_freq);
    spi_obj->set_ss_n(ss_vector);

    // start communicating;
    spi_obj->assert_ss(which_slave);

    debug_str("test starts\r\n");
    
    // read test 0;
    debug_str("read lcd at 0x0A, expect 0x08 response\r\n");
    spi_obj->set_dc(is_command);
    wr_data = 0x0A;
    spi_obj->full_duplex_transfer(wr_data);
    spi_obj->set_dc(is_data);
    rd_data = spi_obj->full_duplex_transfer(dummy_data);
    debug_str("returned: ");
    debug_dec(rd_data);
    debug_str("\r\n");

    // read test 1;
    debug_str("read lcd at 0x0B, expect 0x00 response\r\n");
    spi_obj->set_dc(is_command);
    wr_data = 0x0B;
    spi_obj->full_duplex_transfer(wr_data);
    spi_obj->set_dc(is_data);
    rd_data = spi_obj->full_duplex_transfer(dummy_data);
    debug_str("returned: ");
    debug_dec(rd_data);
    debug_str("\r\n");
    
    // read test 2;
    debug_str("read lcd at 0x0C, expect 0x06 response\r\n");
    spi_obj->set_dc(is_command);
    wr_data = 0x0C;
    spi_obj->full_duplex_transfer(wr_data);
    spi_obj->set_dc(is_data);
    rd_data = spi_obj->full_duplex_transfer(dummy_data);
    debug_str("returned: ");
    debug_dec(rd_data);
    debug_str("\r\n");
    
    // read test 3;
    debug_str("read lcd at 0x0D, expect 0x00 response\r\n");
    spi_obj->set_dc(is_command);
    wr_data = 0x0D;
    spi_obj->full_duplex_transfer(wr_data);
    spi_obj->set_dc(is_data);
    rd_data = spi_obj->full_duplex_transfer(dummy_data);
    debug_str("returned: ");
    debug_dec(rd_data);
    debug_str("\r\n");


    debug_str("test ends\r\n");

}


void test_video_core_lcd_display(video_core_lcd_display *lcd_obj){
    /*
    @brief  : to test video core: lcd displat
    @param  : lcd_obj - pointer to an instantiated class
    retval  : none
    What to Test:
        0. write/read clock setting;
        1. chip select and deselect;
        2. data-or-command signal;
        3. write strobe (WRX signal);
        4. read strobe (RDX signa);
  
    Test Method:
        1. use logic analyser;
    Test limitation: What could be tested;
        1. data is 8-bit but logic analyser could only accommodate 8 signals;
        2. read strobe (RDX) could be tested 
        (but the read data is meaningless without communicating with an actual device)
    */
   /* signal declare */
   int is_data;     // for DCX;
   uint8_t data;    // for write;
   int enable_cpu_control; // for stream control;
   
   // for clock counter setting;
    int wrx_l;
    int wrx_h;
    int rdx_l;
    int rdx_h;

   // stream control; cpu;
   // for non-cpu control; it requires different setup;
   enable_cpu_control = 1;
   lcd_obj->set_stream(enable_cpu_control);

   /* ----clock counter modulus; */
   // take note that logic analyser max sampling rate is 24MHz;
   // so, allows the these write/read clock cycles to be longer;
   
   // write;
   wrx_l = 10000;   // low period of 100us
   wrx_h = 9000;   // high period of  90us incl the ready signal
   
   // read;
   rdx_l = 20000;   // low period of 200us ;
   rdx_h = 30000;   // high period of 300us incl the ready signal
   
   lcd_obj->set_clockmod(wrx_l, wrx_h, rdx_l, rdx_h);
    
   /* ----test chip select */
   lcd_obj->enable_chip();
   delay_busy_ms(1);
   lcd_obj->disable_chip();
   delay_busy_ms(10);
   lcd_obj->enable_chip();
   delay_busy_ms(1);

   /* ----test write with command */
   for(int i = 0; i < 4; i++){
        is_data = 0; // it is a command;
        data = 0xAA; // 0b1010_1010;
        lcd_obj->write(is_data, data);
   }
    delay_busy_ms(1);

    /* ----test write with non-command */
    for(int i = 0; i < 4; i++){
        is_data = 1; // it is a data;
        data = 0x55; // 0b0101_0101;
        lcd_obj->write(is_data, data);
        
    }
    delay_busy_ms(1);

   /* ----test read */
   for(int i = 0; i < 4; i++){
      lcd_obj->read();        
    }
    delay_busy_ms(1);
}   


void test_HW_reset_pins(void){
    /*---------------------------------
    * HW Reset Pins controlled via SW;
    * all reset pins use GPIO core;
    * up to the SW to configure the core
    * for individiual pin;
    ---------------------------------*/

    // camera ov7670;
    // PIN @ JA04;
    ov7670_hw_reset();
    
    // lcd ili9341;
    // PIN @ JD07;
    lcd_ili9341_hw_reset();

    delay_busy_ms(10);
}