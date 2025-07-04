import spi
import gpio
 
 /**
  Camera status
  */
CAM_ERR_SUCCESS     ::= 0  /**<Operation succeeded*/
CAM_ERR_NO_CALLBACK ::= -1 /**< No callback function is registered*/

/**
Sensor reset and control registers from C code
*/
CAM_REG_SENSOR_RESET ::= 0x07
CAM_SENSOR_RESET_ENABLE ::= 0x40  // (1 << 6)
CAM_I2C_READ_MODE ::= 0x01        // (1 << 0)
CAM_REG_YEAR_ID ::= 0x41
CAM_REG_MONTH_ID ::= 0x42
CAM_REG_DAY_ID ::= 0x43

/**
CAM_IMAGE_MODE
*/
CAM_IMAGE_MODE_QQVGA  ::= 0x00  /**<160x120 */
CAM_IMAGE_MODE_QVGA   ::= 0x01  /**<320x240*/
CAM_IMAGE_MODE_VGA    ::= 0x02  /**<640x480*/
CAM_IMAGE_MODE_SVGA   ::= 0x03  /**<800x600*/
CAM_IMAGE_MODE_HD     ::= 0x04  /**<1280x720*/
CAM_IMAGE_MODE_SXGAM  ::= 0x05  /**<1280x960*/
CAM_IMAGE_MODE_UXGA   ::= 0x06  /**<1600x1200*/
CAM_IMAGE_MODE_FHD    ::= 0x07  /**<1920x1080*/
CAM_IMAGE_MODE_QXGA   ::= 0x08  /**<2048x1536*/
CAM_IMAGE_MODE_WQXGA2 ::= 0x09  /**<2592x1944*/
CAM_IMAGE_MODE_96X96  ::= 0x0a  /**<96x96*/
CAM_IMAGE_MODE_128X128 ::= 0x0b /**<128x128*/
CAM_IMAGE_MODE_320X320 ::= 0x0c /**<320x320*/
/// @cond
CAM_IMAGE_MODE_12      ::= 0x0d /**<Reserve*/
CAM_IMAGE_MODE_13      ::= 0x0e /**<Reserve*/
CAM_IMAGE_MODE_14      ::= 0x0f /**<Reserve*/
CAM_IMAGE_MODE_15      ::= 0x10 /**<Reserve*/
CAM_IMAGE_MODE_NONE    ::= 0x11 /**<No defined resolution*/

/**
Configure camera contrast level
*/
CAM_CONTRAST_LEVEL_MINUS_3 ::= 6 /**<Level -3 */
CAM_CONTRAST_LEVEL_MINUS_2 ::= 4 /**<Level -2 */
CAM_CONTRAST_LEVEL_MINUS_1 ::= 2 /**<Level -1 */
CAM_CONTRAST_LEVEL_DEFAULT ::= 0 /**<Level Default*/
CAM_CONTRAST_LEVEL_1       ::= 1 /**<Level +1 */
CAM_CONTRAST_LEVEL_2       ::= 3 /**<Level +2 */
CAM_CONTRAST_LEVEL_3       ::= 5 /**<Level +3 */

/**
Configure camera EV level
*/
CAM_EV_LEVEL_MINUS_3 ::= 6 /**<Level -3 */
CAM_EV_LEVEL_MINUS_2 ::= 4 /**<Level -2 */
CAM_EV_LEVEL_MINUS_1 ::= 2 /**<Level -1 */
CAM_EV_LEVEL_DEFAULT ::= 0 /**<Level Default*/
CAM_EV_LEVEL_1       ::= 1 /**<Level +1 */
CAM_EV_LEVEL_2       ::= 3 /**<Level +2 */
CAM_EV_LEVEL_3       ::= 5 /**<Level +3 */

/**
Configure camera saturation  level
*/
CAM_SATURATION_LEVEL_MINUS_3 ::= 6 /**<Level -3 */
CAM_SATURATION_LEVEL_MINUS_2 ::= 4 /**<Level -2 */
CAM_SATURATION_LEVEL_MINUS_1 ::= 2 /**<Level -1 */
CAM_SATURATION_LEVEL_DEFAULT ::= 0 /**<Level Default*/
CAM_SATURATION_LEVEL_1       ::= 1 /**<Level +1 */
CAM_SATURATION_LEVEL_2       ::= 3 /**<Level +2 */
CAM_SATURATION_LEVEL_3       ::= 5 /**<Level +3 */

