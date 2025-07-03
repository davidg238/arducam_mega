// Test sensor initialization and I2C tunnel

import arducam_mega show *
import spi
import gpio

main:
  print "=== SENSOR INITIALIZATION TEST ==="
  print "Testing I2C tunnel and sensor initialization..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    // Test basic register reads before initialization
    print "\nTesting basic register reads..."
    test-regs := [0x00, 0x40, 0x41, 0x42, 0x43, 0x44]
    test-regs.do: | reg-addr |
      val := camera.read-reg reg-addr
      print "  Register 0x$(%02x reg-addr): 0x$(%02x val)"
    
    // Initialize camera
    print "\nInitializing camera..."
    camera.on
    print "✅ Camera initialized"
    
    // Test registers again after initialization
    print "\nTesting registers after initialization..."
    test-regs.do: | reg-addr |
      val := camera.read-reg reg-addr
      print "  Register 0x$(%02x reg-addr): 0x$(%02x val)"
    
    // Test sensor state specifically
    print "\nTesting sensor state register (0x44)..."
    for i := 0; i < 10; i++:
      state := camera.read-reg 0x44
      idle-bit := (state & 0x02) != 0
      print "  Read $i: 0x$(%02x state) (idle bit: $idle-bit)"
      sleep --ms=100
    
    // Test if we can write to format register
    print "\nTesting format register write..."
    format-before := camera.read-reg 0x20
    print "  Format before: 0x$(%02x format-before)"
    
    camera.write-reg 0x20 0x01  // JPEG format
    sleep --ms=100
    
    format-after := camera.read-reg 0x20
    print "  Format after: 0x$(%02x format-after)"
    
    if format-after == 0x01:
      print "  ✅ Format register write successful!"
    else:
      print "  ❌ Format register write failed"
    
    // Test if sensor responds to reset
    print "\nTesting sensor reset..."
    state-before := camera.read-reg 0x44
    print "  State before reset: 0x$(%02x state-before)"
    
    camera.write-reg 0x07 0x40  // Reset sensor
    sleep --ms=500
    
    state-after := camera.read-reg 0x44
    print "  State after reset: 0x$(%02x state-after)"
    
    if state-after != state-before:
      print "  ✅ Sensor responds to reset!"
    else:
      print "  ❌ Sensor doesn't respond to reset"
    
    // Test different format values
    print "\nTesting different format values..."
    formats := [0x01, 0x02, 0x03, 0x04]
    formats.do: | fmt |
      camera.write-reg 0x20 fmt
      sleep --ms=100
      readback := camera.read-reg 0x20
      print "  Format 0x$(%02x fmt) -> 0x$(%02x readback)"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== SENSOR INITIALIZATION TEST COMPLETE ==="
