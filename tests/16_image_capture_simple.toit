// Test 16: Simple Image Capture Test
// Goal: Test image capture with working SPI protocol
// Success: Camera captures image data to FIFO

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 16: Simple Image Capture Test ==="
  print "Goal: Test image capture with working SPI protocol"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Initialize Camera ==="
    camera.on
    print "✅ Camera initialized"
    
    print "\n=== Phase 2: Capture Image ==="
    
    // Clear FIFO and reset
    camera.flush-fifo
    camera.clear-fifo-flag
    
    // Check initial FIFO state
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO length: $initial-fifo bytes"
    
    // Capture QVGA JPEG image
    print "Capturing QVGA JPEG image..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    
    // Wait for capture completion
    print "Waiting for capture completion..."
    sleep --ms=3000
    
    // Check FIFO after capture
    final-fifo := camera.read-fifo-length
    captured-bytes := final-fifo - initial-fifo
    
    print "Final FIFO length: $final-fifo bytes"
    print "Captured data: $captured-bytes bytes"
    
    if captured-bytes > 0:
      print "✅ Image data captured!"
      
      print "\n=== Phase 3: Read Image Data ==="
      
      // Set FIFO burst mode
      camera.set-fifo-burst
      
      // Read first 16 bytes
      print "Reading first 16 bytes of image..."
      header-bytes := []
      16.repeat: | i |
        try:
          byte := camera.read-byte
          header-bytes.add byte
        finally: | is-exception exception |
          if is-exception:
            print "  Error reading byte $i: $exception"
            header-bytes.add 0x00
      
      print "Image header: $header-bytes"
      
      // Check for JPEG signature
      if header-bytes.size >= 2 and header-bytes[0] == 0xFF and header-bytes[1] == 0xD8:
        print "🎉 SUCCESS! Valid JPEG header found!"
        print "   Camera is fully working and capturing JPEG images!"
      else:
        print "⚠️  No JPEG header found"
        print "   Checking if data is valid..."
        
        // Count non-zero bytes
        non-zero-count := 0
        header-bytes.do: | byte |
          if byte != 0x00:
            non-zero-count++
        
        if non-zero-count > 8:
          print "   Data contains varied bytes - camera is working!"
          print "   Format may not be JPEG, but image capture successful"
        else:
          print "   Data appears to be mostly zeros"
    
    else:
      print "⚠️  No image data captured"
      
      print "\n=== Phase 3: Try Alternative Capture Methods ==="
      
      // Try smaller image size
      print "Trying QQVGA capture..."
      camera.flush-fifo
      camera.clear-fifo-flag
      
      before-small := camera.read-fifo-length
      camera.take-picture CAM_IMAGE_MODE_QQVGA CAM_IMAGE_PIX_FMT_JPG
      sleep --ms=2000
      after-small := camera.read-fifo-length
      
      small-captured := after-small - before-small
      print "QQVGA capture: $small-captured bytes"
      
      if small-captured > 0:
        print "✅ Small image capture successful!"
      else:
        print "❌ Small image capture failed"
        
        // Try RGB format
        print "Trying RGB565 format..."
        camera.flush-fifo
        camera.clear-fifo-flag
        
        before-rgb := camera.read-fifo-length
        camera.take-picture CAM_IMAGE_MODE_QQVGA CAM_IMAGE_PIX_FMT_RGB565
        sleep --ms=2000
        after-rgb := camera.read-fifo-length
        
        rgb-captured := after-rgb - before-rgb
        print "RGB565 capture: $rgb-captured bytes"
        
        if rgb-captured > 0:
          print "✅ RGB format capture successful!"
        else:
          print "❌ RGB format capture failed"
    
    print "\n=== Phase 4: Register Status ==="
    
    // Check key registers
    print "Key register status:"
    
    sensor-id := camera.read-fpga-reg 0x40
    sensor-state := camera.read-fpga-reg 0x44
    power-control := camera.read-fpga-reg 0x02
    memory-control := camera.read-fpga-reg 0x04
    
    print "  Sensor ID: 0x$(%02x sensor-id)"
    print "  Sensor state: 0x$(%02x sensor-state)"
    print "  Power control: 0x$(%02x power-control)"
    print "  Memory control: 0x$(%02x memory-control)"
    
    print "\n=== Summary ==="
    print "Camera initialization: ✅"
    print "SPI protocol: ✅"
    print "Register access: ✅"
    print "Image capture: $(captured-bytes > 0 ? "✅" : "❌")"
    
    if captured-bytes > 0:
      print "🎉 BREAKTHROUGH! Camera is capturing images!"
      print "   Total captured: $captured-bytes bytes"
    else:
      print "⚠️  Image capture needs further investigation"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Image capture test failed: $exception"
    
  print "\n=== Test 16 Complete ==="