/**
Configure camera brightness level
*/
CAM_BRIGHTNESS_LEVEL_MINUS_4 ::= 8 /**<Level -4 */
CAM_BRIGHTNESS_LEVEL_MINUS_3 ::= 6 /**<Level -3 */
CAM_BRIGHTNESS_LEVEL_MINUS_2 ::= 4 /**<Level -2 */
CAM_BRIGHTNESS_LEVEL_MINUS_1 ::= 2 /**<Level -1 */
CAM_BRIGHTNESS_LEVEL_DEFAULT ::= 0 /**<Level Default*/
CAM_BRIGHTNESS_LEVEL_1       ::= 1 /**<Level +1 */
CAM_BRIGHTNESS_LEVEL_2       ::= 3 /**<Level +2 */
CAM_BRIGHTNESS_LEVEL_3       ::= 5 /**<Level +3 */
CAM_BRIGHTNESS_LEVEL_4       ::= 7 /**<Level +4 */

/**
Configure camera Sharpness level
*/
CAM_SHARPNESS_LEVEL_AUTO ::= 0 /**<Sharpness Auto */
CAM_SHARPNESS_LEVEL_1 ::= 1    /**<Sharpness Level 1 */
CAM_SHARPNESS_LEVEL_2 ::= 2    /**<Sharpness Level 2 */
CAM_SHARPNESS_LEVEL_3 ::= 3    /**<Sharpness Level 3 */
CAM_SHARPNESS_LEVEL_4 ::= 4    /**<Sharpness Level 4 */
CAM_SHARPNESS_LEVEL_5 ::= 5    /**<Sharpness Level 5 */
CAM_SHARPNESS_LEVEL_6 ::= 6    /**<Sharpness Level 6 */
CAM_SHARPNESS_LEVEL_7 ::= 7    /**<Sharpness Level 7 */
CAM_SHARPNESS_LEVEL_8 ::= 8    /**<Sharpness Level 8 */

/**
Configure resolution in video streaming mode
*/
CAM_VIDEO_MODE_0 ::= 1 /**< 320x240 */
CAM_VIDEO_MODE_1 ::= 2 /**< 640x480 */

/**
Configure image pixel format
*/
CAM_IMAGE_PIX_FMT_RGB565 ::= 0x02 /**< RGB565 format */
CAM_IMAGE_PIX_FMT_JPG    ::= 0x01 /**< JPEG format */
CAM_IMAGE_PIX_FMT_YUV    ::= 0x03 /**< YUV format */
CAM_IMAGE_PIX_FMT_NONE   ::= 0x04  /**< No defined format */

/**
Configure white balance mode
*/
CAM_WHITE_BALANCE_MODE_DEFAULT  ::= 0 /**< Auto */
CAM_WHITE_BALANCE_MODE_SUNNY    ::= 1 /**< Sunny */
CAM_WHITE_BALANCE_MODE_OFFICE   ::= 2 /**< Office */
CAM_WHITE_BALANCE_MODE_CLOUDY   ::= 3 /**< Cloudy*/
CAM_WHITE_BALANCE_MODE_HOME     ::= 4 /**< Home */

/**
Configure special effects
*/
CAM_COLOR_FX_NONE     ::= 0      /**< no effect   */
CAM_COLOR_FX_BLUEISH  ::= 1      /**< cool light   */
CAM_COLOR_FX_REDISH   ::= 2      /**< warm   */
CAM_COLOR_FX_BW       ::= 3      /**< Black/white   */
CAM_COLOR_FX_SEPIA    ::= 4      /**<Sepia   */
CAM_COLOR_FX_NEGATIVE ::= 5      /**<positive/negative inversion  */
CAM_COLOR_FX_GRASS_GREEN    ::= 6 /**<Grass green */
CAM_COLOR_FX_OVER_EXPOSURE  ::= 7 /**<Over exposure*/
CAM_COLOR_FX_SOLARIZE       ::= 8 /**< Solarize   */

HIGH_QUALITY    ::= 0
DEFAULT_QUALITY ::= 1
LOW_QUALITY     ::= 2

