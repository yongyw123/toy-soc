# Toy SoC

This is a toy System on Chip (SoC) prototype with video streaming as the main application.

**Documentation:** The documentation, titled "master_docs" is linked [here](https://drive.google.com/drive/folders/1FAS5dOIlAdlUM4IH7u-qAvcwE-8EjuxC?usp=drive_link). This documents the memory organization, register map, register definition, construction, test results etc. This README is excerpted from this documentation.

| **Environment**           |                           |
|--                         |--                         |
| FPGA Development Board    | Digilent Nexys A7-50T     |
| FPGA Part Number          | XC7A50T-1CSG3241          |
| HW IDE                    | Vivado v2021.2            |
| HW Language               | SystemVerilog             |
| SW IDE                    | Vitis IDE v1.0.0.2021     |
| SW Language               | C++/C                     |

| **External Devices**  | **Description** |
|--                     |-- |
| LCD                   | Adafruit – 2.8” TFT LCD – ILI9341   |
| Camera                | VGA OV7670 Camera Module - i2C 640x480   |
| External Memory       | DDR2 SDRAM (Micron: MT47H64M16HR-25E). This is already embedded on the FPGA Development Board. |

**Source File Navigation:**

1. HW: It follows Vivado Hierarchy (structure).
    1. Source File : ./dev-soc/hw/dev_soc/dev_soc.srcs/sources_1
    2. Simulation File : ./dev-soc/hw/dev_soc/dev_soc.srcs/sim_1
    3. User Constraint File: /dev-soc/hw/dev_soc/dev_soc.srcs/constrs_1/imports/digilent-xdc-master/Nexys-A7-50T-Master.xdc
    4. DDR2 Pinout: ./dev-soc/ddr2_memory_pinout.ucf
2. SW: ./dev-soc/sw/user_src/

## Table of Contents

1. [Objective](#objective)
2. [SoC Design Flow](#soc-design-flow)
3. [System Overview](#system-overview)
4. [Project Status: Milestone + Demonstration](#project-status-milestone--demonstration)
    1. [Device Resource Utilization](#device-resource-utilization)
    2. [Design Timing Summary](#design-timing-summary)
5. [Test Data Navigation](#test-data-navigation)
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

Video System is considered separately. This is because unlike the MMIO system which is control-dominated, video system is data-dominated. The user (SW) only needs to configure the video cores once, then the data streaming wll take over. The video streaming from the camera to the LCD is automatic via the handshaking mechanism. This is shown in Figure 04.

*Figure 03: User Space Parition*
![Figure 03](/docs/diagram/user_space_partition.png "Figure 03: User space partition")

*Figure 04: Video System*
![Figure 04](/docs/diagram/video_system.png "Figure 04: Video System")

## Motion Detection Overview

This section briefly discusses about the chosen algorithm and the HW implementation.

### Background

The chosen motion detection algorithm is based on this paper: [7] “A robust and computationally efficient motion detection algorithm based on Σ-Δ background estimation”. This algorithm is pixel-based. Using similar language and notation as in the paper, the relevant terms, variables and symbols are listed in Table below. These shall be used for the rest of the document. Since the algorithm is pixel-based, it is implicit that each computation term (variables) listed below is indexed by time, t and at a given pixel, x.

| **Variable**  | **Symbol**    | **Definition**    | **Range**     | **BitWidth**  |
|--             |--             |--                 |--             |--             |
| Input Frame   | $$I_{t}(x)$$  | Raw pixel from the camera. Pixel in grayscale. | [0, 255] | 8 |
| Mean  | $$M_{t}(x)$$  | This is denoted as the first observation field in the paper | [0, 255] | 8 |
| Delta | $$Delta_{t}(x)$$  | Absolute difference between I_{t}(x) and M_{t}(x) | [0, 255]  | 8 |
| Variance  | $$V_{t}(x)$$  | This is denoted as the second observation field in the paper. | [0, 255]  | 8 |
| Amplification Factor   | $$N$$     | This serves as a comparison threshold. Roughly speaking, the higher the value is, the higher delta is needed for the current pixel to be considered as more likely to moving. | Integer: > 0 | NA |
| Final Detection Output | $$D_{t}(x)$$     | True if the current pixel is more likely to be moving; False otherwise. For convenience and display, a white pixel (0xFF) shall represent true; a black pixel (0x00) shall represent false.     | "Binary"  | 8 |

### HW Implementation (Algorithm Mapping)

Online (serial) processing method is employed where the incoming pixel from the camera is processed on-the-fly. The HW system diagram is shown in Figure 05 below. The system consists of two main blocks: (1) HW mapping of the motion detection algorithm; (2) Traffic Controller.

The HW mapping is direct. This is tabulated in Table 14 where each processing element corresponds directly to a part of the algorithm.

The traffic controller is to facilitate the data flow. This is necessary mainly because: (1) the video streaming system is handshaking-based, (2) the DDR2 interface only supports sequential transfer: one read/write transaction at time, (3) the motion detection is serial-processing based on one-pixel (8-bit) but the DDR2 transaction is 128-bit which hosts 8 computation terms corresponding to 8 pixels.

*Figure 05: Motion Detection System Diagram*
![Figure 05](/docs/diagram/motion-detection/motion_detection_system.png "Figure 05: Motion Detection System Diagram")

*Table 01: HW Mapping of the Motion Detection Algorithm*

| **#** | **Algorithm** *(For each frame, t)*   | **Processing Elements (PE) Corresponding to the Algorithm** |
|--     |--     |--     |
| 1 | For each pixel x: $$M_{t-1}(x) < I_{t}(x) \implies M_{t}(x) = M_{t-1}(x) + 1$$ $$M_{t-1}(x) \ge I_{t}(x) \implies M_{t}(x) = M_{t-1}(x) - 1$$ |  ![Figure 06](/docs/diagram/motion-detection/pe01.png "Figure 06: PE 01") |
| 2 | For each pixel x: $$Delta_{t}(x) = abs(M_{t}(x) - I_{t}(x))$$ |  ![Figure 07](/docs/diagram/motion-detection/pe02.png "Figure 07: PE 02") |
| 3 | For each pixel, x such that $$Delta_{t}(x) \ne 0$$ we have: $$M_{t-1}(x) < I_{t}(x) \implies M_{t}(x) = M_{t-1}(x) + 1$$ $$M_{t-1}(x) \ge I_{t}(x) \implies M_{t}(x) = M_{t-1}(x) - 1$$ | ![Figure 08](/docs/diagram/motion-detection/pe03.png "Figure 08: PE 03") |
| 4     | For each pixel x, $$Delta_{t}(x) < V_{t}(x) \implies D_{t}(x) = 1$$ $$Delta_{t}(x) \ge V_{t}(x) \implies D_{t}(x) = 0$$ | ![Figure 09](/docs/diagram/motion-detection/pe04.png "Figure 08: PE 04")    |

## Project Status: Milestone + Demonstration

*Updated: June 03, 2023*

| **Milestone**     | **What's Included**   |   **Status**  | **Video Demo (Link)** |
|--                 |--                     |--             |--         |
| MMIO System       | Constructed the necessary communication IO such as i2C, SPI etc to configure/communicate with the external device.    | Completed | NA (See the Test Data Section)    |
| Video System      | Manage to stream the camera OV7670 to the LCD ILI9341. Supported camera colour format: RGB565, YUV422.  |Completed | [Video Link](https://drive.google.com/file/d/1Ql_ATRLhIBi_aJ_FT88XsLlPmVaYCTlK/view?usp=drive_link)       |
| Pixel Conversion | To convert the luminosity, Y of YUV422 to RGB565 format. | Completed | [Video Link](https://drive.google.com/file/d/1wXfFwY07H_3Q5xLHrdHuBh9xfQ7aIEZR/view?usp=drive_link)  |
| DDR2 SDRAM Interface  | User synchronous interface with the MIG memory interface for the external memory: DDR2 SDRAM. | Completed | NA (See the Test Data Section).   |
| Motion Detection HW Implementation  | TBA       | Not Started   | NA    |

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

![Figure 05](/docs/diagram/timing_summary.png "Figure 05: Design Timing Summary")

## Test Data Navigation

Table 01 links the location of the test data of the major system blocks. Validation is conducted after the SW driver has been developed for its HW Core. Test data includes report, measurement data using logic analyser and/or video recording of the observation.
All the test data are stored under this parent directory: test-data <https://drive.google.com/drive/folders/1dAce-5lKH0lcdWMkTcalP11L70i5ODlV?usp=drive_link>

*Table 01:*
| **System Block Under Test**   | **Test Performed**    | **Test Data Relative Location (under the parent directory linked above)**     |
|--                             |--                     |--                                                                             |
| SPI Master Controller             | To test MOSI write data via logic analyser. | ./spi-core   |
| i2C Master Controller             | To test i2C write protocol via logic analyser. | ./camera-ov7670-setup    |
| LCD Display                       | To test the LCD Parallel 8080-I Interface via logic analyser. | ./mcu-8080-interface-display-controller |
| i2C master controller             | To test the I2C Communication with Camera OV7670. | ./i2c-core-with-camera-ov7670 |
| LCD Display                       | To use LCD SW drivers to read from and write to LCD ILI9341.    |   ./lcd-ILI9341-sw-drivers    |
| LCD Test Pattern Generator        | To display the LCD 8-colour bar generated from the HW core on the LCD ILI9341. | ./lcd-test-pattern-hw-generator |
| DCMI Interface + HW Emulator      | To test the DCMI interface with a HW DCMI emulator. |   ./dcmi-interface-with-hw-emulator   |
| DCMI Interface + Camera OV7670    | To test the DCMI interface with the Camera OV7670.  |   ./dcmi-interface-with-camera-ov7670 |
| Pixel Colour Converter            | To test YUV422 camera OV7670 output to grayscale when displayed as RGB565 format on the LCD ILI9341.  |   ./pixel-converter-YUV422-grayscale      |
| MIG DDR2 Interface                |   To test the interface with the external memory: DDR2 SDRAM. |   ./ddr2-sdram-mig    |

## Acknowledgement

This project is born out of the attempts at the exercises for [4], [5], [6].

## Reference

1. Xilinx. (2019, June 27). "Vivado Design Suite Tutorial: Embedded Processor Hardware Design (UG940)". version 2019.1.
2. Xilinx. (2016, May 05). "Vitis Unified Software Platform Documentation: Embedded Software Development (UG1400)". version 2023.1.
3. Digilent. "Nexys A7 Reference Manual". [Online]. Available: <https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual>. Accessed 2023, 27 May.
4. Donald Thomas. (2016). “Logic Design and Verification Using SystemVerilog (Revised)”. CreateSpace.
5. Joseph Yiu. (2019). “System-on-Chip with Arm® Cortex®-M Processors: Reference Book”. Arm Education Media.
6. Pong P. Chu. (2018). “FPGA Prototyping by SystemVerilog Examples: Xilinx MicroBlaze MCS SoC Edition”. Wiley.
7. A. Manzanera, J.C. Richefeu. (2004). “A robust and computationally efficient motion detection algorithm based on Σ-Δ background estimation”. [Online]. Available: <https://hal.science/hal-01222695/document>

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
- [ ] Characterize the frame rate of the video streaming (inc. the motion detection).

### Application

- [x] Test SW Function for each core.
- [x] IP generate Clock management circuit
- [x] IP generate DDR memory interface for Frame Buffers?
- [x] Camera OV7670 via i2C interface
- [x] LCD ILI9341 Configuration Interface

## Extra (Nice to have)

- [ ] Add interrupt system. To consider using IP or user-defined?
