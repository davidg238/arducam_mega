// Simple initialization test focusing on the failing register communication

import arducam_mega show *
import spi
import gpio

main:
  print "Simple initialization test - focusing on register 0x00 communication"
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  try:
    print "Creating ArduCam camera object..."
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    
    print "\n=== BEFORE camera.on() ==="
    
    // Test direct register access before calling camera.on()
    print "Testing direct register reads (before init):"
    reg-00-before := camera.read-reg 0x00
    reg-01-before := camera.read-reg 0x01
    reg-02-before := camera.read-reg 0x02
    print "  0x00: 0x$(%02x reg-00-before)"
    print "  0x01: 0x$(%02x reg-01-before)"
    print "  0x02: 0x$(%02x reg-02-before)"
    
    print "Testing write/read cycle (before init):"
    camera.write-reg 0x00 0xAA
    sleep --ms=10
    readback-before := camera.read-reg 0x00
    print "  Wrote 0xAA to reg 0x00, read back: 0x$(%02x readback-before)"
    
    print "\n=== CALLING camera.on() ==="
    
    // This should run the initialization sequence
    camera.on
    
    print "\n=== AFTER camera.on() ==="
    
    // Test the same registers after initialization
    print "Testing direct register reads (after init):"
    reg-00-after := camera.read-reg 0x00
    reg-01-after := camera.read-reg 0x01
    reg-02-after := camera.read-reg 0x02
    print "  0x00: 0x$(%02x reg-00-after)"
    print "  0x01: 0x$(%02x reg-01-after)"
    print "  0x02: 0x$(%02x reg-02-after)"
    
    print "Testing write/read cycle (after init):"
    camera.write-reg 0x00 0x33
    sleep --ms=10
    readback-after := camera.read-reg 0x00
    print "  Wrote 0x33 to reg 0x00, read back: 0x$(%02x readback-after)"
    
    print "\n=== ANALYSIS ==="
    
    if readback-before == 0xAA:
      print "✓ Register communication worked BEFORE init"
    else:
      print "❌ Register communication failed BEFORE init"
      
    if readback-after == 0x33:
      print "✓ Register communication works AFTER init"
    else:
      print "❌ Register communication still fails AFTER init"
      
    if reg-00-before != reg-00-after:
      print "✓ Register 0x00 changed after init: 0x$(%02x reg-00-before) -> 0x$(%02x reg-00-after)"
    else:
      print "⚠️  Register 0x00 unchanged after init (both 0x$(%02x reg-00-before))"
      
    print "\n=== ADDITIONAL TESTS ==="
    
    // Test version registers that were failing
    ver-41 := camera.read-reg 0x41
    ver-42 := camera.read-reg 0x42
    ver-43 := camera.read-reg 0x43
    ver-49 := camera.read-reg 0x49
    
    print "Version registers after init:"
    print "  0x41 (YEAR): 0x$(%02x ver-41) = $ver-41"
    print "  0x42 (MONTH): 0x$(%02x ver-42) = $ver-42"
    print "  0x43 (DAY): 0x$(%02x ver-43) = $ver-43"
    print "  0x49 (VERSION): 0x$(%02x ver-49) = $ver-49"
    
    if ver-41 == 0 and ver-42 == 0 and ver-43 == 0 and ver-49 == 0:
      print "❌ All version registers still return 0 - init didn't fix the issue"
    else:
      print "✓ Some version registers have non-zero values - partial success!"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ Test failed: $exception"

  print "\nSimple init test complete."
