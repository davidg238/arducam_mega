// 02: Simple initialization test

import arducam_mega show *
import spi
import gpio

main:
  print "=== 02: INITIALIZATION SIMPLE ==="
  print "Testing basic camera initialization..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    print "\nInitializing camera..."
    camera.on
    print "✅ Camera initialization completed"
    
    print "\nTesting basic status..."
    // Test if basic register reads work
    test-reg := camera.read-reg 0x00
    print "  Status register (0x00): 0x$(%02x test-reg)"
    
    // Test FIFO system
    fifo-size := camera.read-fifo-length
    print "  FIFO length: $fifo-size bytes"
    
    if test-reg == 0x55:
      print "\n⚠️  Still getting 0x55 responses"
      print "  Camera initialized but hardware communication limited"
    else:
      print "\n✅ SUCCESS: Camera responding with varied data"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception during initialization: $exception"
  
  print "\n=== 02: INITIALIZATION SIMPLE COMPLETE ==="
