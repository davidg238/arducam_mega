// Test 24: Use Working Registers for Image Capture
// Goal: Use confirmed working registers (0x04, 0x0A) to enable image capture
// Success: Configure camera using working register writes

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 24: Working Registers for Image Capture ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Configure Working Registers ==="
    
    // We know these registers work for writes:
    // 0x04 - Memory control
    // 0x0A - I2C device address
    
    print "Setting I2C device address to 0x78..."
    camera.write-fpga-reg 0x0A 0x78
    sleep --ms=10
    
    readback-i2c := camera.read-fpga-reg 0x0A
    print "I2C address readback: 0x$(%02x readback-i2c)"
    
    print "Setting memory control for picture taking..."
    // From Application Note: Bit[1]=1 (start taking pictures)
    camera.write-fpga-reg 0x04 0x02
    sleep --ms=10
    
    readback-mem := camera.read-fpga-reg 0x04
    print "Memory control readback: 0x$(%02x readback-mem)"
    
    if readback-i2c == 0x78:
      print "✅ I2C address set correctly!"
    else:
      print "⚠️  I2C address not set correctly"
    
    if readback-mem == 0x02:
      print "✅ Memory control set correctly!"
    else:
      print "⚠️  Memory control not set correctly"
    
    print "\n=== Phase 2: Minimal Image Capture Test ==="
    
    // Clear FIFO using memory control register
    print "Clearing FIFO using memory control..."
    camera.write-fpga-reg 0x04 0x01  // Clear flag
    sleep --ms=50
    
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO: $initial-fifo bytes"
    
    // Try direct ArduCam commands for 96x96 JPEG
    print "Sending direct ArduCam commands..."
    
    // Format command: JPEG + 96x96
    format-cmd := #[0x55, 0x01, 0x1A, 0xAA]
    camera.camera.write format-cmd
    sleep --ms=100
    
    // Trigger picture taking via memory control register
    print "Triggering capture via memory control register..."
    camera.write-fpga-reg 0x04 0x02  // Start taking pictures
    sleep --ms=1000
    
    after-trigger := camera.read-fifo-length
    print "FIFO after trigger: $after-trigger bytes"
    
    // Send capture command
    capture-cmd := #[0x55, 0x10, 0x00, 0xAA]
    camera.camera.write capture-cmd
    sleep --ms=2000
    
    final-fifo := camera.read-fifo-length
    captured := final-fifo - initial-fifo
    
    print "Final FIFO: $final-fifo bytes"
    print "Captured: $captured bytes"
    
    if captured > 0:
      print "🎉 SUCCESS! Image data captured!"
      
      // Try to read first few bytes
      print "Setting FIFO burst mode..."
      camera.set-fifo-burst
      
      print "Reading first 8 bytes..."
      8.repeat: | i |
        try:
          byte := camera.read-byte
          print "  Byte $i: 0x$(%02x byte)"
          
          if i == 0 and byte == 0xFF:
            print "    ✅ Possible JPEG start!"
          else if i == 1 and byte == 0xD8:
            print "    🎉 JPEG header confirmed! (FF D8)"
        finally: | is-exception exception |
          if is-exception:
            print "  Error reading byte $i: $exception"
            return
    else:
      print "❌ No image data captured"
      
      print "\n=== Phase 3: Alternative Approach ==="
      
      // Try different approach with working registers
      print "Trying alternative register sequence..."
      
      // Reset memory control
      camera.write-fpga-reg 0x04 0x00
      sleep --ms=50
      
      // Clear FIFO flag
      camera.write-fpga-reg 0x04 0x01
      sleep --ms=50
      
      // Check FIFO cleared
      cleared-fifo := camera.read-fifo-length
      print "FIFO after clear: $cleared-fifo bytes"
      
      // Set I2C address again
      camera.write-fpga-reg 0x0A 0x78
      sleep --ms=50
      
      // Start picture taking
      camera.write-fpga-reg 0x04 0x02
      sleep --ms=100
      
      // Send ArduCam commands
      camera.camera.write format-cmd
      sleep --ms=100
      camera.camera.write capture-cmd
      sleep --ms=3000
      
      final-alt := camera.read-fifo-length
      captured-alt := final-alt - cleared-fifo
      
      print "Alternative result: $captured-alt bytes"
      
      if captured-alt > 0:
        print "✅ Alternative approach successful!"
      else:
        print "❌ Alternative approach failed"
    
    print "\n=== Phase 4: Register Status Check ==="
    
    // Check all our key registers
    print "Final register status:"
    
    key-regs := [
      [0x0A, "I2C device address"],
      [0x04, "Memory control"],
      [0x40, "Sensor ID"],
      [0x45, "FIFO size low"],
      [0x46, "FIFO size mid"],
      [0x47, "FIFO size high"],
    ]
    
    key-regs.do: | reg-info |
      reg := reg-info[0]
      name := reg-info[1]
      
      value := camera.read-fpga-reg reg
      print "  $name (0x$(%02x reg)): 0x$(%02x value)"
    
    print "\n=== Summary ==="
    if captured > 0:
      print "🎉 BREAKTHROUGH! Working register approach successful!"
      print "   Captured $captured bytes using registers 0x04 and 0x0A"
    else:
      print "⚠️  No capture yet, but register writes confirmed working"
      print "   Next: investigate sensor configuration via I2C tunnel"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "=== Test 24 Complete ==="
