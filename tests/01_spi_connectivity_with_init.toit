// 01: SPI Connectivity Test (with proper initialization)

import arducam_mega show *
import spi
import gpio

main:
  print "=== 01: SPI CONNECTIVITY (WITH INIT) ==="
  print "Testing SPI communication after proper camera initialization..."
  
  try:
    // STEP 1: ALWAYS INITIALIZE CAMERA FIRST
    print "\nStep 1: Initializing camera..."
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on  // Initialize camera
    print "✅ Camera initialized"
    
    // STEP 2: TEST SPI CONNECTIVITY
    print "\nStep 2: Testing register communication..."
    registers := [0x00, 0x01, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45]
    
    print "Register values after initialization:"
    values := []
    registers.do: | reg |
      val := camera.read-reg reg
      values.add val
      print "  0x$(%02x reg): 0x$(%02x val)"
    
    // STEP 3: ANALYZE CONNECTIVITY
    print "\nStep 3: Analyzing SPI connectivity..."
    
    unique-values := values.filter: | val | (values.filter: it == val).size == 1
    all-same := values.every: values[0] == it
    
    if all-same:
      if values[0] == 0x00:
        print "⚠️  All registers return 0x00 - may need additional setup"
      else if values[0] == 0x55:
        print "❌ All registers return 0x55 - initialization failed"
      else:
        print "⚠️  All registers return 0x$(%02x values[0]) - unusual but consistent"
    else:
      print "✅ SUCCESS: Varied register responses - SPI working!"
      print "  Unique values found: $(unique-values.size)"
      
      // Check for expected sensor values
      sensor-id := values[2]  // Register 0x40
      if sensor-id == 0x56:  // Expected MEGA-5MP ID
        print "🎉 MEGA-5MP SENSOR DETECTED!"
      else if sensor-id != 0x00 and sensor-id != 0x55:
        print "✅ Real sensor ID detected: 0x$(%02x sensor-id)"
    
    print "\n=== 01: SPI CONNECTIVITY COMPLETE ==="
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
