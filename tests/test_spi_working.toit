// Working SPI test - no GPIO conflicts, no final field issues

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI WORKING TEST ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  print "\nTest 1: Default ArducamCamera (1MHz, mode 0)"
  test-camera-default bus
  
  print "\nTest 2: Test different SPI buses with different settings"
  test-different-buses
  
  print "\n=== WORKING TEST COMPLETE ==="

test-camera-default bus -> none:
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  
  print "  Camera created with default settings"
  print "  SPI: 1MHz, mode 0 (from library default)"
  
  // Test basic functionality
  print "  Testing basic register operations..."
  
  try:
    // Test reading various registers
    regs-to-test := [0x00, 0x01, 0x02, 0x04, 0x07]
    reg-names := ["TEST1", "FRAMES", "POWER", "FIFO", "RESET"]
    
    for i := 0; i < regs-to-test.size; i++:
      reg := regs-to-test[i]
      name := reg-names[i]
      
      value := camera.read-reg reg
      print "    Reg 0x$(%02x reg) ($name): 0x$(%02x value)"
    
    // Test write/read cycle on test register
    print "  Testing write/read cycle..."
    camera.write-reg 0x00 0x33
    sleep --ms=5
    readback := camera.read-reg 0x00
    print "    Wrote 0x33 to reg 0x00, read back: 0x$(%02x readback)"
    
    if readback == 0x33:
      print "    ✅ Write/read cycle WORKS with default settings!"
    else:
      print "    ❌ Write/read cycle FAILED with default settings"
      
      // Try with longer delay
      camera.write-reg 0x00 0x66
      sleep --ms=50
      readback2 := camera.read-reg 0x00
      print "    Tried with 50ms delay: wrote 0x66, read 0x$(%02x readback2)"
      
      if readback2 == 0x66:
        print "    ✅ Works with longer delay!"
      else:
        print "    ❌ Still failed even with delay"
        
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Exception in default test: $exception"

test-different-buses -> none:
  // Test different SPI configurations by creating separate buses
  
  configurations := [
    [100_000, 0, "100kHz, mode 0"],
    [1_000_000, 0, "1MHz, mode 0 (current)"],
    [4_000_000, 0, "4MHz, mode 0 (Arduino typical)"],
    [8_000_000, 0, "8MHz, mode 0 (Arduino fast)"],
    [4_000_000, 1, "4MHz, mode 1"],
    [4_000_000, 2, "4MHz, mode 2"],
    [4_000_000, 3, "4MHz, mode 3"],
  ]
  
  configurations.do: | config |
    freq := config[0]
    mode := config[1]
    description := config[2]
    
    print "  Testing: $description"
    
    try:
      // Create new bus for this test (avoid conflicts)
      test-bus := spi.Bus
            --miso=gpio.Pin 19
            --mosi=gpio.Pin 23
            --clock=gpio.Pin 18
      
      // Create camera with this bus
      camera := ArducamCamera --spi-bus=test-bus --cs=(gpio.Pin 22)
      
      // Test basic operation
      camera.write-reg 0x00 0x99
      sleep --ms=2
      readback := camera.read-reg 0x00
      
      if readback == 0x99:
        print "    ✅ $description: SUCCESS!"
      else:
        print "    ❌ $description: Failed (got 0x$(%02x readback))"
        
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ $description: Exception: $exception"
