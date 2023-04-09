# fpga-system-verilog-learning


## Task List

### IO Core (inc SW drivers)

- [x] General Purpose Output (GPO)
- [x] General Purpose Input (GPI)
- [ ] System Timer
- [ ] GPIO core as a single entity
- [ ] UART interface for debugging purpose
- [ ] SPI interface
- [ ] i2C interface
- [ ] Digital Camera Interface (DCMI)
- [ ] HW accelator for (undetermined) image algorithm

### Application

- [ ] Test SW Function for each IO cores
- [ ] IP FIFO dual clock
- [ ] IP Clock management circuit
- [ ] IP SDRAM memory interface for Frame Buffers
- [ ] Camera OV7670 via i2C interface
- [ ] LCD-TFT control via SPI interface

## Extra (Nice to have)

### General 
- [ ] Add interrupt system and incorporate into the IO cores. To consider using IP or user-defined.

### System Timer

- [ ] Include extra control register to configure counter count range instead of using the full-64-bit range.
- [ ] Include prescaler control to set the count frequency. *Not sure if it is a good idea.*
- [ ] Include extra status register for System Timer to indicate whether the counter expires (overflow), and how many time it has expired, and the associated set/clear status register operations.