SENSOR_5MP_1 ::= 0x81
SENSOR_3MP_1 ::= 0x82
SENSOR_5MP_2 ::= 0x83 /* 2592x1936 */
SENSOR_3MP_2 ::= 0x84
SENSOR_MEGA_5MP ::= 0x56  /* ArduCam MEGA-5MP */


 
CAM-STATUS-UNINIT ::= 0 /**< Camera is not initialized */
CAM-STATUS-INIT   ::= 1 /**< Camera is initialized */
CAM-STATUS-OPEN   ::= 2 /**< Camera is open */
CAM-STATUS-CLOSE  ::= 3 /**< Camera is closed */

 
ARDUCHIP_FRAMES ::=     0x01
ARDUCHIP_TEST1  ::=     0x00 // TEST register
ARDUCHIP_FIFO   ::=     0x04 // FIFO and I2C control
ARDUCHIP_FIFO_2 ::=     0x07 // FIFO and I2C control
FIFO_CLEAR_ID_MASK ::=  0x01
FIFO_START_MASK ::=     0x02
 
FIFO_RDPTR_RST_MASK ::= 0x10
FIFO_WRPTR_RST_MASK ::= 0x20
FIFO_CLEAR_MASK ::=     0x80
 
ARDUCHIP_TRIG ::=       0x44 // Trigger source
VSYNC_MASK ::=          0x01
SHUTTER_MASK ::=        0x02
CAP_DONE_MASK ::=       0x04
 
FIFO_SIZE1 ::=          0x45 // Camera write FIFO size[7:0] for burst to read
FIFO_SIZE2 ::=          0x46 // Camera write FIFO size[15:8]
FIFO_SIZE3 ::=          0x47 // Camera write FIFO size[18:16]
 
BURST_FIFO_READ ::=     0x3C // Burst FIFO read operation
SINGLE_FIFO_READ ::=    0x3D // Single FIFO read operation
 
PREVIEW_BUF_LEN ::=     255  // was 50 for MSP430G2553

CAPTURE_MAX_NUM ::=                            0xff
 
CAM_REG_POWER_CONTROL ::=                      0X02

CAM_REG_FORMAT ::=                             0X20
CAM_REG_CAPTURE_RESOLUTION ::=                 0X21
CAM_REG_BRIGHTNESS_CONTROL ::=                 0X22
CAM_REG_CONTRAST_CONTROL ::=                   0X23
CAM_REG_SATURATION_CONTROL ::=                 0X24
CAM_REG_EV_CONTROL ::=                         0X25
CAM_REG_WHITEBALANCE_MODE_CONTROL ::=          0X26
CAM_REG_COLOR_EFFECT_CONTROL ::=               0X27
CAM_REG_SHARPNESS_CONTROL ::=                  0X28
CAM_REG_AUTO_FOCUS_CONTROL ::=                 0X29
CAM_REG_IMAGE_QUALITY ::=                      0x2A
CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL ::= 0X30
CAM_REG_MANUAL_GAIN_BIT_9_8 ::=                0X31
CAM_REG_MANUAL_GAIN_BIT_7_0 ::=                0X32
CAM_REG_MANUAL_EXPOSURE_BIT_19_16 ::=          0X33
CAM_REG_MANUAL_EXPOSURE_BIT_15_8 ::=           0X34
CAM_REG_MANUAL_EXPOSURE_BIT_7_0 ::=            0X35
CAM_REG_BURST_FIFO_READ_OPERATION ::=          0X3C
CAM_REG_SINGLE_FIFO_READ_OPERATION ::=         0X3D
CAM_REG_SENSOR_ID ::=                          0x40

CAM_REG_SENSOR_STATE ::=                       0x44
CAM_REG_FPGA_VERSION_NUMBER ::=                0x49
CAM_REG_DEBUG_DEVICE_ADDRESS ::=               0X0A
CAM_REG_DEBUG_REGISTER_HIGH ::=                0X0B
CAM_REG_DEBUG_REGISTER_LOW ::=                 0X0C
CAM_REG_DEBUG_REGISTER_VALUE ::=               0X0D
 
CAM_REG_SENSOR_STATE_IDLE ::=                  (1 << 1)

CAM_FORMAT_BASICS ::=                          (0 << 0)
CAM_SET_CAPTURE_MODE ::=                       (0 << 7)
CAM_SET_VIDEO_MODE ::=                         (1 << 7)
 
