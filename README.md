# Toy SoC

This is a toy SoC prototype with video streaming as the main application.

**Documentation:**
The documentation is linked here <?>. This documents the memory organization, register map, register definition, construction, test results etc. This README is excerpted from this documentation.

**Environment**
??

**Navigation**
??

## Table of Contents

1. [Objective](#objective)
2. [SoC Design Flow](#soc-design-flow)
3. [Project Status: Milestone + Demonstration](#project-status-milestone--demonstration)
    1. [Device Resource Utilization](#device-resource-utilization)
    2. [Design Timing Summary](#design-timing-summary)
4. [External Devices](#external-devices)
5. [Acknowledgement](#acknowledgement)
6. [Reference](#reference)

## Objective

To gain a fundamental SoC design knowledge by kickstarting a prototype. The primary goal is to build the necessary IO peripherals, mainly around the IP-generated CPU: MicroBlaze Micro Controller System (MCS) to enable a video streaming from a camera to an LCD display. This is shown in Figure ??. The secondary goal is to implement a HW motion detection algorithm on top on the video system. This is shown in Figure ??

?? insert diagram ??

## SoC Design Flow

Given a specification, a partition is done between HW and SW. The HW design and SW design methodologies follow closely these tutorials: [0] Vivado Design Suite Tutorial and [1] Vitis Software Development Workflow, respectively. That said, the workflow is slightly modified due to different developing environments. The actual workflow  is shown in Figure ??.

?? insert diagram ??

## Target

1. MMIO System: IO Peripherals to communicate with the external devices
2. Video System: Video streaming from a camera to a LCD
3. Application System: Motion Detection Algorithm HW Implementation

## Project Status: Milestone + Demonstration

Updated: June 03, 2023

### Device Resource Utilization

Updated: June 03, 2023

| **Resource**  | **Utilization**   | **Available**     | **%** |
|--             |--                 |--                 |--     |
| LUT           | 4751              | 32600             | 14.57 |
| LUTRAM        | 680               | 9600              | 7.08  |
| FF            | 4212              | 65200             | 6.46  |
| BRAM          | 33                | 75                | 44.00 |
| IO            | 110               | 210               | 52.38 |
| BUFG          | 6                 | 32                | 18.75 |
| MMCM          | 2                 | 5                 | 40.00 |
| PLL           | 1                 | 5                 | 20.00 |

### Design Timing Summary

Updated: June 03, 2023

?? insert image ??


## External Devices

| **External Devices**  | **Description** |
|--                     |-- |
| LCD                   | Adafruit – 2.8” TFT LCD with Touchscreen Breakout Board with MicroSD Socket – ILI9341   |
| Camera                | VGA OV7670 Camera Module i2C 640x480   |
| External Memory       | DDR2 SDRAM (Micron: MT47H64M16HR-25E) |
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
- [x] Video Streaming System integrating the camera and the LCD
- [x] Colour format conversion
- [x] Configure IP-generated memory interface (MIG) with the external DDR2 SDRAM.
- [x] Add a synchronous interface user logic for the MIG.
- [ ] Implement a known motion detection algorithm.
- [ ] Add a debouncer module for the HW CPU Reset Button.
- [ ] Optimization (performance, area)

### Application

- [x] Test SW Function for each core.
- [x] IP generate Clock management circuit
- [x] IP generate DDR memory interface for Frame Buffers?
- [x] Camera OV7670 via i2C interface
- [x] LCD ILI9341 Configuration Interface

## Extra (Nice to have)

- [ ] Add interrupt system and incorporate into the IO cores. To consider using IP or user-defined.

