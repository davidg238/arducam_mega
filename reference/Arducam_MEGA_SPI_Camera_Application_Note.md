
# Arducam Mega SPI Camera Series  
## Mega SPI Camera Series Application Note  
**September, 2023**

---

## Table of Contents

- [Arducam Mega SPI Camera Series](#arducam-mega-spi-camera-series)
  - [Mega SPI Camera Series Application Note](#mega-spi-camera-series-application-note)
  - [Table of Contents](#table-of-contents)
  - [1. Introduction](#1-introduction)
  - [2. SPI Slave Interface](#2-spi-slave-interface)
  - [3. Arducam Mega Timing Diagram](#3-arducam-mega-timing-diagram)
    - [3.1 Single Read Timing](#31-single-read-timing)
    - [3.2 Single Write Timing](#32-single-write-timing)
    - [3.3 First Time Burst Read Timing](#33-first-time-burst-read-timing)
    - [3.4 Nth Burst Read Timing (N ≥ 2)](#34-nth-burst-read-timing-n--2)
  - [4. Register Table](#4-register-table)
  - [The FPGA register address is 8 bit](#the-fpga-register-address-is-8-bit)
  - [5. Brief of Mega SDK](#5-brief-of-mega-sdk)
    - [Resources](#resources)

---

## 1. Introduction

This application note describes the detailed hardware messages of the Arducam Mega SPI Camera Module.

---

## 2. SPI Slave Interface

Arducam Mega SPI slave interface is fixed SPI mode 0 with POL = 0 and PHA=
0. The recommended speed of SCLK is 8MHz. Also note that the performance
may vary across different platforms. The SPI protocol is designed with a
command phase with variable data phase. The chip select signal should always
keep asserted during the SPI read or write bus cycle.

---

## 3. Arducam Mega Timing Diagram

### 3.1 Single Read Timing

The SPI bus single read timing is for read operation of Arducam Mega internal
registers and single FIFO read function. It is composed of a command phase and a
data phase during the assertion of chip select signal CSn. The first 8 bits is the
command byte which is decoded as a register address. The second 8 bits is the
dummy data, which is used to provide a delay area in a very short time to prepare
data for the camera. The final 8 bits is written to the SPI bus MOSI signal, and the
content read back from register is appeared on the SPI bus MISO signal.

### 3.2 Single Write Timing

The SPI bus write timing composed of a command phase and a data phase during
the assertion of the chip select signal CSn. The first 8 bits is command byte which
is decoded as a register address, and the second 8 bits is data byte to be written to
the Arducam Mega internal registers.

### 3.3 First Time Burst Read Timing

SPI bus burst read timing only applies to burst FIFO read operations. It consists of
a burst read command phase and multiple data phases to achieve multiple times
throughput compared to a single FIFO read operation. Similar to a single read
4mode, when formally burst reading data, the first byte is the dummy data(Allow
enough time for data preparation) and the subsequent data is valid.

### 3.4 Nth Burst Read Timing (N ≥ 2)

Different from the First Time burst read mode, when the Nth burst read command
is issued, the data will start to be prepared directly, and all subsequent data
received will be valid data.

---

## 4. Register Table

(If no entry for MEGA-3MP, same as MEGA-5MP)

| FPGA Reg* | Type | MEGA-5MP                                           | MEGA-3MP  | Default Value |
|:--------: |------|----------                                          |---------  | :---:         |
| `0x00`    | RW   | Test register                                      |           |`0x00` |
| `0x01`    | RW   | Bit[7:0]: Number of shooting frames                |           | `0x00` |
|           |      | 0-254: Number of freames = val +1 (unless full)    | | |
|           |      | 255: Indicates memory is full (8MB)                | | |
| `0x02`    | RW   | Bit[2]: cam_power_en 1: Normal 0: Power off        | | `0x05` |
|           |      | Bit[1]: cam_pwdn  1: Sleep 0: Normal               | | |
|           |      | Bit[0]: cam_rst_n 1: Normal 0: reset               | | |
| `0x04`    | RW   | Memory control                                     | | Default |
|           |      | Bit[1]: Write 1: start taking pictures             | | |
|           |      | Bit[0]: Write 1: clear write mem completion flag   | | |
| `0x05`    | RW   | Bit[7]: Select camera:0 or simulation data:1       | | `0x00`|
|           |      | Bit[1]: In 16bit mode, convert input 10 to 16 bits | | |
|           |      |          Choose to fill hi or lo bit with 0        | | |
|           |      |          Write 0: Fill hi 6 bits with 0            | | |
|           |      |          Write 1: Fill lo 6 bits with 0            | | |
|           |      | Bit[0]: Select 8 or 16 bit mode                    | | |
|           |      |          Write 0: 8 bit mode                       | | |
|           |      |          Write 1: 16 bit mode                      | | |
| `0x06`    | RW   | Bit[7]: test data (32-bit counter)                 | | `0x01` |
|           |      |          Write 0: normal data                      | | |
|           |      |          Write 1: test data                        | | |
|           |      | Bit[0]: VSYN field signal valid hi or lo           | | |
|           |      |          Write 0: hi effective                     | | |
|           |      |          Write 1: lo effective                     | | |
| `0x07`    | RW   | Bit[7]: Write 1, reset cache (SDRAM, 8M)           | | Default |
|           |      | Bit[6]: Write 1 to reset FPGA                      | | |
|           |      | Bit[1]: Write 1 to reset I2C                       | | |
|           |      | Bit[0]: Write 1 to initiate I2C direct read camera operation | | |
| `0x0A`    | RW   | Directly write camera reg, I2C device addr         | | Default |
| `0x0B`    | RW   | Directly write camera reg, upper 8 bits of I2C reg addr | | Default |
| `0x0C`    | RW   | Directly write camera reg, lower 8 bits of I2C reg addr | | Default |
| `0x20`    | WO   | Bit[1:0]: write basic configuration                | | Default |
|           |      |          0: Write basic configuration              | | |
|           |      |          1: Write JPG basic configuration          | | |
|           |      |          2: Write RGB basic configuration          | | |
|           |      |          3: Write YUV basic configuration          | | |
| `0x21`    | WO   | Bit[6:0]: Resolution | Bit[6:0]: Resolution          | Default |
|           |      | 1: 320x240           | 1: 320x240                    | |
|           |      | 2: 640x480           | 2: 640x480                    | |
|           |      | 4: 1280x720          | 4: 1280x720                   | |
|           |      | 6: 1600x1200         | 6: 1600x1200                  | |
|           |      | 7: 1920x1080         | 7: 1920x1080                  | |
|           |      | 9: 2592x1944         | 9: 2592x1944                  | |
|           |      | 10:96x96             | 10:96x96                      | |
|           |      | 11:128x128           | 11:128x128                    | |
|           |      | 12: 320x320          | 12: 320x320                   | |
| `0x22`    | WO   | Bit[3:0]: brightness adjustment                      | | Default |
|           |      | 0: default                                           | | |
|           |      | 1: +1                                                | | |
|           |      | 2: -1                                                | | |
|           |      | 3: +2                                                | | |
|           |      | 4: -2                                                | | |
|           |      | 5: +3                                                | | |
|           |      | 6: -3                                                | | |
|           |      | 7: +4                                                | | |
|           |      | 8: -4                                                | | |
| `0x23`    | WO   | Bit[3:0]: Contrast adjustment                        | | Default |
|           |      | 0: default                                           | | |
|           |      | 1: +1                                                | | |
|           |      | 2: -1                                                | | |
|           |      | 3: +2                                                | | |
|           |      | 4: -2                                                | | |
|           |      | 5: +3                                                | | |
|           |      | 6: -3                                                | | |
| `0x24`    | WO   | Bit[2:0]: Saturation adjustment                      | | Default |
|           |      | 0: default                                           | | |
|           |      | 1: +1                                                | | |
|           |      | 2: -1                                                | | |
|           |      | 3: +2                                                | | |
|           |      | 4: -2                                                | | |
|           |      | 5: +3                                                | | |
|           |      | 6: -3                                                | | |
| `0x25`    | WO   | Bit[2:0]: Exposure compensation                      | | Default |
|           |      | 0: default                                           | | |
|           |      | 1: +1                                                | | |
|           |      | 2: -1                                                | | |
|           |      | 3: +2                                                | | |
|           |      | 4: -2                                                | | |
|           |      | 5: +3                                                | | |
|           |      | 6: -3                                                | | |
| `0x26`    | WO   | Bit[2:0]: White balance mode                         | | Default |
|           |      | 0: automatic                                         | | |
|           |      | 1: daylight                                          | | |
|           |      | 2: office                                            | | |
|           |      | 3: cloudy day                                        | | |
|           |      | 4: indoor                                            | | |
| `0x27`    | WO   | Bit[3:0]: Special effect | Bit[3:0]: Special effect  | Default |
|           |      | 0: none              | 0: none                       | |
|           |      | 1: cool color        | 1: cool color                 | |
|           |      | 2: warm color        | 2: warm color                 | |
|           |      | 3: black & white     | 3: black & white              | |
|           |      | 4: yellowing         | 4: yellowing                  | |
|           |      | 5: reverse color     | 5: reverse color              | |
|           |      | 6: greenish          | 6: greenish                   | |
|           |      |                      | 9: light yellow               | |
| `0x28`    | WO   | -                    | Bit[2:0] Sharpness adjust     | | Default |
|           |      |                      | 0: automatic                  | |
|           |      |                      | 1: Sharpness 1                  | |
|           |      |                      | 2: Sharpness 2                  | |
|           |      |                      | 3: Sharpness 3                  | |
|           |      |                      | 4: Sharpness 4                  | |
|           |      |                      | 5: Sharpness 5                  | |
|           |      |                      | 6: Sharpness 6                  | |
|           |      |                      | 7: Sharpness 7                  | |
|           |      |                      | 8: Sharpness 8                  | |
| `0x29`    | WO   | Bit[1:0]: Autofocus                                  | - | Default |
|           |      | 0: autofocus on, config is very long, default single | | |
|           |      | 1: single focus                                      | | |
|           |      | 2: contiuous autofocus                               | | |
|           |      | 3: pause autofocus                                   | | |
|           |      | 4: autofocus off                                     | | |
| `0x2A`    | WO   | Bit[1:0]: JPG mode image quality                     | | Default |
|           |      | 0: High                                              | | |
|           |      | 1: Medium                                            | | |
|           |      | 2: Low                                               | | |
| `0x30`    | WO   | Bit[7]: Turn on/off automatic mode                   | | Default |
|           |      | 1: Turn on Automatic                                 | | |
|           |      | 0: Turn off Automatic                                | | |
|           |      | Bit[1:0]                                             | | |
|           |      | 0: Automatic gain                                    | | |
|           |      | 1: Auto exposure                                     | | |
|           |      | 2: Auto white balance                                | | |
| `0x31`    | WO   | Bit[1:0]: Manual gain [9:8]                          | | Default |
| `0x32`    | WO   | Bit[7:0]: Manual gain [7:0]                          | | Default |
| `0x33`    | WO   | Bit[3:0]: Manual exposure [19:16]                    | | Default |
| `0x34`    | WO   | Bit[7:0]: Manual exposure [15:8]                     | | Default |
| `0x35`    | WO   | Bit[7:0]: Manual exposure [7:0]                      | | Default |

The FPGA register address is 8 bit
---

## 5. Brief of Mega SDK

Arducam Mega SDK is a C and C++ package, containing convenience classes and
functions that help in most common tasks while using Arducam Mega API. We
support both C API and C++ API. The SDK contains HAL layer and Arducam
Mega Cam protocol layer and API.

### Resources

For more information about Arducam Mega SDK, API, and Arducam Mega GUI,
please refer to the following link: [https://www.arducam.com/docs/arducam-mega/arducam-mega-getting-started/index.html](https://www.arducam.com/docs/arducam-mega/arducam-mega-getting-started/index.html)