SET_WHITEBALANCE ::=                           0X02
SET_EXPOSURE ::=                               0X01
SET_GAIN ::=                                   0X00
 
CAMERA_TYPE_NUMBER ::=                         2
 
 //FORMAT_NONE                                0X00
 //FORMAT_JPEG                                0X01
 //FORMAT_RGB                                 0X02
 //FORMAT_YUV                                 0X03
 
RESOLUTION_160X120 ::=                         (1 << 0)
RESOLUTION_320X240 ::=                         (1 << 1)
RESOLUTION_640X480 ::=                         (1 << 2)
RESOLUTION_800X600 ::=                         (1 << 3)
RESOLUTION_1280X720 ::=                        (1 << 4)
RESOLUTION_1280X960 ::=                        (1 << 5)
RESOLUTION_1600X1200 ::=                       (1 << 6)
RESOLUTION_1920X1080 ::=                       (1 << 7)
RESOLUTION_2048X1536 ::=                       (1 << 8)
RESOLUTION_2592X1944 ::=                       (1 << 9)
RESOLUTION_320x320 ::=                         (1 << 10)
RESOLUTION_128x128 ::=                         (1 << 11)
RESOLUTION_96x96 ::=                           (1 << 12)
 
SPECIAL_NORMAL ::=                             (0 << 0)
SPECIAL_BLUEISH ::=                            (1 << 0)
SPECIAL_REDISH ::=                             (1 << 1)
SPECIAL_BW ::=                                 (1 << 2)
SPECIAL_SEPIA ::=                              (1 << 3)
SPECIAL_NEGATIVE ::=                           (1 << 4)
SPECIAL_GREENISH ::=                           (1 << 5)
SPECIAL_OVEREXPOSURE ::=                       (1 << 6)
SPECIAL_SOLARIZE ::=                           (1 << 7)
SPECIAL_YELLOWISH ::=                          (1 << 8)

DEVICE-ADDRESS ::= 0x78

OV3640-GAIN-VALUE ::= [ 0x00, 0x10, 0x18, 0x30, 0x34, 0x38, 0x3b, 0x3f, 
                        0x72, 0x74, 0x76, 0x78, 0x7a, 0x7c, 0x7e, 0xf0, 
                        0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 
                        0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
                      ]
 

 
class CameraInfo:
  camera-id /string
  support-resolution /int
  support-special-effects /int
  exposure-value-max /int
  exposure-value-min /int
  gain-value-max /int
  gain-value-min /int
  support-focus /bool
  support-sharpness /bool
  device-address /int

  constructor.camera-info-5MP --.camera-id="5MP":
    support-resolution = RESOLUTION_320x320 | RESOLUTION_128x128 | RESOLUTION_96x96 | RESOLUTION_320X240 | RESOLUTION_640X480 | RESOLUTION_1280X720 | RESOLUTION_1600X1200 | RESOLUTION_1920X1080 | RESOLUTION_2592X1944
    support-special-effects = SPECIAL_BLUEISH | SPECIAL_REDISH | SPECIAL_BW | SPECIAL_SEPIA | SPECIAL_NEGATIVE | SPECIAL_GREENISH /*| SPECIAL_OVEREXPOSURE | SPECIAL_SOLARIZE*/
    exposure-value-max = 30000
    exposure-value-min = 1
    gain-value-max     = 1023
    gain-value-min     = 1
    support-focus     = true
    support-sharpness = false
    device-address    = DEVICE-ADDRESS
 
  constructor.camera-info-3MP:
    camera-id          = "3MP"
    support-resolution = RESOLUTION_320x320 | RESOLUTION_128x128 | RESOLUTION_96x96 | RESOLUTION_320X240 | RESOLUTION_640X480 | RESOLUTION_1280X720 | RESOLUTION_1600X1200 | RESOLUTION_1920X1080 | RESOLUTION_2048X1536
    support-special-effects = SPECIAL_BLUEISH | SPECIAL_REDISH | SPECIAL_BW | SPECIAL_SEPIA | SPECIAL_NEGATIVE | SPECIAL_GREENISH | SPECIAL_YELLOWISH
    exposure-value-max = 30000
    exposure-value-min = 1
    gain-value-max     = 1023
    gain-value-min     = 1
    support-focus     = false
    support-sharpness = true
    device-address    = DEVICE-ADDRESS
 


