// Test 17: 96x96 Image Capture Test
// Goal: Capture smallest possible image to debug capture mechanism
// Success: Camera captures 96x96 image data to FIFO

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 17: 96x96 Image Capture Test ==="
  print "Goal: Capture smallest image (96x96) to debug capture mechanism"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Initialize Camera ==="
    camera.on
    print "✅ Camera initialized successfully"
    
    print "\n=== Phase 2: Capture 96x96 Image ==="
    
    // Clear FIFO and reset
    print "Clearing FIFO..."
    camera.flush-fifo
    camera.clear-fifo-flag
    
    // Check initial FIFO state
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO length: $initial-fifo bytes"
    
    // Expected sizes for 96x96:
    // - Raw RGB565: 96 * 96 * 2 = 18,432 bytes
    // - Raw RGB888: 96 * 96 * 3 = 27,648 bytes  
    // - JPEG compressed: ~1,000-5,000 bytes (depends on content)
    print "Expected sizes - RGB565: 18,432 bytes, JPEG: ~1,000-5,000 bytes"
    
    print "\n=== Test 1: 96x96 JPEG Capture ==="
    
    // Capture 96x96 JPEG
    print "Capturing 96x96 JPEG image..."
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    
    // Wait for capture - try different wait times
    print "Waiting 2 seconds for capture..."
    sleep --ms=2000
    
    fifo-after-2s := camera.read-fifo-length
    captured-2s := fifo-after-2s - initial-fifo
    print "After 2s: FIFO=$fifo-after-2s, captured=$captured-2s bytes"
    
    if captured-2s == 0:
      print "No data after 2s, waiting additional 3 seconds..."
      sleep --ms=3000
      
      fifo-after-5s := camera.read-fifo-length
      captured-5s := fifo-after-5s - initial-fifo
      print "After 5s: FIFO=$fifo-after-5s, captured=$captured-5s bytes"
      
      if captured-5s == 0:
        print "No data after 5s, trying longer wait..."
        sleep --ms=5000
        
        fifo-after-10s := camera.read-fifo-length
        captured-10s := fifo-after-10s - initial-fifo
        print "After 10s: FIFO=$fifo-after-10s, captured=$captured-10s bytes"
    
    final-fifo := camera.read-fifo-length
    captured-jpeg := final-fifo - initial-fifo
    
    if captured-jpeg > 0:
      print "✅ JPEG capture successful! Captured $captured-jpeg bytes"
      
      // Try to read image data
      print "Reading image data..."
      camera.set-fifo-burst
      
      // Read first 20 bytes
      header-bytes := []
      20.repeat: | i |
        try:
          byte := camera.read-byte
          header-bytes.add byte
        finally: | is-exception exception |
          if is-exception:
            print "  Error reading byte $i: $exception"
            header-bytes.add 0x00
      
      print "Image header (first 20 bytes): $header-bytes"
      
      // Check for JPEG signature
      if header-bytes.size >= 2 and header-bytes[0] == 0xFF and header-bytes[1] == 0xD8:
        print "🎉 SUCCESS! Valid JPEG header found (FF D8)!"
        print "   96x96 JPEG capture is working!"
        return
      else:
        print "⚠️  No JPEG header found, but data captured"
        print "   May be different format or need different read method"
    else:
      print "❌ JPEG capture failed - no data in FIFO"
    
    print "\n=== Test 2: 96x96 RGB565 Capture ==="
    
    // Try RGB565 format
    print "Trying RGB565 format..."
    camera.flush-fifo
    camera.clear-fifo-flag
    
    initial-rgb := camera.read-fifo-length
    print "Initial RGB FIFO: $initial-rgb bytes"
    
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_RGB565
    sleep --ms=5000  // Longer wait for RGB
    
    final-rgb := camera.read-fifo-length
    captured-rgb := final-rgb - initial-rgb
    
    print "RGB565 capture result: $captured-rgb bytes"
    
    if captured-rgb > 0:
      print "✅ RGB565 capture successful!"
      
      // Expected size check
      expected-rgb := 96 * 96 * 2  // 18,432 bytes
      print "Expected RGB565 size: $expected-rgb bytes"
      print "Actual captured: $captured-rgb bytes"
      
      if captured-rgb == expected-rgb:
        print "🎉 PERFECT! Captured exactly expected RGB565 size!"
      else if captured-rgb > expected-rgb * 0.8:  // Within 80% of expected
        print "✅ Captured reasonable RGB565 size"
      else:
        print "⚠️  Captured size different from expected"
    else:
      print "❌ RGB565 capture failed"
    
    print "\n=== Test 3: Alternative Capture Methods ==="
    
    // Try using direct ArduCam commands
    print "Trying direct ArduCam commands..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    
    initial-direct := camera.read-fifo-length
    print "Initial direct FIFO: $initial-direct bytes"
    
    // Send format command directly
    format-cmd := #[0x55, 0x01, 0x1A, 0xAA]  // JPEG format + 96x96 mode
    print "Sending direct format command: $format-cmd"
    camera.camera.write format-cmd
    sleep --ms=100
    
    // Send capture command directly
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]  // Take picture command
    print "Sending direct capture command: $capture-cmd"
    camera.camera.write capture-cmd
    sleep --ms=5000
    
    final-direct := camera.read-fifo-length
    captured-direct := final-direct - initial-direct
    
    print "Direct command result: $captured-direct bytes"
    
    if captured-direct > 0:
      print "✅ Direct commands successful!"
    else:
      print "❌ Direct commands failed"
    
    print "\n=== Test 4: Check Camera Status ==="
    
    // Check key status registers
    print "Checking camera status registers..."
    
    sensor-id := camera.read-fpga-reg 0x40
    sensor-state := camera.read-fpga-reg 0x44
    power-control := camera.read-fpga-reg 0x02
    memory-control := camera.read-fpga-reg 0x04
    i2c-address := camera.read-fpga-reg 0x0A
    
    print "  Sensor ID: 0x$(%02x sensor-id)"
    print "  Sensor state: 0x$(%02x sensor-state)"
    print "  Power control: 0x$(%02x power-control)"
    print "  Memory control: 0x$(%02x memory-control)"
    print "  I2C address: 0x$(%02x i2c-address)"
    
    // Check if sensor state indicates any issues
    if sensor-state & 0x03 == 0x02:
      print "  ✅ Sensor state indicates ready/idle"
    else:
      print "  ⚠️  Sensor state may indicate issue: 0x$(%02x sensor-state)"
    
    print "\n=== Summary ==="
    print "96x96 JPEG capture: $(captured-jpeg > 0 ? "✅ $captured-jpeg bytes" : "❌")"
    print "96x96 RGB565 capture: $(captured-rgb > 0 ? "✅ $captured-rgb bytes" : "❌")"
    print "Direct commands: $(captured-direct > 0 ? "✅ $captured-direct bytes" : "❌")"
    
    total-captured := captured-jpeg + captured-rgb + captured-direct
    if total-captured > 0:
      print "🎉 SUCCESS! At least one capture method is working!"
      print "   Total data captured: $total-captured bytes"
    else:
      print "❌ No capture methods successful"
      print "   Need to investigate capture mechanism further"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: 96x96 capture test failed: $exception"
    
  print "\n=== Test 17 Complete ==="
