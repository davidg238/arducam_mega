import spi
import gpio
 
 /**
  Camera status
  */
CAM_ERR_SUCCESS     ::= 0  /**<Operation succeeded*/
CAM_ERR_NO_CALLBACK ::= -1 /**< No callback function is registered*/

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

/*TODO 
 typedef uint8_t (*BUFFER_CALLBACK)(uint8_t* buffer, uint8_t lenght); /**<Callback function prototype  */
 typedef void (*STOP_HANDLE)(void);                                   /**<Callback function prototype  */

 uint8_t cameraHeartBeat(ArducamCamera* camera);
 */
 
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
CAM_REG_SENSOR_RESET ::=                       0X07
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
CAM_REG_YEAR_ID ::=                            0x41
CAM_REG_MONTH_ID ::=                           0x42
CAM_REG_DAY_ID ::=                             0x43
CAM_REG_SENSOR_STATE ::=                       0x44
CAM_REG_FPGA_VERSION_NUMBER ::=                0x49
CAM_REG_DEBUG_DEVICE_ADDRESS ::=               0X0A
CAM_REG_DEBUG_REGISTER_HIGH ::=                0X0B
CAM_REG_DEBUG_REGISTER_LOW ::=                 0X0C
CAM_REG_DEBUG_REGISTER_VALUE ::=               0X0D
 
CAM_REG_SENSOR_STATE_IDLE ::=                  (1 << 1)
CAM_SENSOR_RESET_ENABLE ::=                    (1 << 6)
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
 
/*TODO 
 struct cameraDefaultState {
     uint8_t cameraDefaultFormat;
     uint8_t cameraDefaultResolution;
 };
*/ 
 
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
 
/*TODO 
 struct CameraInfo* CameraType[CAMERA_TYPE_NUMBER];
 // struct cameraDefaultState DefaultState_5mp = {
 //     .cameraDefaultFormat = CAM_IMAGE_PIX_FMT_JPG,
 //     .cameraDefaultResolution = CAM_IMAGE_MODE_WQXGA2,
 // };
 
 // struct cameraDefaultState DefaultState_3mp = {
 //     .cameraDefaultFormat = CAM_IMAGE_PIX_FMT_JPG,
 //     .cameraDefaultResolution = CAM_IMAGE_MODE_QXGA,
 // };
 

 */