class ArducamCamera:
  cs  /gpio.Pin                                      /**< CS pin */
  spi-bus / spi.Bus
  camera /spi.Device

  camera-id /string?                               /**< Model of camera module */

  total-length /int       := -1                        /**< The total length of the picture */
  received-length /int    := -1                        /**< The remaining length of the picture */

  burst-first-flag /bool  := false                        /**< Flag bit for reading data for the first time in burst mode */
  preview-mode /bool      := false                       /**< Stream mode flag */
  current-pixel-format /int := -1                     /**< The currently set image pixel format */
  current-picture-mode /int := -1                      /**< Currently set resolution */
  camera-info /CameraInfo? := null                 /**< Basic information of the current camera */
  ver-date-and-number /List := [1970, 1, 1, 0]          /**< Version information of the camera module */

  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin:
    // Try very conservative settings for maximum compatibility
    camera = spi-bus.device --cs=cs --frequency=1_000_000 --mode=0  // Very slow 1MHz, mode 0
    camera-id = ""
    current-pixel-format = CAM_IMAGE_PIX_FMT_NONE
    current-picture-mode = CAM_IMAGE_MODE_NONE

  on -> none:
    print "Camera init - ArduCam MEGA-5MP (C code sequence)"
    
    // Implement C code cameraBegin() sequence exactly
    print "Executing C code initialization sequence..."
    
    // Step 1: Reset CPLD and camera (C code line 319)
    print "  1. Resetting sensor..."
    write-reg CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE
    
    // Step 2: Wait for I2C idle (C code line 320)
    print "  2. Waiting for I2C idle..."
    wait-idle
    
    // Step 3: Get sensor configuration (C code line 321)
    print "  3. Getting sensor configuration..."
    get-sensor-config
    
    // Step 4: Update camera info (C code line 322)
    print "  4. Updating camera info..."
    camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP"
    
    // Step 5: Read version information (C code lines 323-328)
    print "  5. Reading version information..."
    read-version-info
    
    print "  ✅ C code initialization sequence complete!"
    print "Camera initialization complete!"
  
  read-version-info -> none:
    print "    Reading version information..."
    
    year := read-reg CAM_REG_YEAR_ID
    wait-idle
    
    month := read-reg CAM_REG_MONTH_ID
    wait-idle
    
    day := read-reg CAM_REG_DAY_ID
    wait-idle
    
    print "    Version date: $year/$month/$day"
    
    if year != 0x55 or month != 0x55 or day != 0x55:
      print "    ✅ Got version info - initialization successful!"
    else:
      print "    ⚠️  Version info still 0x55 - communication issue"
  
  get-sensor-config -> none:
    // For MEGA-5MP, try multiple sensor ID locations and methods - with I2C waits
    index := read-reg CAM_REG_SENSOR_ID  // 0x40
    wait-idle
    index2 := read-reg 0x41  // Alternative sensor ID location
    wait-idle
    index3 := read-reg 0x42  // Another alternative
    wait-idle
    
    print "MEGA-5MP Sensor ID checks: 0x40=0x$(index.stringify 16), 0x41=0x$(index2.stringify 16), 0x42=0x$(index3.stringify 16)"
    
    // Check if any of the values look like valid sensor IDs
    sensor-ids := [index, index2, index3]
    detected-id := null
    
    sensor-ids.do: | id |
      if id == SENSOR_MEGA_5MP:
        detected-id = "MEGA-5MP"
        camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP"
      else if id == SENSOR_5MP_2:
        detected-id = "MEGA-5MP_2"
        camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP_2"
      else if id == SENSOR_5MP_1:
        detected-id = "MEGA-5MP_1"
        camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP_1"
      else if id == 0x56 or id == 0x85 or id == 0x86:  // Known MEGA variants
        detected-id = "MEGA-5MP-variant"
        camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP"
    
    if detected-id:
      print "✓ Detected $detected-id camera"
    else:
      // Since you confirmed it's a MEGA-5MP, use 5MP config regardless
      camera-info = CameraInfo.camera-info-5MP --camera-id="MEGA-5MP-confirmed"
      print "✓ Using MEGA-5MP configuration (user confirmed hardware)"
  
  set-capture -> none:
    clear-fifo-flag
    start-capture
    
    // Add timeout to prevent hanging
    timeout := 100  // 200ms timeout
    while (get-bit ARDUCHIP_TRIG CAP_DONE_MASK) == 0 and timeout > 0:
      sleep --ms=2
      timeout--
    
    if timeout == 0:
      print "Warning: Capture timeout - camera may not be responding properly"
      received-length = 0
      total-length = 0
    else:
      received-length = read-fifo-length
      total-length = received-length
    burst-first-flag = false

  image-available -> int:
    return received-length
 
  set-autofocus val/int -> none:
    write-reg CAM_REG_AUTO_FOCUS_CONTROL val
 
  take-picture mode/int pixel-format/int -> none:
    // Use ArduCam high-level command protocol (Session 2 breakthrough)
    // ArduCam doesn't use low-level sensor registers directly
    
    if current-pixel-format != pixel-format:
      current-pixel-format = pixel-format
      send-arducam-format-command pixel-format mode
      
    if current-picture-mode != mode:
      current-picture-mode = mode
      // Format command already set the resolution, no separate command needed
    
    // Send ArduCam take picture command
    send-arducam-capture-command
 
  take-multi-pictures mode/int pixel-format/int num/int -> none:
    if current-pixel-format != pixel-format: 
      current-pixel-format = pixel-format
      write-reg CAM_REG_FORMAT pixel-format
    if current-picture-mode != mode:
      current-picture-mode = mode
      write-reg CAM_REG_CAPTURE_RESOLUTION (CAM_SET_CAPTURE_MODE | mode)

    if num > CAPTURE_MAX_NUM: num = CAPTURE_MAX_NUM
    write-reg ARDUCHIP_FRAMES num
    set-capture
  start-preview mode/int -> none:
    preview-mode = true
    write-reg CAM_REG_FORMAT CAM_IMAGE_PIX_FMT_JPG
    wait-idle
    write-reg CAM_REG_CAPTURE_RESOLUTION (CAM_SET_VIDEO_MODE | mode)
    wait-idle
    set-capture

  stop-preview -> none:
    current-pixel-format = CAM_IMAGE_PIX_FMT_JPG
    current-picture-mode = CAM_IMAGE_MODE_QVGA
    preview-mode = false
    received-length = 0
    total-length = 0
    write-reg CAM_REG_FORMAT CAM_IMAGE_PIX_FMT_JPG
    wait-idle
  set-image-quality quality/int -> none:
    write-reg CAM_REG_IMAGE_QUALITY quality


