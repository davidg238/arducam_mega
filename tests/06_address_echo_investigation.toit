// Test 6: Address Echo Investigation
// Goal: Investigate if device is echoing register addresses instead of values
// Success: Understand the device response pattern

import gpio
import spi

read-register device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

main:
  print "=== Test 6: Address Echo Investigation ==="
  print "Goal: Check if device echoes register addresses (all return 0x42)"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    device := spi-bus.device --cs=(gpio.Pin 22) --frequency=100_000 --mode=0
    
    print "\nTesting address echo hypothesis..."
    print "If device echoes addresses, reading 0x42 should return 0x42"
    print "If device echoes addresses, reading 0x56 should return 0x56"
    
    test-addresses := [0x00, 0x01, 0x40, 0x41, 0x42, 0x43, 0x44, 0x49, 0x56, 0x78, 0xAA, 0xFF]
    
    test-addresses.do: | addr |
      value := read-register device addr
      matches := (value == addr)
      status := matches ? "📧 ECHO" : "📝 DATA"
      print "  Read 0x$(%02x addr) -> 0x$(%02x value) $status"
    
    // Test with different register read patterns
    print "\nTesting different read patterns..."
    
    // Pattern 1: Standard 3-byte read
    device.write #[0x40, 0x00, 0x00]
    responses := device.read 3
    print "  Standard read 0x40: $responses"
    
    // Pattern 2: Single byte read
    device.write #[0x40]
    responses = device.read 1
    print "  Single byte read 0x40: $responses"
    
    // Pattern 3: 2-byte read
    device.write #[0x40, 0x00]
    responses = device.read 2
    print "  2-byte read 0x40: $responses"
    
    // Pattern 4: Different dummy bytes
    device.write #[0x40, 0xFF, 0xFF]
    responses = device.read 3
    print "  With 0xFF dummy: $responses"
    
    // Test the exact sensor ID register behavior
    print "\nSensor ID register detailed test..."
    print "Expected MEGA-5MP sensor ID: 0x56"
    
    5.repeat: | i |
      sensor-id := read-register device 0x40
      print "  Attempt $(i+1): Sensor ID = 0x$(%02x sensor-id)"
      sleep --ms=100
    
    // Check if it's a timing issue
    print "\nTiming variation test..."
    [1, 10, 50, 100, 500].do: | delay |
      device.write #[0x40, 0x00, 0x00]
      sleep --ms=delay
      responses = device.read 3
      print "  Delay $delay ms: $responses"
    
    // Try the power-on sequence from C code
    print "\nTrying C code power-on sequence..."
    
    // First, try different reset values
    reset-values := [0x40, 0x80, 0x00, 0x01]
    reset-values.do: | reset-val |
      print "  Reset with 0x$(%02x reset-val):"
      device.write #[0x07 | 0x80, reset-val]  // Write to reset register
      sleep --ms=200
      
      sensor-id := read-register device 0x40
      print "    Sensor ID after reset: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    🎉 SUCCESS! Found working reset sequence!"
        return
    
    print "\nAnalysis:"
    print "- If all reads return their address -> device echoing, needs initialization"
    print "- If reads return different values -> device responding but in wrong state"
    print "- If sensor ID becomes 0x56 -> found proper initialization sequence"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Address echo test failed: $exception"
    
  print "\n=== Test 6 Complete ==="
