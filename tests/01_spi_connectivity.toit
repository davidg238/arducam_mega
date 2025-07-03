// Basic SPI connectivity test

import spi
import gpio

main:
  print "=== 01: BASIC SPI CONNECTIVITY ==="
  print "Testing fundamental SPI communication..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created on CS pin 22"
    
    // Test basic register reads
    registers := [0x00, 0x01, 0x40, 0x44, 0x45]
    print "\nTesting register reads:"
    all-same := true
    first-val := null
    
    registers.do: | reg |
      command := #[reg & 0x7F, 0x00, 0x00]
      device.write command
      responses := device.read 3
      val := responses[2]
      
      if first-val == null: first-val = val
      else if val != first-val: all-same = false
      
      print "  Register 0x$(%02x reg): 0x$(%02x val)"
    
    if all-same and first-val == 0x55:
      print "\n❌ CRITICAL: All registers return 0x55"
      print "  This indicates hardware communication issue"
      print "  Check: power, wiring, device type"
      return
    else if all-same:
      print "\n⚠️  All registers return same value (0x$(%02x first-val))"
      print "  Device may be in wrong state or different type"
    else:
      print "\n✅ SUCCESS: Varied register responses detected"
      print "  Hardware communication is working"
    
    device.close
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 01: BASIC SPI CONNECTIVITY COMPLETE ==="
