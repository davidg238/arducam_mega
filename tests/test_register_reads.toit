// Test register reads to see if we get diverse values

import arducam_mega show *
import spi
import gpio

main:
  print "=== REGISTER READ TEST ==="
  print "Testing if we get diverse register values..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nStep 1: Test BEFORE initialization"
    test-register-diversity camera "BEFORE"
    
    print "\nStep 2: Initialize camera"
    camera.on
    print "Camera initialization complete!"
    
    print "\nStep 3: Test AFTER initialization"
    test-register-diversity camera "AFTER"
    
    print "\nStep 4: Test write operations"
    test-write-operations camera
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== REGISTER READ TEST COMPLETE ==="

test-register-diversity camera phase -> none:
  print "  Testing register diversity ($phase init):"
  
  // Test a variety of registers
  test-regs := [
    [0x00, "ARDUCHIP_TEST1"],
    [0x01, "ARDUCHIP_FRAMES"],
    [0x02, "CAM_REG_POWER_CONTROL"],
    [0x04, "ARDUCHIP_FIFO"],
    [0x07, "CAM_REG_SENSOR_RESET"],
    [0x40, "CAM_REG_SENSOR_ID"],
    [0x41, "CAM_REG_YEAR_ID"],
    [0x42, "CAM_REG_MONTH_ID"],
    [0x43, "CAM_REG_DAY_ID"],
    [0x44, "CAM_REG_SENSOR_STATE"],
    [0x49, "CAM_REG_FPGA_VERSION_NUMBER"]
  ]
  
  values := []
  unique-count := 0
  
  test-regs.do: | reg-info |
    reg := reg-info[0]
    name := reg-info[1]
    
    value := camera.read-reg reg
    values.add value
    print "    0x$(%02x reg) ($name): 0x$(%02x value)"
  
  // Count unique values
  unique-values := {}
  values.do: | val |
    unique-values.add val
  
  unique-count = unique-values.size
  print "\n  Analysis:"
  print "    Total registers tested: $values.size"
  print "    Unique values found: $unique-count"
  
  if unique-count == 1:
    print "    ❌ ALL registers return the same value - read protocol issue!"
  else if unique-count < 3:
    print "    ⚠️  Very few unique values - possible read protocol issue"
  else:
    print "    ✅ Good diversity - register reads working!"

test-write-operations camera -> none:
  print "  Testing write operations:"
  
  // Test writing to the test register
  initial := camera.read-reg 0x00
  print "    Initial test reg value: 0x$(%02x initial)"
  
  test-values := [0x11, 0x22, 0x33, 0x44, 0x55]
  
  test-values.do: | test-val |
    print "    Writing 0x$(%02x test-val)..."
    camera.write-reg 0x00 test-val
    sleep --ms=5
    
    readback := camera.read-reg 0x00
    print "      Read back: 0x$(%02x readback)"
    
    if readback == test-val:
      print "      ✅ Write/read cycle works!"
      return
    else if readback != initial:
      print "      ⚠️  Value changed but not to expected value"
    else:
      print "      ❌ Value didn't change"
  
  print "    ❌ Write operations not working properly"
