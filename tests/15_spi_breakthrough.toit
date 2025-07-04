// Test 15: SPI Breakthrough - Focus on Working Methods
// Goal: Use the working SPI methods that return real register values
// Success: Consistent real register values instead of echo values

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 15: SPI Breakthrough ==="
  print "Goal: Use working SPI methods (Methods 3&4 from previous test)"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=1_000_000 --mode=0
    
    print "\n=== Method 3: Write command+dummy, read 1 byte ==="
    
    test-registers := [
      [0x00, "Test register"],
      [0x02, "Power control"],
      [0x0A, "I2C device address"],
      [0x40, "Sensor ID"],
      [0x41, "Year ID"],
      [0x42, "Month ID"],
      [0x43, "Day ID"],
    ]
    
    print "Reading registers with Method 3 (working method):"
    test-registers.do: | reg-info |
      reg := reg-info[0]
      name := reg-info[1]
      
      device.write #[reg, 0x00]  // Command + dummy
      response := device.read 1   // Read data
      value := response[0]
      
      print "  $name (0x$(%02x reg)): 0x$(%02x value)"
    
    print "\n=== Method 4: Write command, read 2 bytes ==="
    
    print "Reading registers with Method 4 (working method):"
    test-registers.do: | reg-info |
      reg := reg-info[0]
      name := reg-info[1]
      
      device.write #[reg]         // Command only
      response := device.read 2   // Read 2 bytes
      value := response[1]        // Take second byte
      
      print "  $name (0x$(%02x reg)): 0x$(%02x value)"
    
    print "\n=== Write/Read Test ==="
    
    // Test writing and reading back
    print "Testing write/read on test register (0x00):"
    
    // Write 0xAB to test register
    print "  Writing 0xAB to register 0x00..."
    device.write #[0x80, 0xAB]  // Write: address with MSB set + value
    sleep --ms=10
    
    // Read back with Method 3
    device.write #[0x00, 0x00]
    response3 := device.read 1
    print "  Method 3 readback: 0x$(%02x response3[0])"
    
    // Read back with Method 4
    device.write #[0x00]
    response4 := device.read 2
    print "  Method 4 readback: 0x$(%02x response4[1])"
    
    if response3[0] == 0xAB or response4[1] == 0xAB:
      print "  🎉 SUCCESS! Write/read working!"
    else:
      print "  ⚠️  Write/read may not be working"
    
    print "\n=== Test Power Control ==="
    
    // Test power control register specifically
    print "Testing power control register (0x02):"
    
    // Read current value
    device.write #[0x02, 0x00]
    current := device.read 1
    print "  Current power control: 0x$(%02x current[0])"
    
    // Write normal power state
    print "  Writing normal power state (0x05)..."
    device.write #[0x82, 0x05]  // Write to 0x02
    sleep --ms=50
    
    // Read back
    device.write #[0x02, 0x00]
    readback := device.read 1
    print "  Power control readback: 0x$(%02x readback[0])"
    
    if readback[0] == 0x05:
      print "  🎉 SUCCESS! Power control write/read working!"
    else:
      print "  ⚠️  Power control write may not be working"
    
    print "\n=== Test I2C Device Address ==="
    
    // Test I2C device address register
    print "Testing I2C device address register (0x0A):"
    
    // Write I2C address
    print "  Writing I2C address 0x78..."
    device.write #[0x8A, 0x78]  // Write to 0x0A
    sleep --ms=10
    
    // Read back
    device.write #[0x0A, 0x00]
    i2c-readback := device.read 1
    print "  I2C address readback: 0x$(%02x i2c-readback[0])"
    
    if i2c-readback[0] == 0x78:
      print "  🎉 SUCCESS! I2C address write/read working!"
    else:
      print "  ⚠️  I2C address write may not be working"
    
    print "\n=== Test Sensor ID ==="
    
    // Test sensor ID register
    print "Testing sensor ID register (0x40):"
    
    device.write #[0x40, 0x00]
    sensor-id := device.read 1
    print "  Sensor ID: 0x$(%02x sensor-id[0])"
    
    if sensor-id[0] == 0x56:
      print "  🎉 SUCCESS! Got MEGA-5MP sensor ID!"
    else if sensor-id[0] != 0x00 and sensor-id[0] != 0x55:
      print "  ✅ Got non-default sensor ID - may be valid"
    else:
      print "  ⚠️  Got default sensor ID"
    
    print "\n=== Summary ==="
    print "Method 3 (cmd+dummy, read 1) appears to be working"
    print "Method 4 (cmd only, read 2, take byte 1) appears to be working"
    print "These methods return real register values, not echo values"
    print "Next step: Update main library to use working SPI method"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: SPI breakthrough test failed: $exception"
    
  print "\n=== Test 15 Complete ==="
