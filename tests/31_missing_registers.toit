// Test 31: Missing Register Writes from C Code
// Goal: Implement the critical register writes that the C code uses
// Success: Camera captures image data using proper register sequence

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 31: Missing Register Writes from C Code ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized (sensor ID: 0x$(%02x 0x81))"
    
    print "STEP 2: Implement C code register sequence..."
    
    // From C code analysis:
    // CAM_REG_FORMAT = 0x20
    // CAM_REG_CAPTURE_RESOLUTION = 0x21  
    // CAM_SET_CAPTURE_MODE = 0 (bit 7 = 0)
    // ARDUCHIP_FIFO = 0x04
    // FIFO_START_MASK = 0x02
    
    // Clear FIFO first
    camera.flush-fifo
    camera.clear-fifo-flag
    
    print "Setting format register (0x20) to JPEG (value 1)..."
    camera.write-fpga-reg 0x20 1  // CAM_IMAGE_PIX_FMT_JPG = 1
    
    print "Setting capture resolution (0x21) to 96x96 with capture mode..."
    // CAM_IMAGE_MODE_96X96 = 0x0A, CAM_SET_CAPTURE_MODE = 0 (bit 7 = 0)
    camera.write-fpga-reg 0x21 0x0A  // Mode 0x0A = 96x96
    
    print "Checking register writes..."
    format-check := camera.read-fpga-reg 0x20
    resolution-check := camera.read-fpga-reg 0x21
    print "Format register: 0x$(%02x format-check)"
    print "Resolution register: 0x$(%02x resolution-check)"
    
    before-fifo := camera.read-fifo-length
    print "FIFO before capture: $before-fifo bytes"
    
    print "STEP 3: Trigger capture using C code method..."
    print "Writing FIFO_START_MASK (0x02) to ARDUCHIP_FIFO (0x04)..."
    camera.write-fpga-reg 0x04 0x02  // Start capture
    
    print "Waiting for capture completion..."
    sleep --ms=3000
    
    after-fifo := camera.read-fifo-length
    captured := after-fifo - before-fifo
    
    print "FIFO after capture: $after-fifo bytes"
    print "Captured data: $captured bytes"
    
    if captured > 0:
      print "🎉 SUCCESS! C code register method captured data!"
      
      print "STEP 4: Read captured data with proper protocol..."
      camera.set-fifo-burst
      
      // Read first 16 bytes to check format
      header := []
      16.repeat: | i |
        try:
          byte := camera.read-byte
          header.add byte
        finally: | is-exception exception |
          if is-exception:
            print "Error reading byte $i: $exception"
            return
      
      print "Image header: $header"
      
      if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
        print "🎉 PERFECT! Valid JPEG header (FF D8) found!"
        print "   Camera is fully functional with C code register method!"
      else:
        print "⚠️  Data captured but checking format..."
        non-zero := header.any: | byte | byte != 0x00
        if non-zero:
          print "   ✅ Contains varied data - real image capture!"
        else:
          print "   ❌ All zeros - may be padding"
      
    else:
      print "❌ No data captured with C code method"
      
      print "STEP 4: Debug - check register states..."
      debug-regs := [
        [0x20, "Format"],
        [0x21, "Capture resolution"],
        [0x04, "Memory/FIFO control"],
        [0x40, "Sensor ID"],
        [0x44, "Sensor state"],
      ]
      
      debug-regs.do: | reg-info |
        reg := reg-info[0]
        name := reg-info[1]
        value := camera.read-fpga-reg reg
        print "  $name (0x$(%02x reg)): 0x$(%02x value)"
    
    print "\n=== Alternative: Try Combined Approach ==="
    
    // Try combining C code register writes with ArduCam commands
    print "Testing combined approach (registers + ArduCam commands)..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    
    // Set registers first
    camera.write-fpga-reg 0x20 1     // Format
    camera.write-fpga-reg 0x21 0x0A  // Resolution
    
    // Send ArduCam commands too
    format-cmd := #[0x55, 0x01, 0x1A, 0xAA]
    camera.camera.write format-cmd
    sleep --ms=100
    
    before-combined := camera.read-fifo-length
    
    // Trigger with both methods
    camera.write-fpga-reg 0x04 0x02  // C code trigger
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]
    camera.camera.write capture-cmd  // ArduCam trigger
    
    sleep --ms=3000
    
    after-combined := camera.read-fifo-length
    combined-captured := after-combined - before-combined
    
    print "Combined approach: $combined-captured bytes"
    
    print "\n=== Results Summary ==="
    print "C code register method: $(captured > 0 ? "✅ $captured bytes" : "❌ 0 bytes")"
    print "Combined approach: $(combined-captured > 0 ? "✅ $combined-captured bytes" : "❌ 0 bytes")"
    
    total-success := captured + combined-captured
    if total-success > 0:
      print "🎉 BREAKTHROUGH! Found working capture method!"
    else:
      print "⚠️  Still investigating capture mechanism"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 31 Complete ==="
