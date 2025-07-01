// Compare direct SPI vs read-reg function

import arducam_mega show *
import spi
import gpio

main:
  print "=== DIRECT SPI vs READ-REG COMPARISON ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nTesting register 0x00 (test register):"
    test-register camera 0x00 "TEST1"
    
    print "\nTesting register 0x40 (sensor ID):"
    test-register camera 0x40 "SENSOR_ID"
    
    print "\nTesting register 0x44 (sensor state):"
    test-register camera 0x44 "SENSOR_STATE"
    
    print "\nTesting after camera initialization:"
    camera.on
    print "Camera initialized"
    
    print "\nAfter init - Testing register 0x00:"
    test-register camera 0x00 "TEST1_AFTER_INIT"
    
    print "\nAfter init - Testing register 0x44:"
    test-register camera 0x44 "SENSOR_STATE_AFTER_INIT"
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== COMPARISON COMPLETE ==="

test-register camera reg/int name/string -> none:
  print "  Register 0x$(%02x reg) ($name):"
  
  // Method 1: Using camera.read-reg function
  func-result := camera.read-reg reg
  print "    read-reg function: 0x$(%02x func-result)"
  
  // Method 2: Direct SPI - single byte
  camera.camera.write #[reg]
  direct1 := camera.camera.read 1
  print "    direct 1-byte: 0x$(%02x direct1[0])"
  
  // Method 3: Direct SPI - 3 bytes (Arduino style)
  camera.camera.write #[reg, 0x00, 0x00]
  direct3 := camera.camera.read 3
  print "    direct 3-byte: [0x$(%02x direct3[0]), 0x$(%02x direct3[1]), 0x$(%02x direct3[2])]"
  
  // Method 4: Direct SPI - 2 bytes
  camera.camera.write #[reg, 0x00]
  direct2 := camera.camera.read 2
  print "    direct 2-byte: [0x$(%02x direct2[0]), 0x$(%02x direct2[1])]"
  
  // Analysis
  if func-result == direct1[0]:
    print "    ✅ Function matches direct 1-byte"
  else if func-result == direct3[2]:
    print "    ✅ Function matches direct 3-byte[2]"
  else if func-result == direct2[1]:
    print "    ✅ Function matches direct 2-byte[1]"
  else:
    print "    ❌ Function doesn't match any direct method!"
    print "    → Function bug: returning 0x$(%02x func-result) vs direct values"