class ArducamCamera:
  cs  /gpio.Pin                                      /**< CS pin */
  spi-bus / spi.Bus
  camera /spi.Device
  registers /spi.Registers

  camera-id /string?                               /**< Model of camera module */

  total-length /int       := -1                        /**< The total length of the picture */
  received-length /int    := -1                        /**< The remaining length of the picture */
  // uint8_t cameraDataFormat;                       /**< The currently set image pixel format */
  burst-first-flag /bool  := false                        /**< Flag bit for reading data for the first time in burst mode */
  preview-mode /bool      := false                       /**< Stream mode flag */
  current-pixel-format /int := -1                     /**< The currently set image pixel format */
  current-picture-mode /int := -1                      /**< Currently set resolution */
  camera-info /CameraInfo? := null                 /**< Basic information of the current camera */
  ver-date-and-number /List := [1970, 1, 1, 0]          /**< Version information of the camera module */
  
  // BUFFER_CALLBACK callBackFunction               /**< Camera callback function */
  // STOP_HANDLE handle
  // blockSize /int                              /**< The length of the callback function transmission */
  
  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin:
    camera = spi-bus.device --cs=cs --frequency=8_000_000  // Use 8MHz for better compatibility
    camera-id = ""
    current-pixel-format = CAM_IMAGE_PIX_FMT_NONE
    current-picture-mode = CAM_IMAGE_MODE_NONE

  on -> none:
    print "Camera init"
    // Reset CPLD and camera
    write-reg CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE
    sleep --ms=100  // Give time for reset
    
    get-sensor-config
    
    // Read version information
    ver-date-and-number[0] = read-reg CAM_REG_YEAR_ID & 0x3F       // year
    ver-date-and-number[1] = read-reg CAM_REG_MONTH_ID & 0x0F      // month
    ver-date-and-number[2] = read-reg CAM_REG_DAY_ID & 0x1F        // day
    ver-date-and-number[3] = read-reg CAM_REG_FPGA_VERSION_NUMBER & 0xFF  // version

    print "Camera date $ver-date-and-number[0] $ver-date-and-number[1] $ver-date-and-number[2] version $ver-date-and-number[3]"
    
    if camera-info:
      write-reg CAM_REG_DEBUG_DEVICE_ADDRESS camera-info.device-address
  
  get-sensor-config -> none:
    index := read-reg CAM_REG_SENSOR_ID
    print "Sensor ID: 0x$(index.stringify 16)"
    
    if index == SENSOR_5MP_2:
      camera-info = CameraInfo.camera-info-5MP --camera-id="5MP_2"
      print "Detected 5MP_2 camera"
    else if index == SENSOR_5MP_1: 
      camera-info = CameraInfo.camera-info-5MP
      print "Detected 5MP_1 camera"
    else:
      camera-info = CameraInfo.camera-info-3MP
      print "Detected 3MP camera (default)"
  
  set-capture -> none:
    // flushFifo(camera);
    clear-fifo-flag
    start-capture
    while (getBit ARDUCHIP_TRIG CAP_DONE_MASK == 0):
      sleep --ms=2
    received-length = readFifoLength;
    total-length    = received-length;
    burst-first-flag = false

  image-available -> int:
    return received-length
 
  set-autofocus val/int -> none:
    write-reg CAM_REG_AUTO_FOCUS_CONTROL val
 
  take-picture mode/int pixel-format/int -> none:
    if current-pixel-format != pixel-format:
      current-pixel-format = pixel-format
      write-reg CAM_REG_FORMAT pixel-format
    if current-picture-mode != mode:
      current-picture-mode = mode
      write-reg CAM_REG_CAPTURE_RESOLUTION (CAM_SET_CAPTURE_MODE | mode)
    set-capture
 
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
 /*TODO
  register-callback BUFFER_CALLBACK function, uint8_t size, STOP_HANDLE handle)
 {
     camera->callBackFunction = function;
     camera->blockSize        = size;
     camera->handle           = handle;
 }
 */

 /*TODO preview-mode
  start-preview mode/int -> none:
    // camera->cameraDataFormat = CAM_IMAGE_PIX_FMT_JPG;
    preview-mode = TRUE
    if (null == callback): throw "callback function is null"
    writeReg CAM_REG_FORMAT CAM_IMAGE_PIX_FMT_JPG // set  jpeg format
    waitI2cIdle
    writeReg CAM_REG_CAPTURE_RESOLUTION (CAM_SET_VIDEO_MODE | mode) // set  video mode
    waitI2cIdle
    setCapture


 static uint8_t callBackBuff[PREVIEW_BUF_LEN];
 
 void cameraCaptureThread(ArducamCamera* camera)
 {
     if (camera->previewMode) {
         uint8_t callBackLength = readBuff(camera, callBackBuff, camera->blockSize);
         if (callBackLength != FALSE) {
             camera->callBackFunction(callBackBuff, callBackLength);
         } else {
             setCapture(camera);
         }
     }
 }
 
 CamStatus cameraStopPreview(ArducamCamera* camera)
 {
     if (camera->previewMode == TRUE && camera->handle != 0) {
         camera->handle();
     }
 
     camera->currentPixelFormat = CAM_IMAGE_PIX_FMT_JPG;
     camera->currentPictureMode = CAM_IMAGE_MODE_QVGA;
     camera->previewMode        = FALSE;
     camera->receivedLength     = 0;
     camera->totalLength        = 0;
     writeReg(camera, CAM_REG_FORMAT, CAM_IMAGE_PIX_FMT_JPG); // set  jpeg format
     waitI2cIdle(camera);                                     // Wait I2c Idle
     return CAM_ERR_SUCCESS;
 }
 */
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
    if val: symbol |= 0x80
    symbol |= SET_WHITEBALANCE
    write-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol
 
  set-auto-iso-sensitive val/int -> none:
    symbol := 0
    if val: symbol |= 0x80
    symbol |= SET_GAIN
    write-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol
 
  camera-set-iso-sensitivity iso_sense/int -> none:
    if (camera-id == SENSOR_3MP_1):
        iso_sense = OV3640-GAIN-VALUE[iso_sense - 1];
    registers.write-u8 CAM_REG_MANUAL_GAIN_BIT_9_8 (iso_sense >> 8) // set AGC VALUE
    registers.write-u8 CAM_REG_MANUAL_GAIN_BIT_7_0 (iso_sense & 0xff)
 
  camera-set-auto-exposure val/bool -> none:
    symbol := 0
    if val: symbol |= 0x80
    symbol |= SET_EXPOSURE;
    registers.write-u8 CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL symbol    // auto EXPOSURE control
 
  camera-set-absolute-exposure exposure_time/int -> none:
     // set exposure output [19:16]
    registers.write-u8 CAM_REG_MANUAL_EXPOSURE_BIT_19_16 ((exposure_time >> 16) & 0xff)
    // set exposure output [15:8]
    registers.write-u8 CAM_REG_MANUAL_EXPOSURE_BIT_15_8 ((exposure_time >> 8) & 0xff)
    // set exposure output [7:0]
    registers.write-u8 CAM_REG_MANUAL_EXPOSURE_BIT_7_0  (exposure_time & 0xff)

 
  set-color-effect effect/int -> none:
    registers.write-u8 CAM_REG_COLOR_EFFECT_CONTROL effect // set effect
    wait-idle

  camera-set-saturation level/int -> none:
    registers.write-u8 CAM_REG_SATURATION_CONTROL level // set Saturation Level
    
  camera-set-ev level/int -> none:
    registers.write-u8 CAM_REG_EV_CONTROL level // set Exposure  Compensation Level

  camera-set-contrast level/int -> none:
    registers.write-u8 CAM_REG_CONTRAST_CONTROL level // set Contrast Level
 
  set-sharpness level/int -> none:
    registers.write-u8 CAM_REG_SHARPNESS_CONTROL level // set Brightness Level
 
  set-brightness level/int -> none:
    registers.write-u8 CAM_REG_BRIGHTNESS_CONTROL level // set Brightness Level
 
  flush-fifo -> none:
    registers.write-u8 ARDUCHIP_FIFO_2 FIFO_CLEAR_MASK

  start-capture -> none:
    registers.write-u8 ARDUCHIP_FIFO_2 FIFO_START_MASK
 
  clear-fifo-flag -> none:
    registers.write-u8 ARDUCHIP_FIFO_2 FIFO_CLEAR_ID_MASK

