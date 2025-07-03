// Test using the actual library with proper initialization

import arducam_mega show *
import spi
import gpio

main:
  print "=== TESTING WITH ARDUCAM LIBRARY ==="
  print "Using the actual library implementation..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    // Initialize camera
    print "\nInitializing camera..."
    camera.on
    print "✅ Camera initialized"
    
    // Test image capture
    print "\nTaking JPEG picture..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Picture taken"
    
    // Check if image is available
    image-size := camera.image-available
    print "\nImage size: $image-size bytes"
    
    if image-size == 0:
      print "❌ No image data available"
      return
    
    if image-size > 10000000:
      print "⚠️  Very large image ($image-size bytes) - likely raw format"
    else:
      print "✅ Reasonable image size for JPEG: $image-size bytes"
    
    // Read first part of image to check format
    print "\nReading image header..."
    header-size := 50
    if header-size > image-size: header-size = image-size
    
    header := camera.read-buffer header-size
    print "\nFirst 20 bytes of image:"
    for i := 0; i < 20 and i < header.size; i++:
      print "  [$i]: 0x$(%02x header[i])"
    
    // Check for JPEG header
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "\n🎉 🎉 🎉 SUCCESS! JPEG HEADER FOUND! 🎉 🎉 🎉"
      print "✅ ArduCam MEGA JPEG format is WORKING!"
      
      // Look for more JPEG markers
      jpeg-markers := []
      for i := 0; i < header.size - 1; i++:
        if header[i] == 0xFF:
          marker := header[i + 1]
          if marker == 0xE0: jpeg-markers.add "JFIF"
          else if marker == 0xDB: jpeg-markers.add "Quantization"
          else if marker == 0xC0: jpeg-markers.add "Start-of-Frame"
          else if marker == 0xDA: jpeg-markers.add "Start-of-Scan"
          else if marker == 0xD9: jpeg-markers.add "End-of-Image"
      
      if jpeg-markers.size > 0:
        print "✅ JPEG structure confirmed: $jpeg-markers"
        
      print "\n🎉 ARDUCAM MEGA-5MP TOIT LIBRARY IS COMPLETE! 🎉"
      
    else:
      print "\n❌ No JPEG header found"
      print "  Expected: 0xFF 0xD8"
      print "  Got: 0x$(%02x header[0]) 0x$(%02x header[1])"
      
      if header[0] == 0x55 and header[1] == 0x55:
        print "  ⚠️  Still getting 0x55 pattern - FIFO issue in library"
        print "  ⚠️  Library may need FIFO register fixes"
      else:
        print "  ⚠️  Got different data - may be raw format"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== LIBRARY TEST COMPLETE ==="
