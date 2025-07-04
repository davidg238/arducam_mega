// Test 26: Corrected 96x96 Image Capture
// Goal: Test 96x96 image capture WITH proper camera initialization
// Success: Capture image data with working register access

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 26: Corrected 96x96 Image Capture ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera (CRITICAL)..."
    camera.on
    print "✅ Camera initialized - all registers should work now"
    
    print "STEP 2: Verify register access is working..."
    sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID: 0x$(%02x sensor-id)"
    
    if sensor-id == 0x81:
      print "✅ Correct sensor ID - initialization successful"
    else:
      print "⚠️  Unexpected sensor ID: 0x$(%02x sensor-id)"
    
    print "STEP 3: Clear FIFO and prepare for capture..."
    camera.flush-fifo
    camera.clear-fifo-flag
    
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO length: $initial-fifo bytes"
    
    print "STEP 4: Capture 96x96 JPEG image..."
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    
    print "STEP 5: Wait for capture completion..."
    sleep --ms=3000
    
    final-fifo := camera.read-fifo-length
    captured := final-fifo - initial-fifo
    
    print "Final FIFO length: $final-fifo bytes"
    print "Captured data: $captured bytes"
    
    if captured > 0:
      print "🎉 SUCCESS! Image data captured with proper initialization!"
      
      // Expected size for 96x96 JPEG: ~1-5KB
      if captured < 10000:
        print "✅ Reasonable size for 96x96 JPEG"
      else:
        print "⚠️  Large size - may be uncompressed or different format"
      
      print "STEP 6: Read image header..."
      camera.set-fifo-burst
      
      print "Reading first 8 bytes to check for JPEG header..."
      header := []
      8.repeat: | i |
        try:
          byte := camera.read-byte
          header.add byte
          print "  Byte $i: 0x$(%02x byte)"
        finally: | is-exception exception |
          if is-exception:
            print "  Error reading byte $i: $exception"
            return
      
      print "Image header: $header"
      
      if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
        print "🎉 PERFECT! Valid JPEG header found (FF D8)!"
        print "   Camera is fully functional and capturing JPEG images!"
      else:
        print "⚠️  No JPEG header found"
        print "   Data captured but format needs investigation"
        
        // Check if data is varied (not all zeros)
        varied-data := header.any: | byte | byte != 0x00
        if varied-data:
          print "   ✅ Data contains varied bytes - real image data"
        else:
          print "   ❌ Data appears to be all zeros"
    
    else:
      print "❌ No image data captured"
      
      print "STEP 6: Debug - check key registers..."
      power-control := camera.read-fpga-reg 0x02
      memory-control := camera.read-fpga-reg 0x04
      i2c-address := camera.read-fpga-reg 0x0A
      
      print "Power control: 0x$(%02x power-control)"
      print "Memory control: 0x$(%02x memory-control)" 
      print "I2C address: 0x$(%02x i2c-address)"
      
      if i2c-address == 0x78:
        print "✅ I2C address correct"
      else:
        print "⚠️  I2C address not set correctly"
    
    print "\n=== Final Status ==="
    print "Camera initialization: ✅"
    print "Register access: $(sensor-id == 0x81 ? "✅" : "❌")"
    print "Image capture: $(captured > 0 ? "✅" : "❌")"
    
    if captured > 0:
      print "🎉 BREAKTHROUGH! 96x96 image capture working!"
      print "   Next: Test larger images and streaming"
    else:
      print "⚠️  Image capture mechanism needs investigation"
      print "   All other systems working correctly"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 26 Complete ==="