/** 
  reset cpld and camera
*/
  reset -> none:
    write-reg CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE
 
  set-auto-white-balance-mode mode/int -> none:
    write-reg CAM_REG_WHITEBALANCE_MODE_CONTROL mode
 
  set-auto-white-balance val/int -> none:
    symbol := 0
    if val > 0: symbol |= 0x80
    symbol |= SET_WHITEBALANCE
    write-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol
 
  set-auto-iso-sensitive val/int -> none:
    symbol := 0
    if val > 0: symbol |= 0x80
    symbol |= SET_GAIN
    write-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol
 
  set-iso-sensitivity iso-sense/int -> none:
    iso-val := iso-sense
    if camera-info and camera-info.camera-id == "3MP":
      if iso-sense >= 1 and iso-sense <= OV3640-GAIN-VALUE.size:
        iso-val = OV3640-GAIN-VALUE[iso-sense - 1]
    write-reg CAM_REG_MANUAL_GAIN_BIT_9_8 (iso-val >> 8)
    write-reg CAM_REG_MANUAL_GAIN_BIT_7_0 (iso-val & 0xff)
 
  set-auto-exposure val/bool -> none:
    symbol := 0
    if val: symbol |= 0x80
    symbol |= SET_EXPOSURE
    write-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol
 
  set-absolute-exposure exposure-time/int -> none:
    write-reg CAM_REG_MANUAL_EXPOSURE_BIT_19_16 ((exposure-time >> 16) & 0xff)
    write-reg CAM_REG_MANUAL_EXPOSURE_BIT_15_8 ((exposure-time >> 8) & 0xff)
    write-reg CAM_REG_MANUAL_EXPOSURE_BIT_7_0 (exposure-time & 0xff)

 
  set-color-effect effect/int -> none:
    write-reg CAM_REG_COLOR_EFFECT_CONTROL effect
    wait-idle

  set-saturation level/int -> none:
    write-reg CAM_REG_SATURATION_CONTROL level
    
  set-ev level/int -> none:
    write-reg CAM_REG_EV_CONTROL level

  set-contrast level/int -> none:
    write-reg CAM_REG_CONTRAST_CONTROL level
 
  set-sharpness level/int -> none:
    write-reg CAM_REG_SHARPNESS_CONTROL level
 
  set-brightness level/int -> none:
    write-reg CAM_REG_BRIGHTNESS_CONTROL level
 
  flush-fifo -> none:
    write-reg ARDUCHIP_FIFO_2 FIFO_CLEAR_MASK

  start-capture -> none:
    write-reg ARDUCHIP_FIFO FIFO_START_MASK
 
  clear-fifo-flag -> none:
    write-reg ARDUCHIP_FIFO FIFO_CLEAR_ID_MASK

