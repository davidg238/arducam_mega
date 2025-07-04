// 01: Basic SPI protocol validation

import spi
import gpio

main:
  print "=== 01: SPI PROTOCOL BASIC ==="
  print "Testing fundamental SPI communication protocols..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created (1MHz, Mode 0, CS=22)"
    
    // Test read protocol: [addr&0x7F, 0x00, 0x00] -> read 3, use byte 2
    print "\nTesting read protocol..."
    test-registers := [0x00, 0x01, 0x40, 0x44]
    responses := []
    
    test-registers.do: | reg |
      command := #[reg & 0x7F, 0x00, 0x00]
      device.write command
      resp := device.read 3
      val := resp[2]
      responses.add val
      print "  Register 0x$(%02x reg): 0x$(%02x val)"
    
    // Test write protocol: [addr|0x80, value]
    print "\nTesting write protocol..."
    device.write #[0x07 | 0x80, 0x40]  // Reset command
    print "  Write test: 0x07 = 0x40 (reset)"
    
    // Analyze responses
    unique-responses := responses.filter: | val | (responses.filter: it == val).size == 1
    all-same := responses.every: responses[0] == it
    
    if all-same and responses[0] == 0x55:
      print "\n❌ CRITICAL: All registers return 0x55"
      print "  Indicates hardware/device communication issue"
    else if all-same:
      print "\n⚠️  All registers return 0x$(%02x responses[0])"
    else:
      print "\n✅ SUCCESS: Mixed register responses ($unique-responses.size unique)"
    
    device.close
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 01: SPI PROTOCOL BASIC COMPLETE ==="
