// Test 21: Simple Stream Test
// Goal: Minimal streaming test to avoid crashes
// Success: Read any streaming data without memory issues

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 21: Simple Stream Test ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "Init camera..."
    camera.on
    print "✅ Camera ready"
    
    print "Clear FIFO..."
    camera.flush-fifo
    camera.clear-fifo-flag
    
    print "Check initial FIFO..."
    initial := camera.read-fifo-length
    print "Initial FIFO: $initial"
    
    print "Send capture command..."
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    
    print "Wait 1 second..."
    sleep --ms=1000
    
    print "Check FIFO after capture..."
    after := camera.read-fifo-length
    captured := after - initial
    print "After capture: $after (captured: $captured)"
    
    if captured > 0:
      print "✅ Data captured!"
      
      print "Set burst mode..."
      camera.set-fifo-burst
      
      print "Read first 4 bytes..."
      4.repeat: | i |
        try:
          byte := camera.read-byte
          print "Byte $i: 0x$(%02x byte)"
        finally: | is-exception exception |
          if is-exception:
            print "Error: $exception"
            return
      
      print "✅ Successfully read data"
    else:
      print "❌ No data captured"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "=== Test 21 Complete ==="
