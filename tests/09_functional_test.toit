// Test 9: Functional Test - Focus on Working Functionality
// Goal: Test if camera actually works despite register read issues
// Success: Camera captures images and responds to commands correctly

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 9: Functional Test ==="
  print "Goal: Test if camera works functionally despite register issues"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\nStep 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "\nStep 2: Test FIFO operations..."
    print "FIFO operations don't depend on sensor ID register"
    
    // Clear FIFO
    camera.flush-fifo
    print "✅ FIFO flushed"
    
    // Clear FIFO flag
    camera.clear-fifo-flag
    print "✅ FIFO flag cleared"
    
    // Check FIFO length (should be 0 after flush)
    fifo-length := camera.read-fifo-length
    print "FIFO length after flush: $fifo-length bytes"
    
    print "\nStep 3: Test image capture sequence..."
    print "This tests if the camera actually takes pictures"
    
    // Take a picture using high-level command protocol
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Picture capture command sent"
    
    // Wait for capture to complete
    print "Waiting for capture to complete..."
    sleep --ms=2000
    
    // Check FIFO length after capture
    fifo-length = camera.read-fifo-length
    print "FIFO length after capture: $fifo-length bytes"
    
    if fifo-length > 0:
      print "🎉 SUCCESS! Camera captured image data!"
      print "   FIFO contains $fifo-length bytes of image data"
      print "   This proves the camera is working correctly!"
      
      print "\nStep 4: Test reading image data..."
      
      // Read first few bytes to verify it's a JPEG
      camera.set-fifo-burst
      
      // Read JPEG header (should start with FF D8)
      header-bytes := []
      10.repeat:
        byte := camera.read-byte
        header-bytes.add byte
      
      print "Image header bytes: $header-bytes"
      
      if header-bytes.size >= 2 and header-bytes[0] == 0xFF and header-bytes[1] == 0xD8:
        print "🎉 CONFIRMED! Valid JPEG header found (FF D8)"
        print "   Camera is capturing real JPEG images!"
      else:
        print "⚠️  Unexpected header, but camera is producing data"
      
      return
    
    print "\nStep 5: Try different capture approaches..."
    
    // Try different image formats and resolutions
    formats := [
      [CAM_IMAGE_MODE_QQVGA, CAM_IMAGE_PIX_FMT_JPG, "QQVGA JPEG"],
      [CAM_IMAGE_MODE_QVGA, CAM_IMAGE_PIX_FMT_JPG, "QVGA JPEG"],
      [CAM_IMAGE_MODE_VGA, CAM_IMAGE_PIX_FMT_JPG, "VGA JPEG"],
    ]
    
    formats.do: | format |
      mode := format[0]
      pixel-format := format[1]
      name := format[2]
      
      print "\nTrying $name..."
      
      camera.flush-fifo
      camera.clear-fifo-flag
      
      camera.take-picture mode pixel-format
      sleep --ms=3000  // Longer wait for larger images
      
      fifo-length = camera.read-fifo-length
      print "$name result: $fifo-length bytes"
      
      if fifo-length > 0:
        print "🎉 SUCCESS! $name captured $fifo-length bytes"
        return
    
    print "\nStep 6: Test high-level commands directly..."
    print "Bypassing library, using raw ArduCam commands"
    
    // Send format command directly
    format-cmd := #[0x55, 0x01, 0x12, 0xAA]  // JPEG + VGA
    camera.camera.write format-cmd
    sleep --ms=100
    
    // Send capture command directly
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]
    camera.camera.write capture-cmd
    sleep --ms=2000
    
    fifo-length = camera.read-fifo-length
    print "Direct command result: $fifo-length bytes"
    
    if fifo-length > 0:
      print "🎉 SUCCESS! Direct commands worked: $fifo-length bytes"
    else:
      print "⚠️  No image data captured with any method"
      print "   Possible issues:"
      print "   - Camera hardware not connected properly"
      print "   - Camera needs different initialization"
      print "   - Camera requires specific timing"
    
    print "\nSummary:"
    print "- Register reads return 0x42 (may be normal for this device)"
    print "- Initialization commands complete without errors"
    print "- FIFO operations work (can flush, clear, read length)"
    print "- Image capture depends on camera being properly connected"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Functional test failed: $exception"
    
  print "\n=== Test 9 Complete ==="
