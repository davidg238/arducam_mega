// Test version register reads - minimal diagnostic

import arducam_mega show *
import spi
import gpio

main:
  print "Testing version register reads..."
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  try:
    print "Initializing camera..."
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    
    print "\n--- Direct Register Reads ---"
    
    // Read the version registers directly
    reg-0x41 := camera.read-reg 0x41
    reg-0x42 := camera.read-reg 0x42
    reg-0x43 := camera.read-reg 0x43
    reg-0x49 := camera.read-reg 0x49
    
    print "Raw register values:"
    print "  0x41 (YEAR_ID): 0x$(%02x reg-0x41) = $reg-0x41"
    print "  0x42 (MONTH_ID): 0x$(%02x reg-0x42) = $reg-0x42"
    print "  0x43 (DAY_ID): 0x$(%02x reg-0x43) = $reg-0x43"
    print "  0x49 (VERSION): 0x$(%02x reg-0x49) = $reg-0x49"
    
    print "\n--- Processed Values (with masks) ---"
    year := reg-0x41 & 0x3F
    month := reg-0x42 & 0x0F
    day := reg-0x43 & 0x1F
    version := reg-0x49 & 0xFF
    
    print "  Year: $year (from 0x$(%02x reg-0x41) & 0x3F)"
    print "  Month: $month (from 0x$(%02x reg-0x42) & 0x0F)"
    print "  Day: $day (from 0x$(%02x reg-0x43) & 0x1F)"
    print "  Version: $version (from 0x$(%02x reg-0x49) & 0xFF)"
    
    print "\n--- Additional Diagnostic Reads ---"
    
    // Test a few more registers to see response pattern
    reg-0x40 := camera.read-reg 0x40  // SENSOR_ID
    reg-0x44 := camera.read-reg 0x44  // SENSOR_STATE
    reg-0x45 := camera.read-reg 0x45  // Test unknown register
    
    print "  0x40 (SENSOR_ID): 0x$(%02x reg-0x40) = $reg-0x40"
    print "  0x44 (SENSOR_STATE): 0x$(%02x reg-0x44) = $reg-0x44"
    print "  0x45 (unknown): 0x$(%02x reg-0x45) = $reg-0x45"
    
    print "\n--- Analysis ---"
    if reg-0x41 == 0 and reg-0x42 == 0 and reg-0x43 == 0 and reg-0x49 == 0:
      print "❌ All version registers return 0 - communication issue"
    else if reg-0x41 == reg-0x42 and reg-0x42 == reg-0x43 and reg-0x43 == reg-0x49:
      print "⚠️  All version registers return same value - possible communication issue"
    else:
      print "✓ Version registers return different values - communication working"
      
    if reg-0x40 != 0:
      print "✓ SENSOR_ID register working (0x$(%02x reg-0x40))"
    else:
      print "❌ SENSOR_ID register also returns 0"
      
  finally: | is-exception exception |
    if is-exception:
      print "❌ Test failed: $exception"

  print "\nVersion register diagnostic complete."
