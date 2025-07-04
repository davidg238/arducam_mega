// Test 5: Alternative Communication Approaches
// Goal: Try different SPI configurations and protocols to find what works
// Success: Find a configuration that enables proper communication

import gpio
import spi

read-register device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-register device/spi.Device addr/int value/int -> none:
  command := #[addr | 0x80, value]
  device.write command

send-command device/spi.Device cmd/int param/int -> none:
  // High-level ArduCam command: 0x55 CMD PARAM 0xAA
  command := #[0x55, cmd, param, 0xAA]
  device.write command

main:
  print "=== Test 5: Alternative Communication Approaches ==="
  print "Goal: Try different configurations to find what works"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    
    // Test 5a: Different SPI frequencies
    print "\nTest 5a: Different SPI frequencies..."
    frequencies := [50_000, 100_000, 200_000, 500_000, 1_000_000]
    
    frequencies.do: | freq |
      print "\n  Testing frequency: $freq Hz"
      device := spi-bus.device --cs=cs --frequency=freq --mode=0
      
      // Try to read sensor ID
      sensor-id := read-register device 0x40
      print "    Sensor ID: 0x$(%02x sensor-id)"
      
      // Try register write
      write-register device 0x0A 0x78
      sleep --ms=10
      readback := read-register device 0x0A
      write-success := (readback == 0x78)
      print "    Write test: $(write-success ? "✅" : "❌") (0x$(%02x readback))"
      
      if sensor-id == 0x56 and write-success:
        print "    ✅ SUCCESS at $freq Hz!"
    
    // Test 5b: Different SPI modes
    print "\nTest 5b: Different SPI modes..."
    modes := [0, 1, 2, 3]
    
    modes.do: | mode |
      print "\n  Testing SPI mode: $mode"
      device := spi-bus.device --cs=cs --frequency=100_000 --mode=mode
      
      sensor-id := read-register device 0x40
      print "    Sensor ID: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    ✅ SUCCESS with mode $mode!"
    
    // Test 5c: High-level command protocol
    print "\nTest 5c: High-level command protocol..."
    device := spi-bus.device --cs=cs --frequency=100_000 --mode=0
    
    print "  Trying ArduCam command protocol..."
    
    // Read state before commands
    before-id := read-register device 0x40
    print "  Sensor ID before commands: 0x$(%02x before-id)"
    
    // Send format command (JPEG + VGA)
    print "  Sending format command: 0x55 0x01 0x12 0xAA"
    send-command device 0x01 0x12  // Format=JPEG(1), Resolution=VGA(2)
    sleep --ms=100
    
    // Send capture command
    print "  Sending capture command: 0x55 0x10 0x00 0xAA"
    send-command device 0x10 0x00
    sleep --ms=100
    
    // Check if commands had any effect
    after-id := read-register device 0x40
    print "  Sensor ID after commands: 0x$(%02x after-id)"
    
    if after-id != before-id:
      print "  ✅ Commands caused register changes!"
    else:
      print "  ⚠️  No visible effect from commands"
    
    // Test 5d: Arduino-style initialization
    print "\nTest 5d: Arduino-style initialization sequence..."
    device = spi-bus.device --cs=cs --frequency=1_000_000 --mode=0  // Arduino typically uses faster SPI
    
    print "  Step 1: Reset sensor"
    write-register device 0x07 0x40
    sleep --ms=100
    
    sensor-id := read-register device 0x40
    print "  Sensor ID after reset: 0x$(%02x sensor-id)"
    
    if sensor-id == 0x56:
      print "  ✅ Arduino-style reset worked!"
      
      print "  Step 2: Set I2C address"
      write-register device 0x0A 0x78
      sleep --ms=10
      readback := read-register device 0x0A
      
      if readback == 0x78:
        print "  ✅ SUCCESS: Complete Arduino-style initialization working!"
      else:
        print "  ⚠️  Reset worked but writes still don't persist"
    else:
      print "  ⚠️  Arduino-style reset didn't enable sensor ID"
    
    // Test 5e: Power cycling simulation
    print "\nTest 5e: Multiple reset attempts..."
    device = spi-bus.device --cs=cs --frequency=100_000 --mode=0
    
    5.repeat: | i |
      print "  Reset attempt $(i + 1):"
      write-register device 0x07 0x40
      sleep --ms=200  // Longer wait
      
      sensor-id = read-register device 0x40
      print "    Sensor ID: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    ✅ SUCCESS on attempt $(i + 1)!"
        return  // Exit the test early on success
    
    print "\nAnalysis:"
    print "  This test tries different approaches to find working configuration"
    print "  Success indicators:"
    print "  - Sensor ID reads as 0x56"
    print "  - Register writes persist"
    print "  - Commands cause visible effects"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Alternative approaches test failed: $exception"
    
  print "\n=== Test 5 Complete ==="
