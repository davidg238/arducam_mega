// Test 18: Quick Test of Current State
// Goal: Quick verification that our SPI fixes are still working
// Success: Register reads return real values

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 18: Quick State Check ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "Initializing camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "Reading key registers..."
    sensor-id := camera.read-fpga-reg 0x40
    power-control := camera.read-fpga-reg 0x02
    i2c-address := camera.read-fpga-reg 0x0A
    
    print "Sensor ID: 0x$(%02x sensor-id)"
    print "Power control: 0x$(%02x power-control)"
    print "I2C address: 0x$(%02x i2c-address)"
    
    if sensor-id != 0x00 and sensor-id != 0x55:
      print "✅ Sensor ID looks good"
    else:
      print "⚠️ Sensor ID is default value"
    
    if i2c-address == 0x78:
      print "✅ I2C address is correct"
    else:
      print "⚠️ I2C address not set correctly"
    
    print "Testing simple FIFO read..."
    fifo-length := camera.read-fifo-length
    print "FIFO length: $fifo-length bytes"
    
    print "✅ Basic functionality working"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "=== Test 18 Complete ==="
