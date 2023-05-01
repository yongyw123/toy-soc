#include "video_core_lcd_display.h"

video_core_lcd_display::video_core_lcd_display(uint32_t core_base_addr){
	/*
	@brief  : constructor to instantiate an object of class: video_core_lcd_display()
	@param  : core_base_addr
				- the base address of this video core resides
					on the microblaze IO bus address;
	@retval : none
	 */

   base_addr = core_base_addr;

   /* wrx, rdx timing;
   read the lcd specs;

   brief definition;
   the host updates its data to send at high-to-low of WRX;
   the lcd samples this data at the low-to-high of WRX;
   this defines two periods;
   low period;
   high period;

   low period: how long should the WRX spend in this low period;
   high period: how long should the WRX spend in this high period;
   
   the data also has to hold until the high period;

   for rdx; it is similar;
   
   */

  // for configuring;
  // can afford to have longer write time;
  // but when streaming; shall have shorted time;
  // following is defaulted to configuring;
   /* not ok
   wrx_l = 4;   // this corresponds to 50 ns;
   wrx_h = 3;   // this corresponds to 50 ns (including the done flag);
   */


   /* ok
   wrx_l = 10;   // this corresponds to 30 ns;
   wrx_h = 10;   // this corresponds to 40 ns (including the done flag);
	*/

   /* ok;
   wrx_l = 9;
   wrx_h = 9;
	*/

   /* ok
   wrx_l = 7;
   wrx_h = 7;
	*/

   /* ok;
   wrx_l = 6;
   wrx_h = 6;
	*/

   /* not ok
   wrx_l = 5;
   wrx_h = 4;
	*/

   /* not ok
   wrx_l = 5;
   wrx_h = 5;
   */

   /* not ok
   wrx_l = 6;
   wrx_h = 5;
   */

   /* not ok;
   wrx_l = 5;
   wrx_h = 6;
	*/

   wrx_l = 6;
   wrx_h = 6;


   // read is usually longer;
   rdx_l = 9;   // 100 ns;
   rdx_h = 39;  // 400 ns;
   set_clockmod(wrx_l, wrx_h, rdx_l, rdx_h);

	/* stream control

	// when configuring; it has to be the cpu that 
	// has the control over the lcd interface;
	// once done; it will be handed over to other video cores;
	// under this; it is all about writing pixels to the lcd;
	*/
   cpu_control = 1; // cpu has the control;
   set_stream(cpu_control);

}

// destructor; not used;
video_core_lcd_display::~video_core_lcd_display(){};

void video_core_lcd_display::set_clockmod(int usr_wrx_l, int usr_wrx_h, int usr_rdx_l, int usr_rdx_h){
	/*
	@brief  : setting the WRX and RDX period by setting the respective counter modulus;
	@param  :
		user_wrx_l  : how long should the WRX be LOW;
		user_wrx_h  : how long should the WRX be HIGH;
		user_rdx_l  : how long should the RDX be LOW;
		user_rdx_h  : how long should the RDX be HIGH;
	@retval : none
	*/

	// var declare;
   uint32_t set_wrx;
   uint32_t set_rdx;

   // update the private var;
	wrx_l = usr_wrx_l;
	wrx_h = usr_wrx_h;
	rdx_l = usr_rdx_l;
	rdx_h = usr_rdx_h;

	// setting up;
	set_wrx = (uint32_t)(usr_wrx_l | ((uint32_t)usr_wrx_h << BIT_POS_REG_CLKMOD_SHALF));
	set_rdx = (uint32_t)(usr_rdx_l | ((uint32_t)usr_rdx_h << BIT_POS_REG_CLKMOD_SHALF));

	// write them into the registers;
	REG_WRITE(base_addr, REG_CLOCKMOD_WR_OFFSET , set_wrx);
	REG_WRITE(base_addr, REG_CLOCKMOD_RD_OFFSET , set_rdx);

}

void video_core_lcd_display::set_stream(int set_cpu_control){
	/*
	@brief  : to set the stream control;
	@note   : this means that which system is driving the lcd interface?
				the cpu (processor) 
				or other video cores (such as pixel generation)
	@param  : set_cpu_control 
				1: cpu takes over;
				0: otherwise;
	@retval : none
	*/
   
   // unfortunately; the HW register uses the other way around;
   // low for cpu control;
   uint32_t wr = (uint32_t)(0x01);  // non-cpu control;
   if(set_cpu_control){
	wr = (uint32_t)0x00;
   }
   
   // update the private var;
   cpu_control = set_cpu_control;

   // update the register;
   REG_WRITE(base_addr, REG_STREAM_CTRL_OFFSET, wr);
}

void video_core_lcd_display::set_cpu_stream(void){
	/*
	@brief	: hand the control to the cpu for LCD display;
	@param	: none
	@retval	: none
	*/
	set_stream(ENABLE_CPU_CTRL);

}

