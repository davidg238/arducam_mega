// Test write then read to see if new protocol works

import arducam_mega show *
import spi
import gpio

main:
  print "=== WRITE/READ TEST WITH NEW PROTOCOL ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    // Test the write/read cycle
    print "\nTesting write/read cycle:"
    
    // Read initial value
    initial := camera.read-reg 0x00
    print "Initial value: 0x$(%02x initial)"
    
    // Write a test value
    print "Writing 0xAA to register 0x00..."
    camera.write-reg 0x00 0xAA
    sleep --ms=5
    
    // Read it back
    readback1 := camera.read-reg 0x00
    print "Read back: 0x$(%02x readback1)"
    
    if readback1 == 0xAA:
      print "✅ SUCCESS! Write/read cycle works with new protocol!"
    else:
      print "❌ Write/read still failed"
      
      // Try different value
      print "Trying different value 0x55..."
      camera.write-reg 0x00 0x55
      sleep --ms=10
      readback2 := camera.read-reg 0x00
      print "Read back: 0x$(%02x readback2)"
      
      if readback2 == 0x55:
        print "✅ Works with longer delay!"
      else:
        print "❌ Still failed"
        
        // Try reading other registers
        print "\nTrying other registers:"
        regs := [0x01, 0x02, 0x04, 0x07]
        names := ["FRAMES", "POWER", "FIFO", "RESET"]
        
        for i := 0; i < regs.size; i++:
          reg := regs[i]
          name := names[i]
          value := camera.read-reg reg
          print "  Reg 0x$(%02x reg) ($name): 0x$(%02x value)"
          
          if value != 0x00:
            print "    ✅ Non-zero value found!"
      
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\nTest complete"
