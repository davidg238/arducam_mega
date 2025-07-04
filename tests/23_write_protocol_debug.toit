// Test 23: Write Protocol Debug
// Goal: Debug why register writes don't persist
// Success: Find working write protocol

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 23: Write Protocol Debug ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=1_000_000 --mode=0
    
    print "Testing different write protocols..."
    
    // Test register 0x00 (test register)
    test-reg := 0x00
    test-value := 0x42
    
    print "\n=== Write Method 1: Current Implementation ==="
    print "Writing 0x$(%02x test-value) to register 0x$(%02x test-reg)"
    
    // Current write method
    device.write #[test-reg | 0x80, test-value]  // MSB set for write
    sleep --ms=10
    
    // Read back with working read method
    device.write #[test-reg, 0x00]
    response := device.read 1
    readback1 := response[0]
    print "Method 1 readback: 0x$(%02x readback1)"
    
    print "\n=== Write Method 2: Separate Transactions ==="
    
    // Try separate write transaction
    device.write #[test-reg | 0x80]  // Write command
    device.write #[test-value]       // Write data
    sleep --ms=10
    
    device.write #[test-reg, 0x00]
    response2 := device.read 1
    readback2 := response2[0]
    print "Method 2 readback: 0x$(%02x readback2)"
    
    print "\n=== Write Method 3: Arduino Style ==="
    
    // Try Arduino-style write (3 bytes in one transaction)
    device.write #[test-reg | 0x80, test-value, 0x00]  // Write with dummy
    sleep --ms=10
    
    device.write #[test-reg, 0x00]
    response3 := device.read 1
    readback3 := response3[0]
    print "Method 3 readback: 0x$(%02x readback3)"
    
    print "\n=== Write Method 4: Check Application Note Protocol ==="
    
    // From Application Note: single write timing shows command + data
    device.write #[test-reg | 0x80, 0x55]  // Different test value
    sleep --ms=50  // Longer delay
    
    device.write #[test-reg, 0x00]
    response4 := device.read 1
    readback4 := response4[0]
    print "Method 4 readback: 0x$(%02x readback4) (wrote 0x55)"
    
    print "\n=== Test Power Control Register (0x02) ==="
    
    // Test on power control register specifically
    power-reg := 0x02
    power-value := 0x05
    
    print "Testing power control register writes..."
    
    // Read initial value
    device.write #[power-reg, 0x00]
    initial := device.read 1
    print "Initial power control: 0x$(%02x initial[0])"
    
    // Try to write normal power state
    device.write #[power-reg | 0x80, power-value]
    sleep --ms=50
    
    device.write #[power-reg, 0x00]
    power-readback := device.read 1
    print "Power control after write: 0x$(%02x power-readback[0])"
    
    if power-readback[0] == power-value:
      print "✅ Power control write successful!"
    else:
      print "❌ Power control write failed"
    
    print "\n=== Test Read-Only vs Read-Write Registers ==="
    
    // Test different registers to see if some are read-only
    test-registers := [
      [0x00, "Test register"],
      [0x02, "Power control"],
      [0x04, "Memory control"],
      [0x0A, "I2C device address"],
      [0x40, "Sensor ID (likely read-only)"],
    ]
    
    test-registers.do: | reg-info |
      reg := reg-info[0]
      name := reg-info[1]
      
      // Read initial value
      device.write #[reg, 0x00]
      initial-resp := device.read 1
      initial-val := initial-resp[0]
      
      // Try to write a test value
      device.write #[reg | 0x80, 0x33]
      sleep --ms=10
      
      // Read back
      device.write #[reg, 0x00]
      final-resp := device.read 1
      final-val := final-resp[0]
      
      print "$name (0x$(%02x reg)): 0x$(%02x initial-val) -> 0x$(%02x final-val)"
      
      if final-val == 0x33:
        print "  ✅ Write successful"
      else if final-val != initial-val:
        print "  ⚠️  Changed but not to expected value"
      else:
        print "  ❌ No change (may be read-only)"
    
    print "\n=== Summary ==="
    print "Need to find the correct write protocol for this hardware"
    print "Some registers may be read-only or require special activation"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "=== Test 23 Complete ==="
