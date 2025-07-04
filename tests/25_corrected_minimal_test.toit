// Test 25: Corrected Minimal Test
// Goal: Minimal test WITH proper camera initialization
// Success: Complete without device reboot, proper initialization

import arducam_mega show *
import gpio
import spi

main:
  print "=== Corrected Minimal Test ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera (CRITICAL)..."
    camera.on
    print "✅ Camera initialized properly"
    
    print "STEP 2: Reading register after initialization..."
    sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID: 0x$(%02x sensor-id)"
    
    print "STEP 3: Test register write after initialization..."
    camera.write-fpga-reg 0x0A 0x78
    readback := camera.read-fpga-reg 0x0A
    print "I2C address write test: wrote 0x78, read 0x$(%02x readback)"
    
    if readback == 0x78:
      print "✅ Register write successful!"
    else:
      print "❌ Register write failed"
    
    print "✅ Test complete with proper initialization"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ Error: $exception"
    
  print "=== Done ==="
