// 06: C-style capture using register approach like examples

import arducam_mega show *
import spi
import gpio

main:
  print "=== 06: C-STYLE CAPTURE ==="
  print "Testing C example approach: register writes + setCapture..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    print "✅ Camera initialized"
    
    print "\nAttempting C-style takePicture (like Capture.ino)..."
    
    // Follow C example: myCAM.takePicture(imageMode, CAM_IMAGE_PIX_FMT_JPG)
    // This should use register writes, not command protocol
    
    print "  Using library take-picture method (should use registers)..."
    
    // Try the old register-based approach from the library
    try:
      // Temporarily bypass command protocol and force register approach
      format := CAM_IMAGE_PIX_FMT_JPG  // 0x01
      mode := CAM_IMAGE_MODE_QVGA      // 0x01
      
      print "    Setting format register 0x20 = 0x$(%02x format)..."
      camera.write-reg 0x20 format
      sleep --ms=100
      
      print "    Setting resolution register 0x21 = 0x$(%02x mode)..."
      camera.write-reg 0x21 mode
      sleep --ms=100
      
      print "    Calling setCapture (FIFO control)..."
      camera.set-capture
      
      print "    ✅ C-style capture sequence completed"
      
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ Exception in register approach: $exception"
        print "    Trying library method instead..."
        
        // Fall back to library method
        camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    
    // Check results
    image-size := camera.image-available
    print "\nCapture results:"
    print "  Image size: $image-size bytes"
    
    if image-size > 0:
      print "  Testing JPEG header with streaming..."
      jpeg-found := camera.check-jpeg-headers
      
      if jpeg-found:
        print "  🎉 SUCCESS: C-style capture produced JPEG!"
      else:
        print "  ⚠️  C-style capture produced data but no JPEG headers"
    else:
      print "  ❌ No image data from C-style capture"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 06: C-STYLE CAPTURE COMPLETE ==="
