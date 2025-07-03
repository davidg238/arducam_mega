// 05: JPEG format verification test

import arducam_mega show *
import spi
import gpio

main:
  print "=== 05: FORMAT JPEG ==="
  print "Testing JPEG format and header verification..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    print "✅ Camera initialized"
    
    print "\nCapturing JPEG image..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    
    image-size := camera.image-available
    print "  Captured: $image-size bytes"
    
    if image-size == 0:
      print "  ❌ No image data to analyze"
      return
    
    print "\nAnalyzing image format using streaming (C code style)..."
    
    // Use streaming approach like C code to avoid memory issues
    jpeg-found := camera.check-jpeg-headers
    
    if jpeg-found:
      print "\n🎉 SUCCESS: JPEG HEADER FOUND!"
      print "  ✅ Standard JPEG format detected using streaming!"
      print "  ✅ ArduCam MEGA JPEG format is working!"
    else:
      print "\n❌ No JPEG header found in streaming chunks"
      print "  May need different capture parameters or FIFO reset"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 05: FORMAT JPEG COMPLETE ==="
