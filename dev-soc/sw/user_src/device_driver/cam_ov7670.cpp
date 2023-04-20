#include "cam_ov7670.h"



void ov7670_hw_reset(core_gpio *gpio_obj){
    gpio_obj->set_direction(OV7670_HW_RSTN_PIN_JA07, 1);
    gpio_obj->write(1, 0);


}