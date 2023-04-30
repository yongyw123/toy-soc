
#include "device_directive.h"


// global definition;
// gpio core is mainly for HW reset pin for the external devices;
core_gpio obj_gpio(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));

/*---------------------------
* instantiate the video core
* lcd controller;
--------------------------*/
video_core_lcd_display obj_lcd_controller(GET_VIDEO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, V0_DISP_LCD));
