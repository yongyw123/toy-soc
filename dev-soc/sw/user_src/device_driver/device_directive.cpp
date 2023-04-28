
#include "device_directive.h"


// global definition;
// gpio core is mainly for HW reset pin for the external devices;
core_gpio obj_gpio(GET_MMIO_CORE_ADDR(BUS_MICROBLAZE_IO_BASE_ADDR_G, S4_GPIO_PORT));