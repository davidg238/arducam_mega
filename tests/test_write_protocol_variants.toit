// Test different write protocol variants to find the correct one

import spi
import gpio

main:
  print "=== WRITE PROTOCOL VARIANTS TEST ==="
  print "Testing different SPI write protocols"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "SPI device created"
    
    print "\nStep 1: Test different write approaches"
    test-write-variants device
    
    print "\nStep 2: Test read after each write variant"
    test-read-after-writes device
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during write protocol test: $exception"
  
  print "\n=== WRITE PROTOCOL VARIANTS TEST COMPLETE ==="

test-write-variants device -> none:
  print "  Testing different write protocol variants..."
  
  test-addr := 0x00  // Test register
  test-value := 0x33
  
  // Variant 1: Current Toit approach (with 0x80)
  print "    Variant 1: Write with 0x80 bit (current Toit)"
  device.write #[test-addr | 0x80, test-value]
  sleep --ms=10
  result1 := read-reg-arduino device test-addr
  print "      Result: 0x$(%02x result1)"
  
  sleep --ms=50
  
  // Variant 2: Arduino busWrite approach (no 0x80)
  print "    Variant 2: Write without 0x80 bit (Arduino busWrite)"
  device.write #[test-addr, test-value]
  sleep --ms=10
  result2 := read-reg-arduino device test-addr
  print "      Result: 0x$(%02x result2)"
  
  sleep --ms=50
  
  // Variant 3: Three-byte write (like read protocol)
  print "    Variant 3: Three-byte write protocol"
  device.write #[test-addr | 0x80, test-value, 0x00]
  sleep --ms=10
  result3 := read-reg-arduino device test-addr
  print "      Result: 0x$(%02x result3)"
  
  sleep --ms=50
  
  // Variant 4: Separate address and data writes
  print "    Variant 4: Separate address and data writes"
  device.write #[test-addr | 0x80]
  sleep --ms=5
  device.write #[test-value]
  sleep --ms=10
  result4 := read-reg-arduino device test-addr
  print "      Result: 0x$(%02x result4)"
  
  // Check which variant worked
  results := [result1, result2, result3, result4]
  variant-names := ["0x80 bit", "No 0x80", "Three-byte", "Separate"]
  
  print "  Summary:"
  for i := 0; i < results.size; i++:
    result := results[i]
    name := variant-names[i]
    if result == test-value:
      print "    ✅ $name: SUCCESS (0x$(%02x result))"
    else if result != 0xFF:
      print "    ⚠️  $name: Changed to 0x$(%02x result) (not target 0x$(%02x test-value))"
    else:
      print "    ❌ $name: No effect (0x$(%02x result))"

test-read-after-writes device -> none:
  print "  Testing read consistency after writes..."
  
  // Test multiple registers to see patterns
  test-registers := [0x00, 0x01, 0x02, 0x04, 0x07, 0x0A]
  test-names := ["Test", "Frames", "Power", "FIFO", "Reset", "Device Addr"]
  
  for i := 0; i < test-registers.size; i++:
    reg := test-registers[i]
    name := test-names[i]
    
    print "    Register 0x$(%02x reg) ($name):"
    
    // Read before write
    before := read-reg-arduino device reg
    print "      Before write: 0x$(%02x before)"
    
    // Write test value with current best approach
    test-val := 0x55 + i  // Different value for each register
    device.write #[reg | 0x80, test-val]  // Using variant 1 for now
    sleep --ms=10
    
    // Read after write
    after := read-reg-arduino device reg
    print "      After write: 0x$(%02x after)"
    
    if after == test-val:
      print "      ✅ Write successful!"
    else if after != before:
      print "      ⚠️  Changed but not to target value"
    else:
      print "      ❌ No change"
    
    sleep --ms=20

// Use the Arduino read protocol we know works
read-reg-arduino device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]
