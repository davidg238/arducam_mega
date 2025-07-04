// Test 27: Post Power Cycle Test
// Goal: Verify camera state after power cycle
// Success: Confirm our breakthrough functionality is restored

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 27: Post Power Cycle Verification ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialization complete"
    
    print "STEP 2: Check sensor ID..."
    sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID: 0x$(%02x sensor-id)"
    
    expected-sensor-id := 0x81  // Our breakthrough value
    if sensor-id == expected-sensor-id:
      print "🎉 EXCELLENT! Sensor ID restored to breakthrough value!"
    else if sensor-id != 0x00 and sensor-id != 0x55:
      print "✅ Got valid sensor ID (may be hardware variant)"
    else:
      print "⚠️  Sensor ID shows default value"
    
    print "STEP 3: Test register write capability..."
    test-value := 0x78
    camera.write-fpga-reg 0x0A test-value
    readback := camera.read-fpga-reg 0x0A
    print "I2C address test: wrote 0x$(%02x test-value), read 0x$(%02x readback)"
    
    if readback == test-value:
      print "🎉 PERFECT! Register writes working again!"
      
    else:
      print "❌ Register writes still not working"
      
    
    print "STEP 4: Check version information..."
    year := camera.read-fpga-reg 0x41
    month := camera.read-fpga-reg 0x42
    day := camera.read-fpga-reg 0x43
    print "Version date: $year/$month/$day"
    
    if year == 23 and month == 3 and day == 3:
      print "🎉 BREAKTHROUGH! Version info matches our earlier success!"
    else if year != 0 or month != 0 or day != 0:
      print "✅ Got real version info (different but valid)"
    else:
      print "❌ Version info shows zeros"
    
    print "STEP 5: Quick FIFO test..."
    fifo-length := camera.read-fifo-length
    print "FIFO length: $fifo-length bytes"
    
    print "\n=== Power Cycle Results ==="
    print "Sensor ID: $(sensor-id == expected-sensor-id ? "✅ Perfect" : sensor-id == 0x00 ? "❌ Default" : "⚠️ Different")"
    print "Register writes: $((readback == test-value) ? "✅ Working" : "❌ Failed")"
    print "Version info: $(year == 23 ? "✅ Breakthrough restored" : year != 0 ? "✅ Valid" : "❌ Zeros")"
    
    if sensor-id == expected-sensor-id and (readback == test-value):
      print "🎉 SUCCESS! Power cycle restored breakthrough functionality!"
      print "   Ready to test image capture with working system"
    else if (readback == test-value):
      print "✅ GOOD! Register writes working, ready for image capture"
    else:
      print "⚠️  Still need to investigate camera state"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 27 Complete ==="
