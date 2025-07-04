// 02: I2C Tunnel Test (with proper initialization)

import arducam_mega show *
import spi
import gpio

main:
  print "=== 02: I2C TUNNEL (WITH INIT) ==="
  print "Testing I2C tunnel after proper camera initialization..."
  
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
    
    // STEP 2: TEST I2C TUNNEL ESTABLISHMENT
    print "\nStep 2: Testing I2C tunnel functionality..."
    
    // Test sensor state register (should show I2C idle after init)
    state := camera.read-reg 0x44
    print "  Sensor state register: 0x$(%02x state)"
    
    state-bits := state & 0x03
    if state-bits == 0x02:  // CAM_REG_SENSOR_STATE_IDLE
      print "✅ Sensor state shows IDLE - I2C tunnel ready!"
    else:
      print "⚠️  Sensor state: $state-bits (not idle)"
    
    // STEP 3: TEST REGISTER WRITES THROUGH I2C TUNNEL
    print "\nStep 3: Testing I2C register writes..."
    
    // Test format register write
    format-before := camera.read-reg 0x20  // CAM_REG_FORMAT
    print "  Format register before: 0x$(%02x format-before)"
    
    // Try to write JPEG format
    camera.write-reg 0x20 0x01  // Set JPEG format
    
    // Wait for I2C operation
    sleep --ms=10
    
    format-after := camera.read-reg 0x20
    print "  Format register after: 0x$(%02x format-after)"
    
    if format-after == 0x01:
      print "✅ SUCCESS: I2C register write worked!"
    else if format-after != format-before:
      print "⚠️  Register changed but not as expected"
    else:
      print "❌ FAILED: Register write had no effect"
    
    // STEP 4: TEST VERSION REGISTERS (I2C DEPENDENT)
    print "\nStep 4: Testing version registers (I2C dependent)..."
    
    year := camera.read-reg 0x41
    month := camera.read-reg 0x42
    day := camera.read-reg 0x43
    
    print "  Version info: $year/$month/$day"
    
    if year > 0 and month > 0 and day > 0:
      print "✅ SUCCESS: Version info available - I2C working!"
    else:
      print "❌ FAILED: No version info - I2C tunnel not established"
    
    print "\n=== 02: I2C TUNNEL COMPLETE ==="
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