/** 
Helper methods
*/

  wait-idle -> none:
    while ((registers.read-u8 CAM_REG_SENSOR_STATE) & 0X03) != CAM_REG_SENSOR_STATE_IDLE:
      sleep --ms=2

  readFifoLength(ArducamCamera* camera)
 {
     uint32_t len1, len2, len3, length = 0;
     len1   = readReg(camera, FIFO_SIZE1);
     len2   = readReg(camera, FIFO_SIZE2);
     len3   = readReg(camera, FIFO_SIZE3);
     length = ((len3 << 16) | (len2 << 8) | len1) & 0xffffff;
     return length;
 }
 
 uint8_t cameraGetBit(ArducamCamera* camera, uint8_t addr, uint8_t bit)
 {
     uint8_t temp;
     temp = readReg(camera, addr);
     temp = temp & bit;
     return temp;
 }
 
  camera-set-fifo-burst -> none:
    arducamSpiTransfer BURST_FIFO_READ
 
  read-byte -> uint8_t:
 {
     uint8_t data = 0;
     arducamSpiCsPinLow(camera->csPin);
     arducamSpiTransfer(SINGLE_FIFO_READ);
     arducamSpiTransfer(0x00);
     data = arducamSpiTransfer(0x00);
     arducamSpiCsPinHigh(camera->csPin);
     camera->receivedLength -= 1;
     return data;
 }
 
 uint32_t cameraReadBuff(ArducamCamera* camera, uint8_t* buff, uint32_t length)
 
 {
     if (imageAvailable(camera) == 0 || (length == 0)) {
         return 0;
     }
 
     if (camera->receivedLength < length) {
         length = camera->receivedLength;
     }
 
     arducamSpiCsPinLow(camera->csPin);
     setFifoBurst(camera);
     if (camera->burstFirstFlag == 0) {
         camera->burstFirstFlag = 1;
         arducamSpiTransfer(0x00);
     }
 
 #ifndef arducamSpiReadBlock
     for (uint32_t count = 0; count < length; count++) {
         buff[count] = arducamSpiTransfer(0x00);
     }
 #else
     arducamSpiReadBlock(buff, length);
 #endif
     arducamSpiCsPinHigh(camera->csPin);
     camera->receivedLength -= length;
     return length;
 }
 
  writeReg addr/int val/int -> none:
   busWrite (addr | 0x80) val
 
 uint8_t cameraReadReg(ArducamCamera* camera, uint8_t addr)
 {
     uint8_t data;
     data = busRead(camera, addr & 0x7F);
     return data;
 }
 
 uint8_t cameraBusWrite(ArducamCamera* camera, int address, int value)
 {
     arducamSpiCsPinLow(camera->csPin);
     arducamSpiTransfer(address);
     arducamSpiTransfer(value);
     arducamSpiCsPinHigh(camera->csPin);
     arducamDelayMs(1);
     return 1;
 }
 
 void cameraCsHigh(ArducamCamera* camera)
 {
     arducamSpiCsPinHigh(camera->csPin);
 }
 void cameraCsLow(ArducamCamera* camera)
 {
     arducamSpiCsPinLow(camera->csPin);
 }
 
 uint8_t cameraBusRead(ArducamCamera* camera, int address)
 {
     uint8_t value;
     arducamSpiCsPinLow(camera->csPin);
     arducamSpiTransfer(address);
     value = arducamSpiTransfer(0x00);
     value = arducamSpiTransfer(0x00);
     arducamSpiCsPinHigh(camera->csPin);
     return value;
 }
 

 
 uint8_t cameraHeartBeat(ArducamCamera* camera)
 {
     return (readReg(camera, CAM_REG_SENSOR_STATE) & 0X03) == CAM_REG_SENSOR_STATE_IDLE;
 }
 
 void cameraDebugWriteRegister(ArducamCamera* camera, uint8_t* buff)
 {
     uint8_t register_high = buff[0];
     uint8_t register_low  = buff[1];
     uint8_t value         = buff[2];
     writeReg(camera, CAM_REG_DEBUG_REGISTER_HIGH, register_high);
     writeReg(camera, CAM_REG_DEBUG_REGISTER_LOW, register_low);
     writeReg(camera, CAM_REG_DEBUG_REGISTER_VALUE, value);
 }
 
 void cameraLowPowerOn(ArducamCamera* camera)
 {
     writeReg(camera, CAM_REG_POWER_CONTROL, 0X07);
 }
 
 void cameraLowPowerOff(ArducamCamera* camera)
 {
     writeReg(camera, CAM_REG_POWER_CONTROL, 0X05);
 }
 
 
 
  // ArduCam-specific SPI register write protocol
  write-reg addr/int val/int -> none:
    camera.write #[addr | 0x80, val]
    sleep --ms=1
 
  // ArduCam-specific SPI register read protocol  
  read-reg addr/int -> int:
    camera.write #[addr & 0x7F, 0x00]
    data := camera.read 1
    return data[0]
  wait-idle -> none:
    while (read-reg CAM_REG_SENSOR_STATE & 0x03) != CAM_REG_SENSOR_STATE_IDLE:
      sleep --ms=2

  read-fifo-length -> int:
    len1 := read-reg FIFO_SIZE1
    len2 := read-reg FIFO_SIZE2
    len3 := read-reg FIFO_SIZE3
    length := ((len3 << 16) | (len2 << 8) | len1) & 0xffffff
    return length
 
  get-bit addr/int bit/int -> int:
    temp := read-reg addr
    return temp & bit