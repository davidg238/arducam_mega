// Test 10: Register Read After Proper Initialization
// Goal: Test register reads AFTER proper camera initialization
// Success: Registers return correct values after camera.on()

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 10: Register Read After Proper Initialization ==="
  print "Goal: Test register behavior AFTER camera.on() initialization"
  
  try:
    // Step 1: ALWAYS initialize camera first
    print "\nStep 1: Initialize camera (camera.on())..."
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    // CRITICAL: Initialize camera before any register operations
    camera.on
    print "✅ Camera initialization complete"
    
    // Step 2: Now test register reads after initialization
    print "\nStep 2: Test register reads after initialization..."
    
    important-registers := [
      [0x40, "Sensor ID (should be 0x56 for MEGA-5MP)"],
      [0x41, "Year ID"],
      [0x42, "Month ID"],
      [0x43, "Day ID"],
      [0x49, "FPGA Version"],
      [0x0A, "I2C Device Address (should be 0x78)"],
      [0x44, "Sensor State"],
      [0x00, "Test Register"],
      [0x01, "Frames Register"],
      [0x07, "Sensor Reset Register"],
    ]
    
    register-values := {:}
    
    important-registers.do: | reg-info |
      addr := reg-info[0]
      desc := reg-info[1]
      
      value := camera.read-fpga-reg addr
      register-values[addr] = value
      
      print "  Register 0x$(%02x addr): 0x$(%02x value) - $desc"
    
    // Step 3: Analyze the results
    print "\nStep 3: Analysis after proper initialization..."
    
    sensor-id := register-values[0x40]
    i2c-addr := register-values[0x0A]
    year := register-values[0x41]
    month := register-values[0x42]
    day := register-values[0x43]
    
    if sensor-id == 0x56:
      print "✅ SUCCESS: Sensor ID is correct (0x56 = MEGA-5MP)!"
    else if sensor-id == 0x42:
      print "⚠️  Sensor ID still 0x42 after initialization"
      print "     This suggests register reads are not working properly"
    else:
      print "⚠️  Unexpected sensor ID: 0x$(%02x sensor-id)"
    
    if i2c-addr == 0x78:
      print "✅ SUCCESS: I2C address correctly set to 0x78!"
    else:
      print "⚠️  I2C address: 0x$(%02x i2c-addr) (expected 0x78)"
    
    // Check if all values are the same (the 0x42 pattern)
    all-same := true
    first-value := register-values[0x40]
    register-values.do --keys: | addr |
      if register-values[addr] != first-value:
        all-same = false
    
    if all-same:
      print "⚠️  All registers return same value (0x$(%02x first-value))"
      print "     This indicates register read protocol issue"
      print "     Camera may be working but register access is broken"
    else:
      print "✅ Registers return different values - register reads working!"
    
    // Step 4: Test register writes after initialization
    print "\nStep 4: Test register writes after initialization..."
    
    // Test write to a safe register
    test-reg := 0x00
    original-value := camera.read-fpga-reg test-reg
    print "  Original value of register 0x$(%02x test-reg): 0x$(%02x original-value)"
    
    test-values := [0x55, 0xAA, 0x12, 0x34]
    write-works := false
    
    test-values.do: | test-val |
      camera.write-fpga-reg test-reg test-val
      sleep --ms=10
      readback := camera.read-fpga-reg test-reg
      
      if readback == test-val:
        print "  ✅ Write 0x$(%02x test-val) -> Read 0x$(%02x readback) SUCCESS!"
        write-works = true
      else:
        print "  ❌ Write 0x$(%02x test-val) -> Read 0x$(%02x readback) FAILED"
    
    // Restore original value
    camera.write-fpga-reg test-reg original-value
    
    if write-works:
      print "✅ SUCCESS: Register writes work after initialization!"
    else:
      print "⚠️  Register writes still don't persist after initialization"
    
    // Step 5: Test functional operations after initialization
    print "\nStep 5: Test functional operations after initialization..."
    
    // Test FIFO operations
    camera.flush-fifo
    camera.clear-fifo-flag
    
    fifo-length := camera.read-fifo-length
    print "  FIFO length after flush: $fifo-length bytes"
    
    if fifo-length == 0:
      print "✅ FIFO operations working correctly!"
    else if fifo-length == 4342338:  // 0x424242
      print "⚠️  FIFO length shows register read issue (0x424242)"
    else:
      print "⚠️  Unexpected FIFO length: $fifo-length"
    
    print "\nSummary:"
    print "- Camera initialization: ✅ Completed successfully"
    print "- Register reads: $(all-same ? "❌ Not working (all return 0x$(%02x first-value))" : "✅ Working correctly")"
    print "- Register writes: $(write-works ? "✅ Working correctly" : "❌ Not working")"
    print "- FIFO operations: $(fifo-length == 0 ? "✅ Working correctly" : "⚠️ Affected by register issues")"
    
    if sensor-id == 0x56 and write-works:
      print "\n🎉 FULL SUCCESS: Camera is fully functional!"
    else if all-same and not write-works:
      print "\n⚠️  Camera initializes but register access is broken"
      print "   Recommendation: Focus on high-level command protocol"
    else:
      print "\n⚠️  Mixed results - partial functionality"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Register test after init failed: $exception"
    
  print "\n=== Test 10 Complete ==="
