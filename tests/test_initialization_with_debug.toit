import gpio
import spi
import system

// Import the actual ArduCam library
import arducam_mega show *

main:
  print "=== Full Initialization Debug Test ==="
  
  // Initialize SPI and camera
  spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
  cs := gpio.Pin 22
  camera := ArducamCamera --spi-bus=spi-bus --cs=cs
  
  print "\n1. Camera object created successfully"
  
  print "\n2. Attempting camera initialization (camera.on)..."
  
  try:
    camera.on
    print "  ✅ camera.on() completed without exception"
    
    print "\n3. Testing basic register reads after initialization..."
    
    // Test reading the sensor ID
    sensor-id := camera.read-fpga-reg 0x40
    print "  Sensor ID: 0x$(%02x sensor-id)"
    
    // Test reading version info
    year := camera.read-fpga-reg 0x41
    month := camera.read-fpga-reg 0x42
    day := camera.read-fpga-reg 0x43
    fpga-version := camera.read-fpga-reg 0x49
    
    print "  Version info: $year/$month/$day, FPGA: 0x$(%02x fpga-version)"
    
    // Test the critical I2C address register
    i2c-addr := camera.read-fpga-reg 0x0A
    print "  I2C address register: 0x$(%02x i2c-addr) (expected: 0x78)"
    
    print "\n4. Summary:"
    
    if sensor-id == 0x56:
      print "  ✅ Sensor ID correct - camera is MEGA-5MP and responding"
    else:
      print "  ❌ Sensor ID incorrect - got 0x$(%02x sensor-id), expected 0x56"
    
    if i2c-addr == 0x78:
      print "  ✅ I2C address set correctly"
    else:
      print "  ❌ I2C address not set - got 0x$(%02x i2c-addr), expected 0x78"
    
    all-zero := (sensor-id == 0x00 and year == 0x00 and month == 0x00 and day == 0x00 and fpga-version == 0x00)
    
    if all-zero:
      print "  ⚠️ All registers return 0x00 - device responding but not communicating"
      print "     This suggests:"
      print "     - SPI communication works (no random values)"
      print "     - ArduCam is not properly initialized"
      print "     - Missing activation sequence or timing issue"
    else:
      print "  ✅ Some registers have non-zero values - communication working"
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Exception during initialization: $exception"
      print "     This suggests:"
      print "     - Hardware connection issue"
      print "     - SPI configuration problem"
      print "     - Library bug"
  
  print "\n=== Test Complete ==="
