// Basic SPI connectivity test with proper camera initialization

import arducam_mega show *
import spi
import gpio

main:
  print "=== 01: BASIC SPI CONNECTIVITY (FIXED) ==="
  print "Testing SPI communication with proper camera initialization..."
  
  try:
    // Step 1: Initialize camera first
    print "\nStep 1: Initializing camera..."
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ SPI device created on CS pin 22"
    
    print "Executing camera initialization sequence..."
    camera.on  // This runs the C code initialization sequence
    print "✅ Camera initialization complete"
    
    // Step 2: Test register communication after initialization
    print "\nStep 2: Testing register reads after initialization..."
    registers := [0x00, 0x01, 0x40, 0x44, 0x45]
    print "Testing register reads:"
    all-same := true
    first-val := null
    
    registers.do: | reg |
      val := camera.read-reg reg
      if first-val == null: first-val = val
      else if val != first-val: all-same = false
      
      print "  Register 0x$(%02x reg): 0x$(%02x val)"
    
    // Analyze results
    if all-same and first-val == 0x00:
      print "\n⚠️  All registers return 0x00 after initialization"
      print "  This may indicate camera needs additional setup"
    else if all-same and first-val == 0x55:
      print "\n❌ CRITICAL: All registers still return 0x55"
      print "  Initialization did not fix communication issue"
    else if all-same:
      print "\n⚠️  All registers return same value (0x$(%02x first-val))"
      print "  Device may need different initialization sequence"
    else:
      print "\n✅ SUCCESS: Varied register responses detected!"
      print "  Hardware communication is working after initialization"
      
      // Test some key registers for expected values
      sensor-id := camera.read-reg 0x40
      if sensor-id != 0x00 and sensor-id != 0x55:
        print "  🎉 SENSOR ID: 0x$(%02x sensor-id) - Real hardware response!"
    
    // Step 3: Test ArduCam command protocol
    print "\nStep 3: Testing ArduCam command protocol..."
    camera.send-arducam-format-command CAM_IMAGE_PIX_FMT_JPG CAM_IMAGE_MODE_QVGA
    print "✅ Format command sent successfully"
    
    print "\n=== SPI CONNECTIVITY TEST COMPLETE ==="
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"

// Constants needed
CAM_IMAGE_PIX_FMT_JPG ::= 1
CAM_IMAGE_MODE_QVGA ::= 0x01