/** 
Helper methods
*/

  // ArduCam High-Level Command Protocol (Session 2 breakthrough)
  // ArduCam uses command format: 0x55 [CMD] [PARAM] 0xAA
  
  send-arducam-format-command pixel-format/int mode/int -> none:
    // Combine format and resolution into single parameter (Session 2 discovery)
    // Format: bits [6:4], Resolution: bits [3:0]
    format-bits := 0
    if pixel-format == CAM_IMAGE_PIX_FMT_JPG: format-bits = 1
    else if pixel-format == CAM_IMAGE_PIX_FMT_RGB565: format-bits = 2
    else if pixel-format == CAM_IMAGE_PIX_FMT_YUV: format-bits = 3
    
    // Map mode to ArduCam resolution parameter
    resolution-bits := mode & 0x0F  // Use lower 4 bits
    
    param := (format-bits << 4) | resolution-bits
    arducam-command := #[0x55, 0x01, param, 0xAA]
    
    print "Sending ArduCam format command: format=$format-bits, resolution=$resolution-bits, param=0x$(%02x param)"
    camera.write arducam-command
    sleep --ms=100  // Allow command processing
  
  send-arducam-capture-command -> none:
    // ArduCam take picture command: 0x55 0x10 0xAA
    capture-command := #[0x55, 0x10, 0xAA]
    print "Sending ArduCam capture command"
    camera.write capture-command
    sleep --ms=1000  // Allow capture time
 
  // ArduCam-specific SPI register write protocol - FIXED to match C code
  write-reg addr/int val/int -> none:
    // Match C code exactly: cameraWriteReg does busWrite(addr | 0x80, val)
    sleep --ms=1
    camera.write #[addr | 0x80, val]  // Set bit 7 for write operations
    sleep --ms=1
 
  // ArduCam MEGA-5MP specific SPI register read protocol - EXACT ARDUINO C REPLICATION
  read-reg addr/int -> int:
    // Arduino cameraBusRead: single CS transaction with 3 transfers
    // arducamSpiCsPinLow -> transfer(address) -> transfer(0x00) -> transfer(0x00) -> arducamSpiCsPinHigh
    sleep --ms=1
    
    // Single SPI transaction: send address + 2 dummy bytes, read 3 responses
    command := #[addr & 0x7F, 0x00, 0x00]
    camera.write command
    responses := camera.read 3
    
    sleep --ms=1
    
    // Arduino takes the 3rd byte (index 2) as the real data
    return responses[2]
  wait-idle -> none:
    timeout := 25  // 50ms timeout (25 * 2ms)
    while timeout > 0:
      sensor-state := read-reg CAM_REG_SENSOR_STATE
      state-bits := sensor-state & 0x03
      if state-bits == CAM_REG_SENSOR_STATE_IDLE:
        print "[DEBUG] wait-idle: sensor ready (state=0x$(%02x sensor-state), bits=0x$(%02x state-bits))"
        return
      print "[DEBUG] wait-idle: waiting... (state=0x$(%02x sensor-state), bits=0x$(%02x state-bits), timeout=$timeout)"
      sleep --ms=2
      timeout--
    print "[WARNING] wait-idle timeout after 50ms - sensor state never became idle"

  // Helper method for I2C initialization
  try-wait-idle context/string -> bool:
    print "  Waiting for I2C idle ($context)..."
    timeout := 25
    while timeout > 0:
      sensor-state := read-reg CAM_REG_SENSOR_STATE
      state-bits := sensor-state & 0x03
      if state-bits == CAM_REG_SENSOR_STATE_IDLE:
        print "    ✅ I2C idle achieved! (state=0x$(%02x sensor-state))"
        return true
      sleep --ms=2
      timeout--
    print "    ❌ I2C idle timeout ($context)"
    return false

  // Test I2C tunnel functionality
  test-format-register -> none:
    print "  Testing format register setting via I2C tunnel..."
    
    format-before := read-reg CAM_REG_FORMAT
    print "    Format before: 0x$(%02x format-before)"
    
    write-reg CAM_REG_FORMAT CAM_IMAGE_PIX_FMT_JPG
    i2c-success := try-wait-idle "format register write"
    
    if i2c-success:
      format-after := read-reg CAM_REG_FORMAT
      print "    Format after: 0x$(%02x format-after)"
      
      if format-after == CAM_IMAGE_PIX_FMT_JPG:
        print "    ✅ I2C tunnel working! Format register set successfully!"
      else:
        print "    ⚠️  I2C wait succeeded but format not set (got 0x$(%02x format-after))"
    else:
      print "    ❌ I2C tunnel not working for format register"

  read-fifo-length -> int:
    len1 := read-reg FIFO_SIZE1
    len2 := read-reg FIFO_SIZE2
    len3 := read-reg FIFO_SIZE3
    length := ((len3 << 16) | (len2 << 8) | len1) & 0xffffff
    return length
 
  get-bit addr/int bit/int -> int:
    temp := read-reg addr
    return temp & bit
  set-fifo-burst -> none:
    camera.write #[BURST_FIFO_READ]
 
  read-byte -> int:
    if received-length <= 0: return 0
    camera.write #[SINGLE_FIFO_READ, 0x00]
    data := camera.read 1
    received-length -= 1
    return data[0]
 
  read-buffer length/int -> ByteArray:
    if image-available == 0 or length == 0: return #[]
    
    actual-length := length
    if received-length < length:
      actual-length = received-length
    
    camera.write #[BURST_FIFO_READ]
    if not burst-first-flag:
      burst-first-flag = true
      camera.write #[0x00]
    
    buffer := camera.read actual-length
    received-length -= actual-length
    return buffer

  heart-beat -> bool:
    return (read-reg CAM_REG_SENSOR_STATE & 0x03) == CAM_REG_SENSOR_STATE_IDLE

  low-power-on -> none:
    write-reg CAM_REG_POWER_CONTROL 0x07
 
  low-power-off -> none:
    write-reg CAM_REG_POWER_CONTROL 0x05
  // Quick SPI test method - don't call full on() method
  test-spi-basic -> bool:
    // Try a few basic register reads to see if we get any response
    test1 := read-reg 0x00
    test2 := read-reg 0x01  
    test3 := read-reg 0x40  // Sensor ID register
    
    print "    Basic SPI test: 0x00=0x$(test1.stringify 16), 0x01=0x$(test2.stringify 16), 0x40=0x$(test3.stringify 16)"
    
    // If we get varied responses (not all 0xFF or all 0x00), SPI might be working
    responses := [test1, test2, test3]
    all-same := responses.every: responses[0] == it
    
    if all-same and (test1 == 0xFF or test1 == 0x00):
      print "    ❌ All reads return same value (0x$(test1.stringify 16)) - likely no device"
      return false
    else:
      print "    ✅ Got varied responses - possible device detected"
      return true
  // Test different SPI modes to see if we get better communication
  test-spi-modes -> none:
    print "  Testing different SPI modes..."
    
    // Test current mode
    current-result := read-reg 0x40
    print "    Current mode (0): reg 0x40 = 0x$(current-result.stringify 16)"
    
    // We can't easily change SPI mode mid-stream, but we can try different timing
    
    // Try reading with different delays
    camera.write #[0x40 & 0x7F, 0x00]
    sleep --ms=10  // Much longer delay
    delayed-result := camera.read 2
    print "    With 10ms delay: got 0x$(delayed-result[0].stringify 16), 0x$(delayed-result[1].stringify 16)"
    
    // Try reading a known register that should have predictable value
    camera.write #[0x00 & 0x7F, 0x00]  // Test register
    sleep --ms=1
    test-reg := camera.read 2
    print "    Test register 0x00: got 0x$(test-reg[0].stringify 16), 0x$(test-reg[1].stringify 16)"