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
    
    print "\nAnalyzing image format..."
    header-size := 50
    if header-size > image-size: header-size = image-size
    
    header := camera.read-buffer header-size
    print "  Read $header.size bytes for analysis"
    
    print "\nFirst 20 bytes:"
    for i := 0; i < 20 and i < header.size; i++:
      print "    [$i]: 0x$(%02x header[i])"
    
    // Check for JPEG header
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "\n🎉 SUCCESS: JPEG HEADER FOUND!"
      print "  ✅ Standard JPEG format detected (FF D8)"
      
      // Look for additional JPEG markers
      markers := []
      for i := 0; i < header.size - 1; i++:
        if header[i] == 0xFF:
          marker := header[i + 1]
          if marker == 0xE0: markers.add "JFIF"
          else if marker == 0xDB: markers.add "Quantization"
          else if marker == 0xC0: markers.add "Start-of-Frame"
          else if marker == 0xDA: markers.add "Start-of-Scan"
      
      if markers.size > 0:
        print "  ✅ JPEG structure: $markers"
    else:
      print "\n❌ No JPEG header found"
      print "    Expected: 0xFF 0xD8"
      if header.size >= 2:
        print "    Got: 0x$(%02x header[0]) 0x$(%02x header[1])"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 05: FORMAT JPEG COMPLETE ==="
