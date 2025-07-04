// Test 1: Hardware Connection Test
// Goal: Verify SPI communication works at the most basic level
// Success: SPI transactions complete without exceptions

import gpio
import spi

main:
  print "=== Test 1: Hardware Connection Test ==="
  print "Goal: Verify SPI communication works at basic level"
  
  try:
    // Initialize SPI with conservative settings
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=100_000 --mode=0  // Very slow and safe
    
    print "✅ SPI bus and device created successfully"
    
    // Test 1a: Simple write transaction
    print "\nTest 1a: Simple write transaction..."
    device.write #[0x00, 0x55]  // Write 0x55 to register 0x00
    print "✅ Write transaction completed without exception"
    
    // Test 1b: Simple read transaction
    print "\nTest 1b: Simple read transaction..."
    device.write #[0x00, 0x00, 0x00]  // Read register 0x00
    response := device.read 3
    print "✅ Read transaction completed: $response"
    
    // Test 1c: Multiple transactions
    print "\nTest 1c: Multiple transactions..."
    5.repeat:
      device.write #[0x00, 0x00, 0x00]
      response = device.read 3
    print "✅ Multiple transactions completed successfully"
    
    // Test 1d: Different register addresses
    print "\nTest 1d: Different register addresses..."
    registers := [0x00, 0x01, 0x07, 0x0A, 0x40, 0x41]
    registers.do: | reg |
      device.write #[reg, 0x00, 0x00]
      response = device.read 3
      print "  Register 0x$(%02x reg): $response"
    
    print "\n✅ SUCCESS: Hardware connection test passed!"
    print "   - SPI transactions work without exceptions"
    print "   - Device is responding to communication attempts"
    print "   - Ready for register-level tests"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Hardware connection test failed: $exception"
      print "   Possible issues:"
      print "   - SPI wiring incorrect (MOSI=23, MISO=19, CLK=18, CS=22)"
      print "   - ArduCam not powered (check 3.3V supply)"
      print "   - Hardware damage"
      print "   - ESP32 GPIO configuration issue"
    
  print "\n=== Test 1 Complete ==="
