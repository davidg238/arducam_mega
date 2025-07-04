// Test 32: Corrected Register Writes WITH wait-idle calls
// Goal: Implement C code sequence with proper I2C bridge waits
// Success: Camera captures image data with proper wait-idle sequence

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 32: Corrected with wait-idle calls ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "STEP 2: C code register sequence WITH proper waits..."
    
    // Clear FIFO first
    camera.flush-fifo
    camera.clear-fifo-flag
    
    print "Setting format register (0x20) to JPEG..."
    camera.write-fpga-reg 0x20 1  // CAM_IMAGE_PIX_FMT_JPG = 1
    camera.wait-idle  // CRITICAL: Wait for I2C bridge to settle
    
    print "Setting capture resolution (0x21) to 96x96..."
    camera.write-fpga-reg 0x21 0x0A  // Mode 0x0A = 96x96
    camera.wait-idle  // CRITICAL: Wait for I2C bridge to settle
    
    print "Checking register states after waits..."
    format-check := camera.read-fpga-reg 0x20
    sensor-state := camera.read-fpga-reg 0x44
    print "Format register: 0x$(%02x format-check)"
    print "Sensor state: 0x$(%02x sensor-state) (should be idle after waits)"
    
    before-fifo := camera.read-fifo-length
    print "FIFO before capture: $before-fifo bytes"
    
    print "STEP 3: Trigger capture with wait..."
    print "Writing FIFO_START_MASK to trigger capture..."
    camera.write-fpga-reg 0x04 0x02  // Start capture
    camera.wait-idle  // Wait for capture command to process
    
    print "Waiting for image capture to complete..."
    sleep --ms=3000
    
    after-fifo := camera.read-fifo-length
    captured := after-fifo - before-fifo
    
    print "FIFO after capture: $after-fifo bytes"
    print "Captured data: $captured bytes"
    
    if captured > 0:
      print "🎉 SUCCESS! Proper wait-idle sequence captured data!"
      
      print "STEP 4: Read image data..."
      camera.set-fifo-burst
      
      header := []
      8.repeat: | i |
        try:
          byte := camera.read-byte
          header.add byte
        finally: | is-exception exception |
          if is-exception:
            print "Error reading byte $i: $exception"
            return
      
      print "Image header: $header"
      
      if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
        print "🎉 PERFECT! Valid JPEG header found!"
      else:
        print "⚠️  Data captured, checking if valid..."
        non-zero := header.any: | byte | byte != 0x00
        print "Contains varied data: $(non-zero ? "✅" : "❌")"
      
    else:
      print "❌ Still no data captured"
      
      print "STEP 4: Additional debugging..."
      
      // Check if camera state indicates issues
      final-sensor-state := camera.read-fpga-reg 0x44
      print "Final sensor state: 0x$(%02x final-sensor-state)"
      
      // Try using the library's take-picture method which has all the waits
      print "Trying library take-picture method (has all waits built-in)..."
      
      camera.flush-fifo
      camera.clear-fifo-flag
      
      before-lib := camera.read-fifo-length
      camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
      sleep --ms=3000
      
      after-lib := camera.read-fifo-length
      lib-captured := after-lib - before-lib
      
      print "Library method result: $lib-captured bytes"
      
      if lib-captured > 0:
        print "✅ Library method works - our manual sequence needs refinement"
      else:
        print "❌ Even library method fails - deeper issue"
    
    print "\n=== Wait-idle Analysis ==="
    print "Format register set: $(format-check == 1 ? "✅" : "❌")"
    print "Sensor state after waits: $(sensor-state & 0x03 == 2 ? "✅ Idle" : "⚠️ Not idle")"
    print "Manual capture: $(captured > 0 ? "✅" : "❌")"
    
    if captured == 0:
      print "\n🔍 The issue may be:"
      print "   1. Additional sensor configuration needed"
      print "   2. Different trigger sequence required"
      print "   3. Timing between format/resolution/trigger"
      print "   4. Need to configure image sensor via I2C tunnel first"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 32 Complete ==="