void video_core_lcd_display::set_video_stream(void){
	/*
	@brief	: hand the control to the HW video core for the LCD display;
	@param	: none
	@retval	: none
	*/
	set_stream(DISABLE_CPU_CTRL);

}

int video_core_lcd_display::is_ready(void){
	/*
	@brief  : check whether the lcd display controller is ready/idle;
	@param  : none;
	@retval : 1 if ready; 0 otherwise;
	*/

   uint32_t rd_data;
   rd_data = REG_READ(base_addr, REG_RD_DATA_OFFSET);
   return (int)((rd_data & MASK_REG_RD_DATA_STATUS_READY) >> BIT_POS_REG_RD_DATA_STATUS_READY);
}


void video_core_lcd_display::enable_chip(void){
	/*
	@brief  : assert CS (active low) to enable the LCD;
	@param  : none;
	@retval : none
	*/
	uint32_t wr = (uint32_t)0x01;
   REG_WRITE(base_addr, REG_CSX_OFFSET, wr);

}

void video_core_lcd_display::disable_chip(void){
	/*
	@brief  : deassert the CS (active low) to the disable the LCD chip
	@param  : none;
	@retval : none
	*/

   uint32_t wr = (uint32_t)0x00;
   REG_WRITE(base_addr, REG_CSX_OFFSET, wr);

}

void video_core_lcd_display::assert_command_mode(void){
	/*
	@brief	: set the DCX line to command mode (LOW);
	@param	: none;
	@retval	: none;
	*/

	uint32_t wr = (uint32_t)0x01;
	REG_WRITE(base_addr, REG_DCX_OFFSET, wr);
}

void video_core_lcd_display::deassert_command_mode(void){
	/*
	@brief	: set the DCX line to data mode (HIGH);
	@param	: none;
	@retval	: none;
	*/

	uint32_t wr = (uint32_t)0x00;
	REG_WRITE(base_addr, REG_DCX_OFFSET, wr);
}

void video_core_lcd_display::write(int is_data, uint8_t data){
	/*
	@brief  : Host transfers to the LCD
	@param  :
			is_data: how should the LCD interpret the host data?
					1 for data;
					0 for command
			data    : the data to transfer
	@retval : none
	@note   : this is a blocking method;
	*/

	// var declare;
   	uint32_t wr;

	// set the DCX line according to user argument;
	if(is_data){
		deassert_command_mode();
	}else{
		assert_command_mode();
	}
	// packing;
	wr = (uint32_t)(CMD_WR | (uint32_t)data);

	// block until the lcd interface controller is ready;
	while(!is_ready()){};

	// update the register;
	REG_WRITE(base_addr, REG_WR_DATA_OFFSET, wr);

	// due to limitation;
	// need to issue a NOP command after a clock cyle;
	// otherwise, the controller will keep on writing;
	// careful not to override other setting;
	wr = (uint32_t)(CMD_NOP | (uint32_t)data);
	REG_WRITE(base_addr, REG_WR_DATA_OFFSET, wr);
	
}


uint8_t video_core_lcd_display::read(void){
	/* 
	@brief  : read a byte from the lcd;
	@param  : none;
	@retval : none;
	@note   : this is a blocking method;
	*/

	// signal declaration;
	uint32_t req_rd;    // for issuing a read request;
	uint32_t rd_data;   // after reading from the lcd;

	// set the DCX line to data-mode;
	// this is by the lcd specs;
	// during reading; DCX must always be HIGH;
	deassert_command_mode();

	// insert some delay here if needed;
	// depends on the specs;

	// issue a read command;
	uint32_t dummy_data = (uint32_t)0x00;
	req_rd = (uint32_t)(CMD_RD | dummy_data);

	// update the reg;
	REG_WRITE(base_addr, REG_WR_DATA_OFFSET, req_rd);

	// due to limitation;
	// need to issue a NOP command after a clock cyle;
	// otherwise, the controller will keep on 
	// signalling to the lcd that it wants to read;
	// careful not to override other setting;
	req_rd = (uint32_t)(CMD_NOP | dummy_data);
	REG_WRITE(base_addr, REG_WR_DATA_OFFSET, req_rd);

	// block until the lcd is ready;
	while(!is_ready()){};

	// read;
	rd_data = REG_READ(base_addr, REG_RD_DATA_OFFSET);
	return (uint8_t)(rd_data & 0xFF);

}


void video_core_lcd_display::write_data(uint8_t data){
	/* 
	@brief	: write data to the LCD in data-mode (DCX);
	@param	: 8-bit data to write
	@retval	: none
	@none	: this method is just a wrapper for write();

	*/
	write(1, data);

}             
	
void video_core_lcd_display::write_command(uint8_t reg_command){
	/* 
	@brief	: write data to the LCD in command-mode (DCX);
	@param	: reg_command - which command to issue to the LCD?
	@retval	: none
	@none	: this method is just a wrapper for write();

	*/
	write(0, reg_command);

}   
