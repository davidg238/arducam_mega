// Test 14: SPI Protocol Fix Based on Application Note
// Goal: Fix SPI read protocol to match exact timing requirements
// Success: Register reads return actual hardware values

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 14: SPI Protocol Fix ==="
  print "Goal: Fix SPI read protocol based on Application Note timing"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    
    // Test different SPI configurations
    test-configs := [
      [1_000_000, 0, "1MHz Mode 0 (current)"],
      [8_000_000, 0, "8MHz Mode 0 (recommended)"],
      [4_000_000, 0, "4MHz Mode 0 (conservative)"],
      [2_000_000, 0, "2MHz Mode 0 (middle)"],
    ]
    
    test-configs.do: | config |
      freq := config[0]
      mode := config[1]
      desc := config[2]
      
      print "\n=== Testing $desc ==="
      
      device := spi-bus.device --cs=cs --frequency=freq --mode=mode
      
      // Test 1: Read test register (0x00)
      print "Test 1: Reading test register (0x00)..."
      
      // Method 1: Current implementation (3 bytes in one transaction)
      print "  Method 1: 3-byte transaction"
      device.write #[0x00, 0x00, 0x00]
      response1 := device.read 3
      print "    Response: $response1, taking byte 2: 0x$(%02x response1[2])"
      
      // Method 2: Separate transactions per Application Note
      print "  Method 2: Command + dummy + read"
      device.write #[0x00]  // Command phase
      device.write #[0x00]  // Dummy phase
      response2 := device.read 1  // Data phase
      print "    Response: $response2, value: 0x$(%02x response2[0])"
      
      // Method 3: Write command, then read with dummy
      print "  Method 3: Write command, then read"
      device.write #[0x00, 0x00]  // Command + dummy
      response3 := device.read 1   // Read data
      print "    Response: $response3, value: 0x$(%02x response3[0])"
      
      // Method 4: Single byte command, then read 2 bytes
      print "  Method 4: Single command, read 2 bytes"
      device.write #[0x00]
      response4 := device.read 2
      print "    Response: $response4, taking byte 1: 0x$(%02x response4[1])"
      
      // Test 2: Write then read back to test persistence
      print "\nTest 2: Write/readback test on register 0x00..."
      
      // Write a test value
      print "  Writing 0x55 to register 0x00..."
      device.write #[0x80, 0x55]  // Write: address with MSB set + value
      sleep --ms=10
      
      // Read back using each method
      print "  Readback with Method 1:"
      device.write #[0x00, 0x00, 0x00]
      rb1 := device.read 3
      print "    $rb1 -> 0x$(%02x rb1[2])"
      
      print "  Readback with Method 2:"
      device.write #[0x00]
      device.write #[0x00]
      rb2 := device.read 1
      print "    $rb2 -> 0x$(%02x rb2[0])"
      
      print "  Readback with Method 3:"
      device.write #[0x00, 0x00]
      rb3 := device.read 1
      print "    $rb3 -> 0x$(%02x rb3[0])"
      
      print "  Readback with Method 4:"
      device.write #[0x00]
      rb4 := device.read 2
      print "    $rb4 -> 0x$(%02x rb4[1])"
      
      // Check if any method shows the written value
      readback-values := [rb1[2], rb2[0], rb3[0], rb4[1]]
      success := readback-values.any: it == 0x55
      
      if success:
        print "  🎉 SUCCESS! At least one method shows written value!"
      else:
        print "  ❌ No method shows written value"
      
      // Test 3: Test on known register with expected value
      print "\nTest 3: Reading power control register (0x02)..."
      
      power-values := []
      
      // Method 1
      device.write #[0x02, 0x00, 0x00]
      p1 := device.read 3
      power-values.add p1[2]
      
      // Method 2
      device.write #[0x02]
      device.write #[0x00]
      p2 := device.read 1
      power-values.add p2[0]
      
      // Method 3
      device.write #[0x02, 0x00]
      p3 := device.read 1
      power-values.add p3[0]
      
      // Method 4
      device.write #[0x02]
      p4 := device.read 2
      power-values.add p4[1]
      
      print "  Power control values: $power-values"
      
      // Check for variation (sign of real hardware response)
      first-value := power-values[0]
      has-variation := false
      power-values.do: | val |
        if val != first-value:
          has-variation = true
      if has-variation:
        print "  ✅ Got varied values - suggests real hardware communication!"
      else:
        print "  ⚠️  All values same - may be protocol issue"
      
      print "\n" + "="*50
    
    print "\n=== Analysis ==="
    print "The key insight is that current method gets responses like [0x78, 0x78, 0x42]"
    print "This suggests the SPI device may be echoing the command bytes."
    print "The Application Note shows specific timing for CS assertion."
    print "We need to find the method that returns actual register values."
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: SPI protocol test failed: $exception"
    
  print "\n=== Test 14 Complete ==="
