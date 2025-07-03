// 04: Basic image capture test

import arducam_mega show *
import spi
import gpio

main:
  print "=== 04: CAPTURE BASIC ==="
  print "Testing basic image capture functionality..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    camera.on
    print "✅ Camera initialized"
    
    print "\nAttempting image capture..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Capture command completed"
    
    print "\nChecking captured data..."
    image-size := camera.image-available
    print "  Image size: $image-size bytes"
    
    if image-size == 0:
      print "  ❌ No image data captured"
    else if image-size > 10000000:  // > 10MB
      print "  ⚠️  Very large image ($image-size bytes) - likely raw format"
    else if image-size > 100000:   // > 100KB
      print "  ✅ Reasonable size ($image-size bytes) - likely compressed"
    else:
      print "  ⚠️  Small image ($image-size bytes) - may be incomplete"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception during capture: $exception"
  
  print "\n=== 04: CAPTURE BASIC COMPLETE ==="
