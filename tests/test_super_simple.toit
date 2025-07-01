// Super simple test - just try to read one register

import arducam_mega show *
import spi
import gpio

main:
  print "=== SUPER SIMPLE TEST ==="
  print "Just trying to read register 0x00..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    value := camera.read-reg 0x00
    print "Register 0x00 value: 0x$(%02x value)"
    
    if value == 0x00:
      print "Got 0x00 - this is the problem we need to fix"
    else:
      print "Got non-zero value - SPI might be working!"
      
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "Test complete"
