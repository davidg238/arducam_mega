// Test 29: Capture Command Debug
// Goal: Debug why capture commands aren't generating FIFO data
// Success: Find working capture command sequence

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 29: Capture Command Debug ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized (sensor ID: 0x$(%02x camera.read-fpga-reg(0x40)))"
    
    print "STEP 2: Test different capture approaches..."
    
    // Approach 1: Current method
    print "\n--- Approach 1: Current take-picture method ---"
    camera.flush-fifo
    camera.clear-fifo-flag
    
    before1 := camera.read-fifo-length
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    sleep --ms=2000
    after1 := camera.read-fifo-length
    print "Current method: $before1 -> $after1 bytes"
    
    // Approach 2: Direct ArduCam commands only
    print "\n--- Approach 2: Direct ArduCam commands ---"
    camera.flush-fifo
    camera.clear-fifo-flag
    
    before2 := camera.read-fifo-length
    
    // Send format command
    format-cmd := #[0x55, 0x01, 0x1A, 0xAA]  // JPEG + 96x96
    print "Sending format: $format-cmd"
    camera.camera.write format-cmd
    sleep --ms=200
    
    // Send capture command
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]  // Take picture
    print "Sending capture: $capture-cmd"
    camera.camera.write capture-cmd
    sleep --ms=3000
    
    after2 := camera.read-fifo-length
    print "Direct commands: $before2 -> $after2 bytes"
    
    // Approach 3: Test if camera responds to any commands
    print "\n--- Approach 3: Test camera responsiveness ---"
    
    // Try reading some registers to see if they change after commands
    print "Register states after commands:"
    
    status-regs := [
      [0x41, "Year ID"],
      [0x42, "Month ID"], 
      [0x43, "Day ID"],
      [0x44, "Sensor state"],
      [0x02, "Power control"],
      [0x04, "Memory control"],
    ]
    
    status-regs.do: | reg-info |
      reg := reg-info[0]
      name := reg-info[1]
      value := camera.read-fpga-reg reg
      print "  $name (0x$(%02x reg)): 0x$(%02x value)"
    
    // Approach 4: Try different image formats
    print "\n--- Approach 4: Try RGB format ---"
    camera.flush-fifo
    camera.clear-fifo-flag
    
    before4 := camera.read-fifo-length
    
    // RGB565 format might work differently
    rgb-format := #[0x55, 0x01, 0x2A, 0xAA]  // RGB565 + 96x96
    print "Sending RGB format: $rgb-format"
    camera.camera.write rgb-format
    sleep --ms=200
    
    camera.camera.write capture-cmd
    sleep --ms=3000
    
    after4 := camera.read-fifo-length
    print "RGB format: $before4 -> $after4 bytes"
    
    // Approach 5: Try memory control triggers
    print "\n--- Approach 5: Memory control triggers ---"
    camera.flush-fifo
    camera.clear-fifo-flag
    
    before5 := camera.read-fifo-length
    
    // Try triggering via memory control register
    print "Setting memory control to start picture taking..."
    camera.write-fpga-reg 0x04 0x02  // Bit[1]=1 (start taking pictures)
    sleep --ms=100
    
    // Send format and capture
    camera.camera.write format-cmd
    sleep --ms=200
    camera.camera.write capture-cmd
    sleep --ms=3000
    
    after5 := camera.read-fifo-length
    print "Memory trigger: $before5 -> $after5 bytes"
    
    print "\n=== Summary of Approaches ==="
    approaches := [
      ["Current method", after1 - before1],
      ["Direct commands", after2 - before2],
      ["RGB format", after4 - before4],
      ["Memory trigger", after5 - before5],
    ]
    
    working-approaches := 0
    approaches.do: | approach |
      name := approach[0]
      captured := approach[1]
      status := captured > 0 ? "✅ $captured bytes" : "❌ 0 bytes"
      print "$name: $status"
      
      if captured > 0:
        working-approaches++
    
    if working-approaches > 0:
      print "🎉 SUCCESS! Found working approach(es)!"
    else:
      print "❌ No approaches generated FIFO data"
      print "   Issue may be: sensor not responding, wrong commands, or hardware"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 29 Complete ==="
