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
- [ ] Digital Camera Interface (DCMI)
- [ ] Video Streaming System integrating the camera and the LCD.
- [ ] Some basic DSP block?
- [ ] HW accelerator for (undetermined) image algorithm

### Application

- [ ] Test SW Function for each IO cores
- [ ] IP generate FIFO dual clock
- [x] IP generate Clock management circuit
- [ ] IP generate SDRAM memory interface for Frame Buffers
- [x] Camera OV7670 via i2C interface
- [x] LCD ILI9341 Configuration Interface

## Extra (Nice to have)

### General 

- [ ] Add interrupt system and incorporate into the IO cores. To consider using IP or user-defined.

### System Timer

- [ ] Include extra control register to configure counter count range instead of using the full-64-bit range.
- [ ] Include prescaler control to set the count frequency. *Not sure if it is a good idea.*
- [ ] Include extra status register for System Timer to indicate whether the counter expires (overflow), and how many time it has expired, and the associated set/clear status register operations.
