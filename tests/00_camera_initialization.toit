// 00: Camera Initialization - The very first test
// This test focuses solely on getting the camera properly initialized

import arducam_mega show *
import spi
import gpio

main:
  print "=== 00: CAMERA INITIALIZATION ==="
  print "This is the foundational test - initializing the ArduCam..."
  
  try:
    print "\nStep 1: Creating SPI bus and camera instance..."
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera instance created successfully"
    
    print "\nStep 2: Testing state before initialization..."
    test-reg-before := camera.read-reg 0x00
    sensor-id-before := camera.read-reg 0x40
    state-before := camera.read-reg 0x44
    print "  Before init - Test reg: 0x$(%02x test-reg-before), Sensor ID: 0x$(%02x sensor-id-before), State: 0x$(%02x state-before)"
    
    print "\nStep 3: Executing camera initialization sequence..."
    print "  Running camera.on() - C code initialization sequence..."
    camera.on
    print "✅ Initialization sequence completed"
    
    print "\nStep 4: Testing state after initialization..."
    test-reg-after := camera.read-reg 0x00
    sensor-id-after := camera.read-reg 0x40
    state-after := camera.read-reg 0x44
    year := camera.read-reg 0x41
    month := camera.read-reg 0x42
    day := camera.read-reg 0x43
    
    print "  After init - Test reg: 0x$(%02x test-reg-after), Sensor ID: 0x$(%02x sensor-id-after), State: 0x$(%02x state-after)"
    print "  Version info: $year/$month/$day"
    
    print "\nStep 5: Analyzing initialization results..."
    
    // Check if values changed
    if test-reg-before != test-reg-after or sensor-id-before != sensor-id-after:
      print "✅ REGISTER VALUES CHANGED - Initialization had effect!"
    else:
      print "⚠️  Register values unchanged - may need different approach"
    
    // Check for real sensor communication
    if sensor-id-after != 0x00 and sensor-id-after != 0x55 and sensor-id-after != 0xFF:
      print "🎉 REAL SENSOR ID DETECTED: 0x$(%02x sensor-id-after)"
      print "  ✅ INITIALIZATION SUCCESS - Real hardware communication!"
    else if sensor-id-after == 0x00:
      print "⚠️  Sensor ID still 0x00 - camera may need additional setup"
    else:
      print "❌ Sensor ID still problematic: 0x$(%02x sensor-id-after)"
    
    // Check version info
    if year != 0 and month != 0 and day != 0:
      print "✅ VERSION INFO AVAILABLE - I2C communication working!"
    else:
      print "⚠️  Version info not available - I2C tunnel issue"
    
    print "\nStep 6: Testing basic ArduCam commands..."
    camera.send-arducam-format-command CAM_IMAGE_PIX_FMT_JPG CAM_IMAGE_MODE_QVGA
    print "✅ Format command sent"
    
    fifo-size := camera.read-fifo-length
    print "  Initial FIFO size: $fifo-size bytes"
    
    print "\n=== INITIALIZATION ASSESSMENT ==="
    
    if sensor-id-after != 0x00 and sensor-id-after != 0x55:
      print "🎉 FULL SUCCESS: Camera fully initialized and communicating!"
    else if test-reg-before != test-reg-after:
      print "⚠️  PARTIAL SUCCESS: Init sequence works but needs more setup"
    else:
      print "❌ INITIALIZATION FAILED: No communication established"
    
    print "\n=== 00: CAMERA INITIALIZATION COMPLETE ==="
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception during initialization: $exception"

// Constants
CAM_IMAGE_PIX_FMT_JPG ::= 1
CAM_IMAGE_MODE_QVGA ::= 0x01
