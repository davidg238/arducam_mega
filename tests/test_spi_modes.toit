// Test Suite 2: SPI Modes
// Test all 4 SPI modes to see which one Arduino uses

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI MODE TEST SUITE ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Test all 4 SPI modes
  modes := [0, 1, 2, 3]
  
  // Test with a few different frequencies
  frequencies := [1_000_000, 4_000_000, 8_000_000]
  
  frequencies.do: | freq |
    print "\n\n=== Testing at $freq Hz ==="
    
    modes.do: | mode |
      print "\n--- Testing SPI Mode $mode at $freq Hz ---"
      print "  Mode $mode: CPOL=$(mode >> 1), CPHA=$(mode & 1)"
      
      try:
        // Create camera with this mode
        camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
        
        // Override the SPI device with new mode
        camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=mode
        
        print "  SPI device created: mode=$mode, freq=$freq Hz"
        
        // Test basic register communication
        success := test-communication camera mode freq
        
        if success:
          print "  ✅ SUCCESS with mode $mode at $freq Hz"
          test-sensor-registers camera mode freq
        else:
          print "  ❌ FAILED with mode $mode at $freq Hz"
          
      finally: | is-exception exception |
        if is-exception:
          print "  ❌ ERROR with mode $mode at $freq Hz: $exception"
  
  print "\n=== SPI MODE TEST COMPLETE ==="

test-communication camera mode freq -> bool:
  try:
    // Test multiple register operations
    print "    Testing register 0x00 (ARDUCHIP_TEST1)..."
    
    // Read initial value
    initial := camera.read-reg 0x00
    print "    Initial: 0x$(%02x initial)"
    
    // Write test pattern
    camera.write-reg 0x00 0xAA
    sleep --ms=2
    readback1 := camera.read-reg 0x00
    print "    Wrote 0xAA, read: 0x$(%02x readback1)"
    
    // Write different pattern
    camera.write-reg 0x00 0x55
    sleep --ms=2
    readback2 := camera.read-reg 0x00
    print "    Wrote 0x55, read: 0x$(%02x readback2)"
    
    // Test should work for at least one pattern
    if readback1 == 0xAA or readback2 == 0x55:
      print "    ✅ Register read/write working in mode $mode"
      return true
    else:
      print "    ❌ Register read/write failed in mode $mode"
      return false
      
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ Exception in mode $mode: $exception"
      return false

test-sensor-registers camera mode freq -> none:
  try:
    print "    Testing sensor registers (I2C tunnel)..."
    
    // These are the registers that were returning 0x00
    sensor-regs := [0x40, 0x41, 0x42, 0x43, 0x44, 0x49]
    reg-names := ["SENSOR_ID", "YEAR_ID", "MONTH_ID", "DAY_ID", "SENSOR_STATE", "VERSION"]
    
    working-regs := 0
    
    for i := 0; i < sensor-regs.size; i++:
      reg := sensor-regs[i]
      name := reg-names[i]
      
      value := camera.read-reg reg
      print "    0x$(%02x reg) ($name): 0x$(%02x value)"
      
      if value != 0x00:
        working-regs++
        
    if working-regs > 0:
      print "    ✅ $working-regs sensor registers responding in mode $mode!"
    else:
      print "    ❌ All sensor registers still return 0x00 in mode $mode"
      
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ Exception testing sensors in mode $mode: $exception"
