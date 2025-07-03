// Test different SPI protocol variants to find the working one

import spi
import gpio

main:
  print "=== SPI PROTOCOL VARIANTS TEST ==="
  print "Testing different SPI transaction patterns..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    // Test with confirmed camera CS pin
    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created on CS pin 22 (camera)"
    
    print "\n=== PROTOCOL 1: Current Implementation ==="
    print "Read: [addr&0x7F, 0x00, 0x00] -> read 3 bytes, use byte 2"
    print "Write: [addr|0x80, value]"
    
    // Test current read protocol
    addr := 0x00
    read-cmd := #[addr & 0x7F, 0x00, 0x00]
    device.write read-cmd
    read-resp := device.read 3
    print "  Read 0x$(%02x addr): cmd=$(%02x read-cmd[0]) $(%02x read-cmd[1]) $(%02x read-cmd[2]) -> resp=$(%02x read-resp[0]) $(%02x read-resp[1]) $(%02x read-resp[2]) = 0x$(%02x read-resp[2])"
    
    // Test current write protocol
    write-addr := 0x07  // Reset register
    write-val := 0x40   // Reset value
    write-cmd := #[write-addr | 0x80, write-val]
    device.write write-cmd
    print "  Write 0x$(%02x write-addr)=0x$(%02x write-val): cmd=$(%02x write-cmd[0]) $(%02x write-cmd[1])"
    
    print "\n=== PROTOCOL 2: Alternative Read Methods ==="
    
    // Try single transaction read
    print "  Single byte read:"
    device.write #[0x00]
    single-resp := device.read 1
    print "    0x00: $(%02x single-resp[0])"
    
    // Try two byte read
    print "  Two byte read:"
    device.write #[0x00, 0x00]
    two-resp := device.read 2
    print "    0x00: $(%02x two-resp[0]) $(%02x two-resp[1])"
    
    // Try different dummy bytes
    print "  Different dummy bytes:"
    variants := [[0x00, 0xFF, 0xFF], [0x00, 0xAA, 0x55], [0x00, 0x01, 0x02]]
    variants.do: | variant |
      device.write variant
      var-resp := device.read 3
      print "    cmd=$(%02x variant[0]) $(%02x variant[1]) $(%02x variant[2]) -> $(%02x var-resp[0]) $(%02x var-resp[1]) $(%02x var-resp[2])"
    
    print "\n=== PROTOCOL 3: Register-Specific Tests ==="
    
    // Test different registers that should have known values
    test-registers := [0x00, 0x01, 0x02, 0x04, 0x07, 0x40, 0x41, 0x44, 0x45, 0x46, 0x47]
    test-registers.do: | reg |
      cmd := #[reg & 0x7F, 0x00, 0x00]
      device.write cmd
      resp := device.read 3
      print "  Reg 0x$(%02x reg): 0x$(%02x resp[2])"
    
    print "\n=== PROTOCOL 4: Write-Read Verification ==="
    
    // Try writing and immediately reading back
    test-reg := 0x0A  // Debug device address register
    test-val := 0x78  // Standard I2C address
    
    print "  Writing 0x$(%02x test-val) to register 0x$(%02x test-reg)..."
    device.write #[test-reg | 0x80, test-val]
    sleep --ms=10
    
    print "  Reading back..."
    device.write #[test-reg & 0x7F, 0x00, 0x00]
    readback := device.read 3
    readback-val := readback[2]
    
    print "  Write verification: wrote 0x$(%02x test-val), read 0x$(%02x readback-val)"
    if readback-val == test-val:
      print "  ✅ Write-read verification SUCCESS!"
    else if readback-val == 0x55:
      print "  ❌ Still getting 0x55 - device not responding to writes"
    else:
      print "  ⚠️  Got different value - partial communication?"
    
    print "\n=== PROTOCOL 5: Timing Variations ==="
    
    // Test with different delays
    delays := [1, 10, 50, 100]
    delays.do: | delay |
      print "  Testing with $delay ms delay:"
      device.write #[0x40 & 0x7F, 0x00, 0x00]
      sleep --ms=delay
      delayed-resp := device.read 3
      print "    Result: 0x$(%02x delayed-resp[2])"
    
    print "\n=== PROTOCOL 6: Device Detection ==="
    
    // Check if device responds differently to different addresses
    device.write #[0xFF]  // Invalid command
    invalid-resp := device.read 1
    print "  Invalid command response: 0x$(%02x invalid-resp[0])"
    
    // Try a command that should definitely fail
    device.write #[0x00, 0x00, 0x00, 0x00, 0x00]  // Too many bytes
    junk-resp := device.read 1
    print "  Junk command response: 0x$(%02x junk-resp[0])"
    
    device.close
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== SPI PROTOCOL VARIANTS TEST COMPLETE ==="
  print "\nIf all responses are 0x55, the issue may be:"
  print "1. Device not powered properly"
  print "2. Different SPI device on this CS pin"
  print "3. Device requires specific initialization sequence"
  print "4. Hardware fault or wrong device variant"
