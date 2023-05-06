# Toy SoC


## Task List

### Construction of Basic IO Core (inc SW drivers)

- [x] General Purpose Output (GPO)
- [x] General Purpose Input (GPI)
- [x] System Timer
- [x] General Purpose Input Output (GPIO) as HW Pins for external devices
- [x] UART interface for debugging purpose
- [x] SPI interface to control LCD ILI9341
- [x] i2C interface to control Camera OV7670
- [x] LCD Display Parallel Interface
- [x] Pixel Test HW generation for LCD Display
- [x] Digital Camera Interface (DCMI)
- [x] Video Streaming System integrating the camera and the LCD.
- [ ] Some basic DSP blocks for colour format conversion?
- [ ] HW accelerator for (undetermined) image algorithm: DCT?

### Application

- [ ] Test SW Function for each IO cores
- [x] IP generate Clock management circuit
- [ ] IP generate DDRAM memory interface for Frame Buffers?
- [x] Camera OV7670 via i2C interface
- [x] LCD ILI9341 Configuration Interface

## Extra (Nice to have)

### General 

- [ ] Add interrupt system and incorporate into the IO cores. To consider using IP or user-defined.

### System Timer

- [ ] Include extra control register to configure counter count range instead of using the full-64-bit range.
- [ ] Include prescaler control to set the count frequency. *Not sure if it is a good idea.*
- [ ] Include extra status register for System Timer to indicate whether the counter expires (overflow), and how many time it has expired, and the associated set/clear status register operations.
