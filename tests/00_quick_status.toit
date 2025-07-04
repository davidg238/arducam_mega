// Quick Status Test - Simple test to verify current state
// This test gives us immediate feedback on the hardware state

import gpio
import spi

main:
  print "=== Quick Status Check ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    device := spi-bus.device --cs=(gpio.Pin 22) --frequency=100_000 --mode=0
    
    // Quick register read
    device.write #[0x40, 0x00, 0x00]  // Read sensor ID
    response := device.read 3
    sensor-id := response[2]
    
    // Quick write test
    device.write #[0x0A | 0x80, 0x78]  // Write I2C address
    sleep --ms=10
    device.write #[0x0A, 0x00, 0x00]  // Read back
    response = device.read 3
    readback := response[2]
    
    print "Sensor ID (0x40): 0x$(%02x sensor-id)"
    print "Write test (0x0A): wrote 0x78, read 0x$(%02x readback)"
    
    if sensor-id == 0x56:
      print "✅ Camera detected!"
    else if sensor-id == 0x00:
      print "⚠️  Device responding but not initialized"
    else:
      print "⚠️  Unexpected sensor ID"
      
    if readback == 0x78:
      print "✅ Register writes working!"
    else:
      print "❌ Register writes not persisting"
      
  finally: | is-exception exception |
    if is-exception:
      print "❌ SPI Error: $exception"
      
  print "=== Status Check Complete ==="
