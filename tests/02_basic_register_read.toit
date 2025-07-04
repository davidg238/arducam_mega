// Test 2: Basic Register Read Test
// Goal: Verify we can read register values using ArduCam protocol
// Success: Consistent, non-random register values

import gpio
import spi

read-register device/spi.Device addr/int -> int:
  // ArduCam read protocol: send address + 2 dummy bytes, take 3rd response byte
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]  // C code takes 3rd byte as real data

main:
  print "=== Test 2: Basic Register Read Test ==="
  print "Goal: Verify ArduCam register read protocol works"
  
  try:
    // Initialize SPI
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=100_000 --mode=0
    
    print "✅ SPI device initialized"
    
    // Test 2a: Read key registers multiple times for consistency
    print "\nTest 2a: Register consistency test..."
    test-registers := [0x00, 0x01, 0x07, 0x0A, 0x40, 0x41, 0x42, 0x43, 0x49]
    
    test-registers.do: | reg |
      values := []
      5.repeat:
        value := read-register device reg
        values.add value
        sleep --ms=10
      
      // Check if all values are the same (consistent)
      first-value := values[0]
      all-same := values.every: it == first-value
      
      status := all-same ? "✅" : "⚠️"
      print "  Register 0x$(%02x reg): $values -> $status $(all-same ? "consistent" : "inconsistent")"
    
    // Test 2b: Check for expected patterns
    print "\nTest 2b: Expected value patterns..."
    
    // Read sensor ID (should be 0x56 for MEGA-5MP if working)
    sensor-id := read-register device 0x40
    print "  Sensor ID (0x40): 0x$(%02x sensor-id)"
    
    if sensor-id == 0x56:
      print "  ✅ Got expected MEGA-5MP sensor ID!"
    else if sensor-id == 0x00:
      print "  ⚠️  Got 0x00 - device responding but not communicating properly"
    else if sensor-id == 0xFF:
      print "  ⚠️  Got 0xFF - possible floating/disconnected MISO line"
    else:
      print "  ⚠️  Got unexpected value - unknown state"
    
    // Read version registers
    year := read-register device 0x41
    month := read-register device 0x42
    day := read-register device 0x43
    fpga-version := read-register device 0x49
    
    print "  Year (0x41): 0x$(%02x year)"
    print "  Month (0x42): 0x$(%02x month)"
    print "  Day (0x43): 0x$(%02x day)"
    print "  FPGA Version (0x49): 0x$(%02x fpga-version)"
    
    // Analyze results
    all-zero := (sensor-id == 0x00 and year == 0x00 and month == 0x00 and day == 0x00)
    some-nonzero := (sensor-id != 0x00 or year != 0x00 or month != 0x00 or day != 0x00)
    
    print "\nAnalysis:"
    if sensor-id == 0x56:
      print "✅ SUCCESS: Camera detected and communicating properly!"
    else if all-zero:
      print "⚠️  All registers return 0x00 - hardware connected but not initialized"
      print "   - SPI communication is working (consistent values)"
      print "   - ArduCam needs initialization/activation sequence"
    else if some-nonzero:
      print "⚠️  Some registers have values - partial communication"
      print "   - May need specific initialization sequence"
    else:
      print "❌ Unknown communication state"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Register read test failed: $exception"
    
  print "\n=== Test 2 Complete ==="
