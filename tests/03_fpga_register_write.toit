// Test 3: FPGA Register Write Test
// Goal: Test if FPGA register writes persist (the critical blocker)
// Success: Written values can be read back correctly

import gpio
import spi

read-register device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-register device/spi.Device addr/int value/int -> none:
  // ArduCam write protocol: address with bit 7 set + value
  command := #[addr | 0x80, value]
  device.write command

main:
  print "=== Test 3: FPGA Register Write Test ==="
  print "Goal: Test if FPGA register writes persist (critical blocker)"
  
  try:
    // Initialize SPI
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=100_000 --mode=0
    
    print "✅ SPI device initialized"
    
    // Test 3a: Write/read cycle on safe registers
    print "\nTest 3a: Testing write persistence on safe registers..."
    
    safe-registers := [0x00, 0x01]  // Start with registers that should be safe to modify
    test-values := [0x55, 0xAA, 0x12, 0x34, 0x00]
    
    safe-registers.do: | reg |
      print "\n  Testing register 0x$(%02x reg):"
      
      // Read original value
      original := read-register device reg
      print "    Original value: 0x$(%02x original)"
      
      test-values.do: | test-val |
        // Write test value
        write-register device reg test-val
        sleep --ms=10  // Allow write to complete
        
        // Read back
        readback := read-register device reg
        
        success := (readback == test-val)
        status := success ? "✅" : "❌"
        print "    Write 0x$(%02x test-val) -> Read 0x$(%02x readback) $status"
        
        if not success:
          print "      ⚠️  Write did not persist! This is the core issue."
      
      // Restore original value
      write-register device reg original
    
    // Test 3b: Critical I2C address register (the specific failing case)
    print "\nTest 3b: Testing critical I2C address register (0x0A)..."
    print "  This is the specific register mentioned in session summary"
    
    original-addr := read-register device 0x0A
    print "  Original I2C address register: 0x$(%02x original-addr)"
    
    // Try to write 0x78 (expected I2C device address)
    print "  Writing 0x78 to register 0x0A..."
    write-register device 0x0A 0x78
    sleep --ms=50  // Extra time for this critical register
    
    readback := read-register device 0x0A
    print "  Readback: 0x$(%02x readback)"
    
    if readback == 0x78:
      print "  ✅ SUCCESS: I2C address register write persisted!"
      print "     This means FPGA register writes are working!"
    else:
      print "  ❌ FAILED: I2C address register write did not persist"
      print "     Expected: 0x78, Got: 0x$(%02x readback)"
      print "     This confirms the core issue: FPGA register writes don't stick"
    
    // Test 3c: Register write timing experiments
    print "\nTest 3c: Timing experiments..."
    
    timing-delays := [1, 10, 50, 100, 200]
    timing-delays.do: | delay |
      write-register device 0x0A 0x78
      sleep --ms=delay
      timing-readback := read-register device 0x0A
      success := (timing-readback == 0x78)
      status := success ? "✅" : "❌"
      print "  Delay $delay ms: 0x$(%02x timing-readback) $status"
    
    // Restore original value
    write-register device 0x0A original-addr
    
    print "\nAnalysis:"
    print "  If no writes persist -> FPGA not accepting writes (hardware/protocol issue)"
    print "  If some writes persist -> Timing or register-specific issue"
    print "  If all writes persist -> Issue was in library code (now fixed)"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Register write test failed: $exception"
    
  print "\n=== Test 3 Complete ==="
