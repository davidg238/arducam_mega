// Test 11: Functional Test With Proper Initialization
// Goal: Test camera functionality with proper initialization first
// Success: Camera captures real images after proper initialization

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 11: Functional Test With Proper Initialization ==="
  print "Goal: Test camera functionality after proper camera.on() initialization"
  
  try:
    // Step 1: ALWAYS initialize camera first
    print "\nStep 1: Initialize camera (camera.on())..."
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    // CRITICAL: Initialize camera before any operations
    camera.on
    print "✅ Camera initialization complete"
    
    // Step 2: Test FIFO operations after initialization
    print "\nStep 2: Test FIFO operations after initialization..."
    
    camera.flush-fifo
    print "✅ FIFO flushed"
    
    camera.clear-fifo-flag
    print "✅ FIFO flag cleared"
    
    initial-fifo-length := camera.read-fifo-length
    print "Initial FIFO length: $initial-fifo-length bytes"
    
    // Step 3: Attempt image capture after initialization
    print "\nStep 3: Attempt image capture after initialization..."
    
    print "Capturing QVGA JPEG image..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Capture command sent"
    
    // Wait for capture
    print "Waiting 3 seconds for capture to complete..."
    sleep --ms=3000
    
    post-capture-fifo-length := camera.read-fifo-length
    print "FIFO length after capture: $post-capture-fifo-length bytes"
    
    // Calculate captured data
    captured-data := post-capture-fifo-length - initial-fifo-length
    print "Captured data: $captured-data bytes"
    
    if captured-data > 0 and captured-data < 1000000:  // Reasonable size
      print "✅ Reasonable amount of image data captured!"
      
      // Try to read image data
      print "\nStep 4: Read captured image data..."
      
      camera.set-fifo-burst
      print "✅ FIFO burst mode enabled"
      
      // Read first 16 bytes to check for JPEG header
      header-bytes := []
      16.repeat:
        try:
          byte := camera.read-byte
          header-bytes.add byte
        finally: | is-exception exception |
          if is-exception:
            header-bytes.add 0xFF  // Error marker
      
      print "Image header: $header-bytes"
      
      // Check for JPEG markers
      has-jpeg-header := header-bytes.size >= 2 and header-bytes[0] == 0xFF and header-bytes[1] == 0xD8
      has-valid-data := header-bytes.any: it != 0x00 and it != 0xFF
      
      if has-jpeg-header:
        print "🎉 PERFECT! Valid JPEG header found (FF D8)!"
        print "   Camera is capturing real JPEG images!"
        return
      else if has-valid-data:
        print "✅ Camera is capturing real data (not all zeros)!"
        print "   Format might not be JPEG, but camera is working"
        return
      else:
        print "⚠️  Image data appears to be all zeros or invalid"
        
    else if captured-data == 0:
      print "⚠️  No new data captured (FIFO length unchanged)"
    else:
      print "⚠️  Suspicious data amount: $captured-data bytes"
      print "   This might indicate FIFO length calculation issues"
    
    // Step 5: Try alternative capture methods
    print "\nStep 5: Try alternative capture methods..."
    
    // Method 1: Different image sizes
    image-modes := [
      [CAM_IMAGE_MODE_QQVGA, "QQVGA (160x120)"],
      [CAM_IMAGE_MODE_96X96, "96x96"],
      [CAM_IMAGE_MODE_VGA, "VGA (640x480)"],
    ]
    
    image-modes.do: | mode-info |
      mode := mode-info[0]
      name := mode-info[1]
      
      print "\nTrying $name..."
      
      camera.flush-fifo
      camera.clear-fifo-flag
      before := camera.read-fifo-length
      
      camera.take-picture mode CAM_IMAGE_PIX_FMT_JPG
      sleep --ms=2000
      
      after := camera.read-fifo-length
      captured := after - before
      
      print "$name result: $captured bytes"
      
      if captured > 0 and captured < 500000:
        print "✅ $name captured reasonable data!"
        
        // Try to read a few bytes
        camera.set-fifo-burst
        first-bytes := []
        5.repeat:
          try:
            byte := camera.read-byte
            first-bytes.add byte
          finally: | is-exception exception |
            if is-exception:
              first-bytes.add 0xFF
        
        print "First bytes: $first-bytes"
        
        if first-bytes[0] == 0xFF and first-bytes[1] == 0xD8:
          print "🎉 JPEG header found with $name!"
          return
    
    // Step 6: Try high-level command protocol directly
    print "\nStep 6: Try high-level ArduCam commands directly..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    before := camera.read-fifo-length
    
    // Send commands directly to camera SPI device
    format-cmd := #[0x55, 0x01, 0x11, 0xAA]  // JPEG + QVGA
    camera.camera.write format-cmd
    sleep --ms=100
    
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]  // Capture
    camera.camera.write capture-cmd
    sleep --ms=3000
    
    after := camera.read-fifo-length
    captured := after - before
    
    print "Direct command result: $captured bytes"
    
    if captured > 0:
      print "✅ Direct commands captured data!"
    else:
      print "⚠️  No data captured with any method"
    
    print "\nConclusion:"
    print "- Camera initializes successfully"
    print "- Commands execute without errors"
    print "- FIFO operations work"
    
    if captured-data > 0:
      print "- Camera appears to be capturing data"
      print "- Issue may be with data format or read protocol"
    else:
      print "- No image data captured"
      print "- Camera may need different commands or timing"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Functional test failed: $exception"
    
  print "\n=== Test 11 Complete ==="
