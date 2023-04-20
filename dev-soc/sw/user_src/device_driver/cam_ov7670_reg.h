#ifndef _CAM_OV7670_REG_H
#define _CAM_OV7670_REG_H

#include "io_reg_util.h"
#include "io_map.h"
#include "user_util.h"
#include "core_gpio.h"
#include "core_timer.h"
#include "core_spi.h"
#include "core_i2c_master.h"
#include "main.h"

/* ------------------------------------------------
*  This header file lists down the following:
*  1. the OV7670 camera master address
*  2. OV7670 specs;
*  3. bit masking fields;
*  3. OV7670 camera i2C control register addresses; 
--------------------------------------------------*/

// c and cpp linkage;
// reference: https://igl.ethz.ch/teaching/tau/resources/cprog.htm
#ifdef __cpluscplus
extern "C" {
#endif

/* ------------------------------------------------
 * OV7670 Device ID
 ------------------------------------------------*/
// if left shifted one-bit plus R/W bit, this translates to 0x42 for write and 0x43 for read;
#define OV7670_DEV_ID   0x21 

/* -----------------------------------------------
 * MASKING AND SETTING OV7670 CONTROL REGISTERS
 * 1. This provides BIT MASK for certain control register;
 * 2. This provides certain register values;
 -----------------------------------------------*/
//> PLL control register at address 0x6B;
#define USER_OV7670_DBLV_PLL_MASK 	0b11000000	// MSB 2 bits to control PLL factor;
#define USER_OV7670_DBLV_PLL_0F 	0b00000000	// bypass PLL (not using it);
#define USER_OV7670_DBLV_PLL_4F 	0b01000000	// PLL times the input clock by a factor of 4;
#define USER_OV7670_DBLV_PLL_6F 	0b10000000	// PLL times the input clock by a factor of 6;
#define USER_OV7670_DBLV_PLL_8F 	0b11000000	// PLL times the input clock by a factor of 8;

//> clock prescaler register at address 0x11;
// formula: pixel_clock_out = system_clock_input/(PRESCALER + 1);
// prescaler range value: 00_000 to 11_111; but shall create somme predefined odd factor;
// odd factor is chosen because there is already an offset of 1; (this ensures the divider is an even number);
#define USER_OV7670_CLKRC_PRESCALER_MASK 	0b00111111	// LSB 6 bits for prescaler; range: 00_000 to 11_111
#define USER_OV7670_CLKRC_PRESCALER_0F	 	0x00		// not scaling; zero;
#define USER_OV7670_CLKRC_PRESCALER_1F 		0x01		// divide by 2;
#define USER_OV7670_CLKRC_PRESCALER_3F 		0x03		// divide by 4;
#define USER_OV7670_CLKRC_PRESCALER_5F 		0x05		// divide by 6;
#define USER_OV7670_CLKRC_PRESCALER_7F 		0x07		// divide by 8;
#define USER_OV7670_CLKRC_PRESCALER_15F 	0x0F		// divide by 16;

//> pixel output format
#define USER_OV7670_COM7_OUTPUT_FORMAT_MASK 			0b00000101	// which output format: RGB565 or YUV422 etc?
#define USER_OV7670_COM7_OUTPUT_FORMAT_RGB565_ENABLE	0b00000100	// set to use RGB565 at COM7 register;
#define USER_OV7670_COM7_OUTPUT_FORMAT_YUV_ENABLE 		0b00000000	// set to use RGB565 at COM7 register;
#define USER_OV7670_COM15_RGB565_OPTION_MASK 			0b00110000	//COM15 sets RGB option using bit[5:4]
#define USER_OV7670_COM15_RGB565_OPTION_ENABLE 			0b00010000	// set to use RGB565 at COM15 register;
#define USER_OV7670_COM15_RGB565_OPTION_DISABLE 		0b00000000	// to use YUV, this option must be disabled;

//> pixel output range;
#define USER_OV7670_COM15_OUTPUT_RANGE_MASK 		0b11000000 // output range of RGB565; use all 16 bits? 00 to FF?
#define USER_OV7670_COM15_OUTPUT_RANGE_FULL_SET 	0b11000000 // use full output range of RGB565; 00 to FF;

//> QVGA resolution (size: 320 x 240);
#define USER_OV7670_COM7_QVGA_MASK 	    0b00010000	// COM 7 register sets the QVGA resolution at bit 4;
#define USER_OV7670_COM7_QVGA_ENABLE 	0b00010000	// set to use QVGA pre-defined resolution;
#define USER_OV7670_COM7_QVGA_DISABLE 	0b00000000	// do not use QVGA pre-defined resolution;

//> COM 10 for synchronization signal settings of interest;
// mask;
#define USER_OV7670_COM10_HSYNC_POLARITY_MASK 	0b00000001 	// HSYNC: active high or active low?
#define USER_OV7670_COM10_VSYNC_POLARITY_MASK	0b00000010 	// VSYNC: active high or active low?
#define USER_OV7670_COM10_VSYNC_UPDATE_MASK		0b00000100 	// VSYNC: update at the falling or rising edge of the pixel clock?
#define USER_OV7670_COM10_PCLK_UPDATE_MASK		0b00010000 	// PIXEL CLOCK: data update at falling or rising edge?
#define USER_OV7670_COM10_PCLK_OUTPUT_MASK 		0b00100000	// PIXEL CLOCK: free running or pause during idle?
#define USER_OV7670_COM10_HREF_OR_HSYNC_MASK	0b01000000	// Use HREF or HSYNC?

// set according to the application;
#define USER_OV7670_COM10_HSYNC_POLARITY_ACTIVE_LOW_SET 	0b00000001 	// HSYNC active low;
#define USER_OV7670_COM10_HSYNC_POLARITY_ACTIVE_HIGH_SET	0b00000000 	// HSYNC active high;
#define USER_OV7670_COM10_VSYNC_POLARITY_ACTIVE_LOW_SET 	0b00000000 	// VSYNC active low;
#define USER_OV7670_COM10_VSYNC_POLARITY_ACTIVE_HIGH_SET 	0b00000010 	// VSYNC active high;
#define USER_OV7670_COM10_VSYNC_UPDATE_RISING_SET			0b00000100	// VSYNC: update at the falling or rising edge of the pixel clock?
#define USER_OV7670_COM10_PCLK_UPDATE_RISING_SET			0b00010000 	// PIXEL CLOCK: data update at rising edge
#define USER_OV7670_COM10_PCLK_OUTPUT_FREE_SET 				0b00000000	// PIXEL CLOCK: free running
#define USER_OV7670_COM10_HSYNC_SET							0b01000000	// use HSYNCS instead of HREF;

//> COM12 for HSYNC/HREF presence during VSYNC IDLE?
// two options: (1) free running or (2) no output during VSYNC Active Level (IDLE);
// note that HREF == HSYNC under most circumstances;
#define OV7670_COM12_HREF_MASK 	        0b10000000	// as per above;
#define OV7670_COM12_HREF_DISABLE_SET 	0b00000000	// no HREF during VSYNC idle;
#define OV7670_COM12_HREF_ENABLE_SET 	0b10000000	// HREF during VSYNC idle;

//> test pattern generator
// note that this is not for DSP;
// test_pattern[1:0] is 2-bit set up by two different registers;
#define OV7670_SCALING_XSC_TEST_PATTERN_LOWER_MASK 	0b10000000	// test_pattern[0]
#define OV7670_SCALING_YSC_TEST_PATTERN_UPPER_MASK 	0b10000000  // test_pattern[1]

#define OV7670_TEST_PATTERN_NONE 				0	// no test pattern; actual capture;
#define OV7670_TEST_PATTERN_SHIFTING 			1	// single pixel wide vertical RGB stripes;
#define OV7670_TEST_PATTERN_COLOUR_BAR 			2	// 8-bar colour bar;
#define OV7670_TEST_PATTERN_COLOUR_BAR_FADING 	3	// 8-bar colour bar with fading;

//> auto windowing setting;
#define OV7670_TSLB_AUTO_WINDOW_MASK 	    0b00000001	// to control auto output window after resolution changes;
#define OV7670_TSLB_AUTO_WINDOW_SET_DISABLE 0b00000000	// disable auto output window;
#define OV7670_TSLB_AUTO_WINDOW_ENABLE 	    0b00000001	// enable auto output window;

//> DCW and Scaling feature at COM3 register;
#define OV7670_COM3_SCALE_MASK 		0b00001000	// scale enabled or disabled?
#define OV7670_COM3_DCW_MASK 		0b00000100	// DCW enabled or disabled?
#define OV7670_COM3_SCALE_ENABLE 	0b00001000	// enable scaling;
#define OV7670_COM3_DCW_ENABLE 		0b00000100	// enable DCW;

//> scaling factor for vertical and horizontal
#define OV7670_SCALING_XSC_SCALE_FACTOR_MASK 0b01111111	// bit mask for scale factor;
#define OV7670_SCALING_YSC_SCALE_FACTOR_MASK 0b01111111	// bit mask for scale factor;

//> VREF frame control bit masking;
#define OV7670_VREF_MASK	0b00001111	// Only the 4 LSB bits are for VREF, the rest are for the other settings;

/* ---------------------------------------------
 * OV7670 Device Control Register Address;
 ---------------------------------------------*/
/* device register address */
// ID (read only);
#define OV7670_REG_PID  0x0A		// Product ID Number MSB (Expect 0x76)
#define OV7670_REG_VER  0x0B		// Product ID Number LSB (Expect 0x73)
#define OV7670_REG_MIDH 0x1C	// manufacture ID byte HIGH;
#define OV7670_REG_MIDH 0x1C	// manufacture ID byte HIGH;
#define OV7670_REG_MIDL 0x1D	// manufacture ID byte LOW;

// control param (read or write);
#define OV7670_REG_GAIN 0x00				// AGC gain control gain setting;
#define OV7670_REG_BLUE 0x01				// AWB - Blue channel gain setting;
#define OV7670_REG_RED 0x02					// AWB - Red channel gain setting;
#define OV7670_REG_VREF 0x03				// Vertical Frame Control;
#define OV7670_REG_GFIX 0x69				// Fix Gain Control;
#define OV7670_REG_COM1 0x04               // Common control 1
#define OV7670_COM1_R656 0x40              // COM1 enable R656 format
#define OV7670_REG_BAVE 0x05               // U/B average level
#define OV7670_REG_GbAVE 0x06              // Y/Gb average level
#define OV7670_REG_AECHH 0x07              // Exposure value - AEC 15:10 bits
#define OV7670_REG_RAVE 0x08               // V/R average level
#define OV7670_REG_COM2 0x09               // Common control 2
#define OV7670_COM2_SSLEEP 0x10            // COM2 soft sleep mode
#define OV7670_REG_PID 0x0A                // Product ID MSB (read-only)
#define OV7670_REG_VER 0x0B                // Product ID LSB (read-only)
#define OV7670_REG_COM3 0x0C               // Common control 3
#define OV7670_COM3_SWAP 0x40              // COM3 output data MSB/LSB swap
#define OV7670_COM3_SCALEEN 0x08           // COM3 scale enable
#define OV7670_COM3_DCWEN 0x04             // COM3 DCW enable
#define OV7670_REG_COM4 0x0D               // Common control 4
#define OV7670_REG_COM5 0x0E               // Common control 5
#define OV7670_REG_COM6 0x0F               // Common control 6
#define OV7670_REG_AECH 0x10               // Exposure value 9:2
#define OV7670_REG_CLKRC 0x11              // Internal clock
#define OV7670_CLK_EXT 0x40                // CLKRC Use ext clock directly
#define OV7670_CLK_SCALE 0x3F              // CLKRC Int clock prescale mask
#define OV7670_REG_COM7 0x12               // Common control 7
#define OV7670_COM7_SOFT_RESET 0x80        // COM7 SCCB register reset
#define OV7670_COM7_SIZE_MASK 0x38         // COM7 output size mask
#define OV7670_COM7_PIXEL_MASK 0x05        // COM7 output pixel format mask
#define OV7670_COM7_SIZE_VGA 0x00          // COM7 output size VGA
#define OV7670_COM7_SIZE_CIF 0x20          // COM7 output size CIF
#define OV7670_COM7_SIZE_QVGA 0x10         // COM7 output size QVGA
#define OV7670_COM7_SIZE_QCIF 0x08         // COM7 output size QCIF
#define OV7670_COM7_RGB 0x04               // COM7 pixel format RGB
#define OV7670_COM7_YUV 0x00               // COM7 pixel format YUV
#define OV7670_COM7_BAYER 0x01             // COM7 pixel format Bayer RAW
#define OV7670_COM7_PBAYER 0x05            // COM7 pixel fmt proc Bayer RAW
#define OV7670_COM7_COLORBAR 0x02          // COM7 color bar enable
#define OV7670_REG_COM8 0x13               // Common control 8
#define OV7670_COM8_FASTAEC 0x80           // COM8 Enable fast AGC/AEC algo,
#define OV7670_COM8_AECSTEP 0x40           // COM8 AEC step size unlimited
#define OV7670_COM8_BANDING 0x20           // COM8 Banding filter enable
#define OV7670_COM8_AGC 0x04               // COM8 AGC (auto gain) enable
#define OV7670_COM8_AWB 0x02               // COM8 AWB (auto white balance)
#define OV7670_COM8_AEC 0x01               // COM8 AEC (auto exposure) enable
#define OV7670_REG_COM9 0x14               // Common control 9 - max AGC value
#define OV7670_REG_COM10 0x15              // Common control 10
#define OV7670_COM10_HSYNC 0x40            // COM10 HREF changes to HSYNC
#define OV7670_COM10_PCLK_HB 0x20          // COM10 Suppress PCLK on hblank
#define OV7670_COM10_HREF_REV 0x08         // COM10 HREF reverse
#define OV7670_COM10_VS_EDGE 0x04          // COM10 VSYNC chg on PCLK rising
#define OV7670_COM10_VS_NEG 0x02           // COM10 VSYNC negative
#define OV7670_COM10_HS_NEG 0x01           // COM10 HSYNC negative
#define OV7670_REG_HSTART 0x17             // Horiz frame start high bits
#define OV7670_REG_HSTOP 0x18              // Horiz frame end high bits
#define OV7670_REG_VSTART 0x19             // Vert frame start high bits
#define OV7670_REG_VSTOP 0x1A              // Vert frame end high bits
#define OV7670_REG_PSHFT 0x1B              // Pixel delay select
#define OV7670_REG_MIDH 0x1C               // Manufacturer ID high byte
#define OV7670_REG_MIDL 0x1D               // Manufacturer ID low byte
#define OV7670_REG_MVFP 0x1E               // Mirror / vert-flip enable
#define OV7670_MVFP_MIRROR 0x20            // MVFP Mirror image
#define OV7670_MVFP_VFLIP 0x10             // MVFP Vertical flip
#define OV7670_REG_LAEC 0x1F               // Reserved
#define OV7670_REG_ADCCTR0 0x20            // ADC control
#define OV7670_REG_ADCCTR1 0x21            // Reserved
#define OV7670_REG_ADCCTR2 0x22            // Reserved
#define OV7670_REG_ADCCTR3 0x23            // Reserved
#define OV7670_REG_AEW 0x24                // AGC/AEC upper limit
#define OV7670_REG_AEB 0x25                // AGC/AEC lower limit
#define OV7670_REG_VPT 0x26                // AGC/AEC fast mode op region
#define OV7670_REG_BBIAS 0x27              // B channel signal output bias
#define OV7670_REG_GbBIAS 0x28             // Gb channel signal output bias
#define OV7670_REG_EXHCH 0x2A              // Dummy pixel insert MSB
#define OV7670_REG_EXHCL 0x2B              // Dummy pixel insert LSB
#define OV7670_REG_RBIAS 0x2C              // R channel signal output bias
#define OV7670_REG_ADVFL 0x2D              // Insert dummy lines MSB
#define OV7670_REG_ADVFH 0x2E              // Insert dummy lines LSB
#define OV7670_REG_YAVE 0x2F               // Y/G channel average value
#define OV7670_REG_HSYST 0x30              // HSYNC rising edge delay
#define OV7670_REG_HSYEN 0x31              // HSYNC falling edge delay
#define OV7670_REG_HREF 0x32               // HREF control
#define OV7670_REG_CHLF 0x33               // Array current control
#define OV7670_REG_ARBLM 0x34              // Array ref control - reserved
#define OV7670_REG_ADC 0x37                // ADC control - reserved
#define OV7670_REG_ACOM 0x38               // ADC & analog common - reserved
#define OV7670_REG_OFON 0x39               // ADC offset control - reserved
#define OV7670_REG_TSLB 0x3A               // Line buffer test option
#define OV7670_TSLB_NEG 0x20               // TSLB Negative image enable
#define OV7670_TSLB_YLAST 0x04             // TSLB UYVY or VYUY, see COM13
#define OV7670_TSLB_AOW 0x01               // TSLB Auto output window
#define OV7670_REG_COM11 0x3B              // Common control 11
#define OV7670_COM11_NIGHT 0x80            // COM11 Night mode
#define OV7670_COM11_NMFR 0x60             // COM11 Night mode frame rate mask
#define OV7670_COM11_HZAUTO 0x10           // COM11 Auto detect 50/60 Hz
#define OV7670_COM11_BAND 0x08             // COM11 Banding filter val select
#define OV7670_COM11_EXP 0x02              // COM11 Exposure timing control
#define OV7670_REG_COM12 0x3C              // Common control 12
#define OV7670_COM12_HREF 0x80             // COM12 Always has HREF
#define OV7670_REG_COM13 0x3D              // Common control 13
#define OV7670_COM13_GAMMA 0x80            // COM13 Gamma enable
#define OV7670_COM13_UVSAT 0x40            // COM13 UV saturation auto adj
#define OV7670_COM13_UVSWAP 0x01           // COM13 UV swap, use w TSLB[3]
#define OV7670_REG_COM14 0x3E              // Common control 14
#define OV7670_COM14_DCWEN 0x10            // COM14 DCW & scaling PCLK enable
#define OV7670_REG_EDGE 0x3F               // Edge enhancement adjustment
#define OV7670_REG_COM15 0x40              // Common control 15
#define OV7670_COM15_RMASK 0xC0            // COM15 Output range mask
#define OV7670_COM15_R10F0 0x00            // COM15 Output range 10 to F0
#define OV7670_COM15_R01FE 0x80            // COM15              01 to FE
#define OV7670_COM15_R00FF 0xC0            // COM15              00 to FF
#define OV7670_COM15_RGBMASK 0x30          // COM15 RGB 555/565 option mask
#define OV7670_COM15_RGB 0x00              // COM15 Normal RGB out
#define OV7670_COM15_RGB565 0x10           // COM15 RGB 565 output
#define OV7670_COM15_RGB555 0x30           // COM15 RGB 555 output
#define OV7670_REG_COM16 0x41              // Common control 16
#define OV7670_COM16_AWBGAIN 0x08          // COM16 AWB gain enable
#define OV7670_REG_COM17 	0x42              // Common control 17
#define OV7670_COM17_AECWIN 0xC0           // COM17 AEC window must match COM4
#define OV7670_COM17_CBAR 	0x08             // COM17 DSP Color bar enable
#define OV7670_REG_AWBC1 	0x43              // Reserved
#define OV7670_REG_AWBC2 	0x44              // Reserved
#define OV7670_REG_AWBC3 	0x45              // Reserved
#define OV7670_REG_AWBC4 	0x46              // Reserved
#define OV7670_REG_AWBC5 	0x47              // Reserved
#define OV7670_REG_AWBC6 	0x48              // Reserved
#define OV7670_REG_AWBC7	0x59    		// AWB Control 7
#define OV7670_REG_AWBC8	0x5a    		// AWB Control 8
#define OV7670_REG_AWBC9 	0x5b    		// AWB Control 9
#define OV7670_REG_AWBC10	0x5c   			 // AWB Control 10
#define OV7670_REG_AWBC11	0x5d    		// AWB Control 11
#define OV7670_REG_AWBC12 	0x5e    		// AWB Control 12
#define OV7670_REG_REG4B 0x4B              // UV average enable
#define OV7670_REG_DNSTH 0x4C              // De-noise strength
#define OV7670_REG_MTX1 0x4F               // Matrix coefficient 1
#define OV7670_REG_MTX2 0x50               // Matrix coefficient 2
#define OV7670_REG_MTX3 0x51               // Matrix coefficient 3
#define OV7670_REG_MTX4 0x52               // Matrix coefficient 4
#define OV7670_REG_MTX5 0x53               // Matrix coefficient 5
#define OV7670_REG_MTX6 0x54               // Matrix coefficient 6
#define OV7670_REG_MTXS 0x58				// Matrix coeffiicent sign
#define OV7670_REG_BRIGHT 0x55             // Brightness control
#define OV7670_REG_CONTRAS 0x56            // Contrast control
#define OV7670_REG_CONTRAS_CENTER 0x57     // Contrast center
#define OV7670_REG_MTXS 0x58               // Matrix coefficient sign
#define OV7670_REG_LCC1 0x62               // Lens correction option 1
#define OV7670_REG_LCC2 0x63               // Lens correction option 2
#define OV7670_REG_LCC3 0x64               // Lens correction option 3
#define OV7670_REG_LCC4 0x65               // Lens correction option 4
#define OV7670_REG_LCC5 0x66               // Lens correction option 5
#define OV7670_REG_MANU 0x67               // Manual U value
#define OV7670_REG_MANV 0x68               // Manual V value
#define OV7670_REG_GFIX 0x69               // Fix gain control
#define OV7670_REG_GGAIN 0x6A              // G channel AWB gain
#define OV7670_REG_DBLV 0x6B               // PLL & regulator control
#define OV7670_REG_AWBCTR3 0x6C            // AWB control 3
#define OV7670_REG_AWBCTR2 0x6D            // AWB control 2
#define OV7670_REG_AWBCTR1 0x6E            // AWB control 1
#define OV7670_REG_AWBCTR0 0x6F            // AWB control 0
#define OV7670_REG_SCALING_XSC 0x70        // Vertical Scale Factor and Test pattern X scaling
#define OV7670_REG_SCALING_YSC 0x71        // Horizontal Scale Factor Test pattern Y scaling
#define OV7670_REG_SCALING_DCWCTR 0x72     // DCW control (down converter);
#define OV7670_REG_SCALING_PCLK_DIV 0x73   // DSP scale control clock divide
#define OV7670_REG_REG74 0x74              // Digital gain control
#define OV7670_REG_REG76 0x76              // Pixel correction
#define OV7670_REG_SLOP 0x7A               // Gamma curve highest seg slope
#define OV7670_REG_GAM_BASE 0x7B           // Gamma register base (1 of 15)
#define OV7670_GAM_LEN 15  CA              // Number of gamma registers
#define OV7670_R76_BLKPCOR 0x80            // REG76 black pixel corr enable
#define OV7670_R76_WHTPCOR 0x40            // REG76 white pixel corr enable
#define OV7670_REG_RGB444 0x8C             // RGB 444 control
#define OV7670_R444_ENABLE 0x02            // RGB444 enable
#define OV7670_R444_RGBX 0x01              // RGB444 word format
#define OV7670_REG_DM_LNL 0x92             // Dummy line LSB
#define OV7670_REG_LCC6 0x94               // Lens correction option 6
#define OV7670_REG_LCC7 0x95               // Lens correction option 7
#define OV7670_REG_HAECC1 0x9F             // Histogram-based AEC/AGC ctrl 1
#define OV7670_REG_HAECC2 0xA0             // Histogram-based AEC/AGC ctrl 2
#define OV7670_REG_SCALING_PCLK_DELAY 0xA2 // Scaling pixel clock delay
#define OV7670_REG_BD50MAX 0xA5            // 50 Hz banding step limit
#define OV7670_REG_HAECC3 0xA6             // Histogram-based AEC/AGC ctrl 3
#define OV7670_REG_HAECC4 0xA7             // Histogram-based AEC/AGC ctrl 4
#define OV7670_REG_HAECC5 0xA8             // Histogram-based AEC/AGC ctrl 5
#define OV7670_REG_HAECC6 0xA9             // Histogram-based AEC/AGC ctrl 6
#define OV7670_REG_HAECC7 0xAA             // Histogram-based AEC/AGC ctrl 7
#define OV7670_REG_BD60MAX 0xAB            // 60 Hz banding step limit
#define OV7670_REG_ABLC1 0xB1              // ABLC enable
#define OV7670_REG_THL_ST 0xB3             // ABLC target
#define OV7670_REG_SATCTR 0xC9             // Saturation control
#define OV7670_REG_LAST (OV7670_REG_SATCTR + 1) 	// define the register address boundary; as not to cross over;

// multiple reserved registers;
// not sure if these will ever be used; but listed for convenience;
#define OV7670_REG_RSVD_XA1 0xA1
#define OV7670_REG_RSVD_X16 0x16
#define OV7670_REG_RSVD_X29 0x29
#define OV7670_REG_RSVD_X35 0x35
#define OV7670_REG_RSVD_X0B 0x0B



#ifdef __cpluscplus
} // extern "C";
#endif


#endif // _CAM_OV7670_REG_H




