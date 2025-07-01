# ArduCam Mega for Toit

A Toit library for ArduCam Mega cameras, supporting 3MP and 5MP modules.

## Features

- Support for 3MP and 5MP ArduCam modules
- Multiple image formats (JPEG, RGB565, YUV)
- Multiple resolutions from 96x96 to 2592x1944
- Camera settings control (brightness, contrast, saturation, etc.)
- Auto-focus and exposure controls
- Hardware SPI communication

## Development Setup

`sketch --unsafe-mode --device=/dev/ttyUSB0`

## Hardware Setup


There is an [ArduCam Mega-5MP](https://docs.arducam.com/Arduino-SPI-camera/MEGA-SPI/MEGA-Quick-Start-Guide/#hardware-connection) SPI camera and SD card reader hooked to the www.EzSBC.com ESP32 board as follows:

### ArduCam MEGA5-MP connections

| Description   | EzSBC ESP32 |  Mega camera |
| --            | --          |  --          |
| miso          | 19          |  MISO        |
| mosi          | 23          |  MOSI        |
| clk           | 18          |  SCK         |
| cs/camera     | 22          |  CS          |
| 3.3v          | 3.3         |  VCC         |  
| gnd           | Gnd         |  GND         |  


### SD Card connections

| Description   | EzSBC ESP32 | Micro-SD board  | 
| --            | --          | --              | 
| miso          | 19          | DO              | 
| mosi          | 23          | DI              | 
| clk           | 18          | CLK             | 
| cs/sd-card    | 5           | CS              | 
| 5v            | Vin         | 5v              | 
| gnd           | Gnd         | GND             | 
| not connected |             | CD, 3v          | 

## Usage

### Basic Example

```toit
import arducam_mega show *
import spi
import gpio

main:
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  camera := ArducamCamera
      --spi-bus=bus
      --cs=gpio.Pin 22

  camera.on
  
  // Take a picture
  camera.take-picture CAM_IMAGE_MODE_VGA CAM_IMAGE_PIX_FMT_JPG
  
  // Read the image data
  if camera.image-available > 0:
    image-data := camera.read-buffer camera.image-available
    // Process your image data here
```

### Testing on Hardware

To test with an ESP32 connected via USB:

```bash
# Run the test
jag run examples/test_camera.toit

# Monitor the output
jag monitor
```

### Image Modes

- `CAM_IMAGE_MODE_QQVGA` - 160x120
- `CAM_IMAGE_MODE_QVGA` - 320x240
- `CAM_IMAGE_MODE_VGA` - 640x480
- `CAM_IMAGE_MODE_SVGA` - 800x600
- `CAM_IMAGE_MODE_HD` - 1280x720
- `CAM_IMAGE_MODE_UXGA` - 1600x1200
- `CAM_IMAGE_MODE_FHD` - 1920x1080
- `CAM_IMAGE_MODE_WQXGA2` - 2592x1944

### Pixel Formats

- `CAM_IMAGE_PIX_FMT_JPG` - JPEG format (recommended)
- `CAM_IMAGE_PIX_FMT_RGB565` - RGB565 format
- `CAM_IMAGE_PIX_FMT_YUV` - YUV format

### Camera Settings

```toit
// Set image quality (0-2: 0=high, 1=default, 2=low)
camera.set-image-quality HIGH_QUALITY

// Set brightness (-4 to +4)
camera.set-brightness CAM_BRIGHTNESS_LEVEL_1

// Set contrast (-3 to +3)
camera.set-contrast CAM_CONTRAST_LEVEL_1

// Enable auto white balance
camera.set-auto-white-balance true

// Set white balance mode
camera.set-auto-white-balance-mode CAM_WHITE_BALANCE_MODE_SUNNY
```

## Troubleshooting

### Camera returns zeros for version info

This usually indicates SPI communication issues:

1. Check your wiring connections
2. Verify the CS pin is correct
3. Try a different CS pin
4. Check power supply (3.3V, adequate current)
5. Try reducing SPI frequency

### "No image data captured"

1. Ensure camera is properly initialized
2. Check that `camera.on` completed successfully
3. Verify the camera module is compatible (3MP/5MP ArduCam)
4. Try different image modes/formats

### Communication errors

- Verify SPI pins are correct for your ESP32 board
- Check for loose connections
- Ensure adequate power supply
- Try adding delays between operations

## Examples

- `examples/test_camera.toit` - Hardware test and diagnostics
- `examples/capture.toit` - Image capture with SD card storage

## License

See LICENSE file for details.
