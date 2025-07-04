// Test 22: Minimal Test
// Goal: Absolute minimal test to avoid reboots
// Success: Complete without device reboot

import arducam_mega show *
import gpio
import spi

main:
  print "=== Minimal Test ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "Reading one register..."
    sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID: 0x$(%02x sensor-id)"
    
    print "✅ Test complete"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ Error: $exception"
    
  print "=== Done ==="
