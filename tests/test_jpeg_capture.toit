// Test specifically for valid JPEG image capture

import arducam_mega show *
import spi
import gpio

main:
  print "=== JPEG CAPTURE TEST ==="
  print "Goal: Capture a valid JPEG image with proper headers"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nStep 1: Initialize camera"
    camera.on
    print "Camera initialization complete!"
    
    print "\nStep 2: Explicitly set JPEG format"
    ensure-jpeg-format camera
    
    print "\nStep 3: Capture image in JPEG format"
    capture-jpeg-image camera
    
    print "\nStep 4: Verify JPEG format"
    verify-jpeg-format camera
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during JPEG test: $exception"
  
  print "\n=== JPEG CAPTURE TEST COMPLETE ==="

ensure-jpeg-format camera -> none:
  print "  Setting format to JPEG explicitly..."
  
  // Set the pixel format to JPEG (from constants in library)
  jpeg-format := CAM_IMAGE_PIX_FMT_JPG  // Should be 0x01
  print "    JPEG format constant: $jpeg-format"
  
  // Write to format register
  camera.write-reg 0x20 jpeg-format  // CAM_REG_FORMAT = 0x20
  camera.wait-idle
  
  // Verify format was set
  format-readback := camera.read-reg 0x20
  print "    Format register readback: 0x$(%02x format-readback)"
  
  if format-readback == jpeg-format:
    print "    ✅ JPEG format set successfully"
  else:
    print "    ⚠️  Format readback doesn't match (expected 0x$(%02x jpeg-format), got 0x$(%02x format-readback))"

capture-jpeg-image camera -> none:
  print "  Capturing image with explicit JPEG settings..."
  
  // Use small resolution for testing
  mode := CAM_IMAGE_MODE_QVGA   // 320x240
  format := CAM_IMAGE_PIX_FMT_JPG
  
  print "    Resolution: QVGA (320x240)"
  print "    Format: JPEG (0x$(%02x format))"
  
  // Take picture with explicit format
  camera.take-picture mode format
  
  // Wait a bit for capture to complete
  sleep --ms=1000
  
  // Check if image is available
  image-size := camera.image-available
  print "    Image data available: $image-size bytes"
  
  if image-size > 0:
    print "    ✅ Image capture completed with data"
  else:
    print "    ❌ No image data available"

verify-jpeg-format camera -> none:
  print "  Verifying JPEG format..."
  
  image-size := camera.image-available
  
  if image-size == 0:
    print "    ❌ No image data to verify"
    return
  
  print "    Reading first 50 bytes to check JPEG header..."
  
  try:
    camera.set-fifo-burst
    first-bytes := camera.read-buffer 50
    
    print "    First 20 bytes:"
    for i := 0; i < (min 20 first-bytes.size); i++:
      print "      [$i]: 0x$(%02x first-bytes[i])"
    
    // Check for JPEG header
    if first-bytes.size >= 2:
      if first-bytes[0] == 0xFF and first-bytes[1] == 0xD8:
        print "    ✅ VALID JPEG: Found JPEG header (FF D8)!"
        
        // Look for JPEG end marker
        if first-bytes.size >= 4:
          // Check last few bytes for JPEG end (FF D9)
          found-end := false
          for i := 2; i < first-bytes.size - 1; i++:
            if first-bytes[i] == 0xFF and first-bytes[i + 1] == 0xD9:
              print "    ✅ JPEG end marker found at position $i"
              found-end = true
              break
          
          if not found-end:
            print "    ⚠️  JPEG header found but no end marker in first 50 bytes (normal for larger images)"
        
        // Additional JPEG structure checks
        check-jpeg-structure first-bytes
        
      else:
        print "    ❌ INVALID: No JPEG header found"
        print "      Expected: 0xFF 0xD8"
        print "      Got: 0x$(%02x first-bytes[0]) 0x$(%02x first-bytes[1])"
        print "      This appears to be raw image data, not JPEG"
    else:
      print "    ❌ Insufficient data to check JPEG header"
      
  finally: | is-exception exception |
    if is-exception:
      print "    Error reading image data: $exception"

check-jpeg-structure data/ByteArray -> none:
  if data.size < 10:
    return
    
  print "    Analyzing JPEG structure:"
  
  // Look for common JPEG markers
  markers := [
    [0xFF, 0xE0, "APP0 (JFIF)"],
    [0xFF, 0xE1, "APP1 (EXIF)"], 
    [0xFF, 0xDB, "DQT (Quantization Table)"],
    [0xFF, 0xC0, "SOF0 (Start of Frame)"],
    [0xFF, 0xDA, "SOS (Start of Scan)"],
  ]
  
  for i := 0; i < data.size - 1; i++:
    if data[i] == 0xFF:
      markers.do: | marker |
        marker-bytes := marker[0..1]
        marker-name := marker[2]
        
        if i + 1 < data.size and data[i + 1] == marker-bytes[1]:
          print "      Found $marker-name at position $i"

min a b -> int:
  return a < b ? a : b
