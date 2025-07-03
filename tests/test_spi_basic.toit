// Very basic SPI test to check hardware connection

import spi
import gpio

main:
  print "=== BASIC SPI HARDWARE TEST ==="
  print "Testing raw SPI communication..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    // Test different SPI settings
    frequencies := [100_000, 500_000, 1_000_000, 2_000_000]
    modes := [0, 1, 2, 3]
    
    frequencies.do: | freq |
      modes.do: | mode |
        print "\nTesting frequency $freq Hz, mode $mode..."
        
        device := bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=mode
        
        // Try simple register reads
        test-addrs := [0x00, 0x40, 0x44]
        test-addrs.do: | addr |
          // Arduino protocol: send [addr, 0x00, 0x00], read 3 bytes
          command := #[addr & 0x7F, 0x00, 0x00]
          device.write command
          responses := device.read 3
          result := responses[2]
          
          print "  Addr 0x$(%02x addr): 0x$(%02x result) (full: $(%02x responses[0]) $(%02x responses[1]) $(%02x responses[2]))"
        
        // Check if we get consistent responses
        consistent := true
        first-response := 0
        for i := 0; i < 3; i++:
          command := #[0x00, 0x00, 0x00]
          device.write command
          responses := device.read 3
          if i == 0:
            first-response = responses[2]
          else:
            if responses[2] != first-response:
              consistent = false
        
        if consistent:
          print "  ✅ Responses are consistent"
        else:
          print "  ⚠️  Responses vary between reads"
          
        // Try a different protocol - maybe single byte reads
        print "  Testing single byte protocol..."
        device.write #[0x00]
        single-resp := device.read 1
        print "  Single byte read: 0x$(%02x single-resp[0])"
        
        // Try write then read separately
        print "  Testing separate write/read..."
        device.write #[0x40 & 0x7F]
        sep-resp := device.read 1
        print "  Separate read: 0x$(%02x sep-resp[0])"
        
        device.close
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== BASIC SPI TEST COMPLETE ==="
