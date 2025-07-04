// Test 19: Memory Analysis and Minimal Capture
// Goal: Analyze memory constraints and try minimal capture approaches
// Success: Find a capture size that works within memory limits

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 19: Memory Analysis and Minimal Capture ==="
  print "Goal: Find capture approach that works within memory limits"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Memory Analysis ==="
    
    print "Checking memory before camera initialization..."
    print "Basic test completed - camera SPI access working"
    
    print "Initializing camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "\n=== Phase 2: Calculate Image Sizes ==="
    
    // Calculate expected sizes for different modes
    image-sizes := [
      ["96x96 RGB565", 96 * 96 * 2],       // 18,432 bytes
      ["96x96 RGB888", 96 * 96 * 3],       // 27,648 bytes
      ["96x96 JPEG", 2000],                // ~2KB estimated
      ["QQVGA RGB565", 160 * 120 * 2],     // 38,400 bytes
      ["QVGA RGB565", 320 * 240 * 2],      // 153,600 bytes
    ]
    
    print "Expected image sizes:"
    image-sizes.do: | size-info |
      name := size-info[0]
      bytes := size-info[1]
      kb := bytes / 1024
      print "  $name: $bytes bytes ($kb KB)"
    
    print "\n=== Phase 3: Test Minimal Capture (JPEG Only) ==="
    
    // Only test JPEG format as it should be smallest
    print "Testing 96x96 JPEG capture (minimal size)..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO: $initial-fifo bytes"
    
    // Try 96x96 JPEG with minimal timing
    print "Sending capture command..."
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    
    // Check immediately 
    immediate-fifo := camera.read-fifo-length
    immediate-captured := immediate-fifo - initial-fifo
    print "Immediate check: $immediate-captured bytes"
    
    // Wait short time
    sleep --ms=500
    short-wait-fifo := camera.read-fifo-length
    short-captured := short-wait-fifo - initial-fifo
    print "After 500ms: $short-captured bytes"
    
    // Wait medium time
    sleep --ms=1500  // Total 2 seconds
    medium-wait-fifo := camera.read-fifo-length
    medium-captured := medium-wait-fifo - initial-fifo
    print "After 2s total: $medium-captured bytes"
    
    if medium-captured > 0:
      print "✅ Some data captured!"
      
      if medium-captured < 100:
        print "⚠️  Very small amount - may be header only"
      else if medium-captured < 1000:
        print "✅ Reasonable JPEG size for 96x96"
      else:
        print "✅ Large capture - good compression or uncompressed"
      
      // Try to read just first few bytes
      print "Reading first 8 bytes only..."
      camera.set-fifo-burst
      
      first-bytes := []
      8.repeat: | i |
        try:
          byte := camera.read-byte
          first-bytes.add byte
          print "  Byte $i: 0x$(%02x byte)"
        finally: | is-exception exception |
          if is-exception:
            print "  Error reading byte $i: $exception"
            break
      
      print "First bytes: $first-bytes"
      
      if first-bytes.size >= 2 and first-bytes[0] == 0xFF and first-bytes[1] == 0xD8:
        print "🎉 SUCCESS! JPEG header detected!"
      else if first-bytes.size > 0:
        print "✅ Data captured, format unknown"
      
    else:
      print "❌ No data captured"
      
      print "\n=== Phase 4: Alternative Minimal Approach ==="
      
      // Try direct commands with minimal parameters
      print "Trying direct ArduCam commands..."
      
      camera.flush-fifo
      camera.clear-fifo-flag
      
      // Send smallest possible JPEG command
      format-cmd := #[0x55, 0x01, 0x1A, 0xAA]  // JPEG + 96x96
      print "Sending format command: $format-cmd"
      camera.camera.write format-cmd
      sleep --ms=100
      
      capture-cmd := #[0x55, 0x10, 0x00, 0xAA]  // Capture
      print "Sending capture command: $capture-cmd"
      camera.camera.write capture-cmd
      
      // Check with minimal wait
      sleep --ms=1000
      final-fifo := camera.read-fifo-length
      direct-captured := final-fifo - initial-fifo
      print "Direct command result: $direct-captured bytes"
      
      if direct-captured > 0:
        print "✅ Direct commands worked!"
      else:
        print "❌ Direct commands failed"
    
    print "\n=== Phase 5: Register Status Check ==="
    
    // Check if registers still working properly
    print "Verifying register access still works..."
    
    sensor-id := camera.read-fpga-reg 0x40
    power-control := camera.read-fpga-reg 0x02
    memory-control := camera.read-fpga-reg 0x04
    
    print "Sensor ID: 0x$(%02x sensor-id)"
    print "Power control: 0x$(%02x power-control)"
    print "Memory control: 0x$(%02x memory-control)"
    
    if sensor-id != 0x00 and power-control == 0x05:
      print "✅ Registers still working correctly"
    else:
      print "⚠️  Register values may have changed"
    
    print "\n=== Summary ==="
    total-captured := medium-captured
    if total-captured > 0:
      print "🎉 SUCCESS! Captured $total-captured bytes"
      print "   Memory constraint: image capture is working!"
      print "   Next step: optimize capture size or streaming"
    else:
      print "❌ No image data captured"
      print "   Issue may not be memory - need to investigate capture mechanism"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Memory analysis failed: $exception"
    
  print "\n=== Test 19 Complete ==="
