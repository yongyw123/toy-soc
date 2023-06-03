# Toy SoC

This is a toy System on Chip (SoC) prototype with video streaming as the main application.

**Documentation:**
The documentation is linked here <?>. This documents the memory organization, register map, register definition, construction, test results etc. This README is excerpted from this documentation.

| **Environment**           |                           |
|--                         |--                         |
| FPGA Development Board    | Digilent Nexys A7-50T     |
| FPGA Part Number          | XC7A50T-1CSG3241          |
| HW IDE                    | Vivado v2021.2            |
| HW Language               | SystemVerilog             |
| SW IDE                    | Vitis IDE v1.0.0.2021     |
| SW Language               | C++/C                     |

**Source File Navigation:**

1. HW: It follows Vivado Hierarchy (structure).
    1. Source File : ./dev-soc/hw/dev_soc/dev_soc.srcs/sources_1
    2. Simulation File : ./dev-soc/hw/dev_soc/dev_soc.srcs/sim_1
2. SW: ./dev-soc/sw/user_src/

## Table of Contents

1. [Objective](#objective)
2. [SoC Design Flow](#soc-design-flow)
3. [Target](#target)
4. [Project Status: Milestone + Demonstration](#project-status-milestone--demonstration)
    1. [Device Resource Utilization](#device-resource-utilization)
    2. [Design Timing Summary](#design-timing-summary)
5. [External Devices](#external-devices)
6. [Acknowledgement](#acknowledgement)
7. [Reference](#reference)

## Objective

To gain a fundamental SoC design knowledge by kickstarting a prototype. The primary goal is to build the necessary IO peripherals, mainly around the IP-generated CPU: MicroBlaze Micro Controller System (MCS) to enable a video streaming from a camera to an LCD display. This is shown in Figure 01. The secondary goal is to implement a HW motion detection algorithm on top on the video system. 

*Figure 01: System Block Diagram*
![Figure 01](/docs/diagram/system_block.png "Figure 01: System Block Diagram")

## SoC Design Flow

Given a specification, a partition is done between HW and SW. The HW design and SW design methodologies follow closely these tutorials: [1] Vivado Design Suite Tutorial and [2] Vitis Software Development Workflow, respectively. That said, the workflow is slightly modified due to different developing environments. The actual workflow  is shown in Figure 02.

*Figure 02: Design Flow*
![Figure 02](/docs/diagram/design_flow.png "Figure 02: Design Flow")

## System Overview

MicroBlaze (MCS) address space is partitioned into two main systems: [1] Memory-mapped IO (MMIO) System and [2] Video System. This is shown in Figure 03.

MMIO System consists of the standard IO peripherals.

Video System is considered as separate system. This is because unlike the MMIO system which is control-dominated, video system is data-dominated. The user (SW) only needs to configure the video cores once, then the data streaming wll take over. The video streaming from the camera to the LCD is automatic via the handshaking mechanism among the FIFO's. This is shown in Figure 04.

*Figure 03: User Space Parition*
![Figure 03](/docs/diagram/user_space_partition.png "Figure 03: User space partition")

*Figure 04: Video System*
![Figure 04](/docs/diagram/video_system.png "Figure 04: Video System")


## Target

1. MMIO System: IO Peripherals to communicate with the external devices
2. Video System: Video streaming from a camera to a LCD
3. Application System: Motion Detection Algorithm HW Implementation

## Project Status: Milestone + Demonstration

*Updated: June 03, 2023*

| **Milestone**     | **What's Included**   |   **Status**  | **Video Demo (Link)** |
|--                 |--                     |--             |--         |
| MMIO System       | Constructed the necessary communication IO such as i2C, SPI etc to configure/communicate with the external device.    | Completed | NA (See the Test Data Section)    |
| Video System      | Manage to stream the camera OV7670 to the LCD ILI9341. Supported camera colour format: RGB565, YUV422.  |Completed | ??        |
| Pixel Conversion | To convert the luminosity, Y of YUV422 to RGB565 format. | Completed | ??  |
| DDR2 SDRAM Interface  | User synchronous interface with the MIG memory interface for the external memory: DDR2 SDRAM. | Completed | NA (See the Test Data Section).   |
| Motion Detection  | TBA       | Not Started   | NA    |

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

*Updated: June 03, 2023*

![Figure 0?](/docs/diagram/timing_summary.png "Figure 0?: Design Timing Summary")

## External Devices

| **External Devices**  | **Description** |
|--                     |-- |
| LCD                   | Adafruit – 2.8” TFT LCD with Touchscreen Breakout Board with MicroSD Socket – ILI9341   |
| Camera                | VGA OV7670 Camera Module i2C 640x480   |
| External Memory       | DDR2 SDRAM (Micron: MT47H64M16HR-25E) |

## Acknowledgement

This project is born out of the attempts at the exercises for [4], [5], [6]. The verification technique  employed is from [4].

## Reference

1. Xilinx, "Vivado Design Suite Tutorial: Embedded Processor Hardware Design (UG940)", version 2019.1, June 27, 2019.
2. Xilinx, "Vitis Unified Software Platform Documentation: Embedded Software Development (UG1400)", version 2023.1, May 05, 2016.
3. Digilent, "Nexys A7 Reference Manual", website, accessed 27 May 2023, Link: <https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual>
4. Donald Thomas. (2016). Logic Design and Verification Using SystemVerilog (Revised). CreateSpace
5. Joseph Yiu. (2019). System-on-Chip with Arm® Cortex®-M Processors: Reference Book. Arm Education Media
6. Pong P. Chu. (2018). FPGA Prototyping by SystemVerilog Exampls: Xilinx MicroBlaze MCS SoC Edition. Wiley

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
