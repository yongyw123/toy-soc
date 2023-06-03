# Toy SoC

This is a toy SoC prototype with video streaming as the main application.

**Documentation:**
The documentation is linked here <?>. This documents the memory organization, register map, register definition, construction, test results etc. This README is excerpted from this documentation.

**Navigation**
??

## Table of Contents

1. [Objective](#objective)
2. [SoC Design Flow](#soc-design-flow)
3. [Milestone + Demonstration](#milestone--demonstration)
    1. [Device Resource Utilization](#device-resource-utilization)
    2. [Design Timing Summary](#design-timing-summary)
4. [Environment](#environment)
5. [External Devices](#external-devices)
6. [Acknowledgement](#acknowledgement)
7. [Reference](#reference)

## Objective

To gain a fundamental SoC design knowledge by kickstarting a prototype. The primary goal is to build the necessary IO peripherals, mainly around the IP-generated CPU: MicroBlaze Micro Controller System (MCS) to enable a video streaming from a camera to an LCD display. This is shown in Figure ??. The secondary goal is to implement a HW motion detection algorithm on top on the video system. This is shown in Figure ??

?? insert diagram ??

## SoC Design Flow

Given a specification, a partition is done between HW and SW. The HW design and SW design methodologies follow closely these tutorials: [0] Vivado Design Suite Tutorial and [1] Vitis Software Development Workflow, respectively. That said, the workflow is slightly modified due to different developing environments. The actual workflow  is shown in Figure ??.

?? insert diagram ??

## Target

1. MMIO System: IO Peripherals to communicate with the external devices.
2. Video System: Video streaming from the camera to the LCD.
3. Application System: Motion Detection Algorithm HW Implementation

## Milestone + Demonstration

Updated: June 03, 2023

### Device Resource Utilization

Updated: June 03, 2023

### Design Timing Summary

Updated: June 03, 2023

## Environment

## External Devices


## Acknowledgement

This project is born out of the attempts at the exercises for [??], [??], [??]. The verification technique  employed is from [?].

## Reference

??

---

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
- [x] Colour format conversion
- [x] Configure IP-generated memory interface (MIG) with the external SDRAM
- [x] Add a SDRAM interface user logic for the MIG
- [ ] Implement a known motion detection algorithm.
- [ ] Add a debouncer module for the HW CPU Reset Button.
- [ ] Optimization (performance, area)

### Application

- [ ] Test SW Function for each IO cores
- [x] IP generate Clock management circuit
- [x] IP generate DDR memory interface for Frame Buffers?
- [x] Camera OV7670 via i2C interface
- [x] LCD ILI9341 Configuration Interface

## Extra (Nice to have)

### General 

- [ ] Add interrupt system and incorporate into the IO cores. To consider using IP or user-defined.

### System Timer

- [ ] Include extra control register to configure counter count range instead of using the full-64-bit range.
- [ ] Include prescaler control to set the count frequency. *Not sure if it is a good idea.*
- [ ] Include extra status register for System Timer to indicate whether the counter expires (overflow), and how many time it has expired, and the associated set/clear status register operations.
