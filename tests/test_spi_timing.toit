// Test Suite 3: SPI Timing and Delays
// Arduino SPI library might have built-in delays we're missing

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI TIMING TEST SUITE ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Test different timing approaches
  print "\n--- Test 1: No delays (current approach) ---"
  test-timing-approach "No delays" bus: | camera |
    test-basic-sequence camera
  
  print "\n--- Test 2: Short delays between operations ---"
  test-timing-approach "Short delays" bus: | camera |
    test-basic-sequence-with-delays camera 1
    
  print "\n--- Test 3: Medium delays between operations ---"
  test-timing-approach "Medium delays" bus: | camera |
    test-basic-sequence-with-delays camera 5
    
  print "\n--- Test 4: Long delays between operations ---"
  test-timing-approach "Long delays" bus: | camera |
    test-basic-sequence-with-delays camera 10
    
  print "\n--- Test 5: CS timing - hold CS low longer ---"
  test-timing-approach "CS hold timing" bus: | camera |
    test-cs-timing camera
    
  print "\n--- Test 6: Register-specific delays ---"
  test-timing-approach "Register delays" bus: | camera |
    test-register-specific-delays camera
  
  print "\n=== TIMING TEST COMPLETE ==="

test-timing-approach name bus block -> none:
  try:
    print "Testing: $name"
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    // Use 4MHz like Arduino typically does
    camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=0
    
    block.call camera
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ ERROR with $name: $exception"

test-basic-sequence camera -> none:
  // Current approach - no delays
  initial := camera.read-reg 0x00
  camera.write-reg 0x00 0x55
  readback := camera.read-reg 0x00
  
  print "  Initial: 0x$(%02x initial), Wrote 0x55, Read: 0x$(%02x readback)"
  if readback == 0x55:
    print "  ✅ Basic sequence works"
  else:
    print "  ❌ Basic sequence failed"

test-basic-sequence-with-delays camera delay-ms -> none:
  // Add delays between each operation
  initial := camera.read-reg 0x00
  sleep --ms=delay-ms
  
  camera.write-reg 0x00 0x55
  sleep --ms=delay-ms
  
  readback := camera.read-reg 0x00
  sleep --ms=delay-ms
  
  print "  Delay: ${delay-ms}ms, Initial: 0x$(%02x initial), Wrote 0x55, Read: 0x$(%02x readback)"
  if readback == 0x55:
    print "  ✅ Sequence works with ${delay-ms}ms delays"
    
    // If basic works, try sensor registers
    print "  Testing sensor registers with ${delay-ms}ms delays..."
    sensor-id := camera.read-reg 0x40
    sleep --ms=delay-ms
    sensor-state := camera.read-reg 0x44
    sleep --ms=delay-ms
    
    print "  Sensor ID: 0x$(%02x sensor-id), State: 0x$(%02x sensor-state)"
    
  else:
    print "  ❌ Sequence failed even with ${delay-ms}ms delays"

test-cs-timing camera -> none:
  // Test holding CS low for longer periods (like Arduino might do)
  try:
    print "  Testing extended CS timing..."
    
    // Manually control CS for extended timing
    cs-pin := gpio.Pin 22
    
    // Test 1: Short CS hold
    cs-pin.set 0  // CS low
    sleep --ms=1
    camera.camera.write #[0x00]  // Read register 0x00
    value1 := camera.camera.read 1
    cs-pin.set 1  // CS high
    sleep --ms=2
    
    print "  Short CS hold: 0x$(%02x value1[0])"
    
    // Test 2: Longer CS hold
    cs-pin.set 0  // CS low
    sleep --ms=5
    camera.camera.write #[0x00]
    value2 := camera.camera.read 1
    sleep --ms=2
    cs-pin.set 1  // CS high
    sleep --ms=5
    
    print "  Long CS hold: 0x$(%02x value2[0])"
    
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ CS timing test failed: $exception"

test-register-specific-delays camera -> none:
  // Test if specific register types need different delays
  print "  Testing register-specific timing..."
  
  // Control registers (should be fast)
  control-regs := [0x00, 0x01, 0x02, 0x04, 0x07]
  control-names := ["TEST1", "FRAMES", "POWER", "FIFO", "RESET"]
  
  print "  Control registers (no delay):" 
  for i := 0; i < control-regs.size; i++:
    reg := control-regs[i]
    name := control-names[i]
    value := camera.read-reg reg
    print "    0x$(%02x reg) ($name): 0x$(%02x value)"
  
  // Sensor registers (might need delays for I2C tunnel)
  sensor-regs := [0x40, 0x41, 0x42, 0x44]
  sensor-names := ["SENSOR_ID", "YEAR", "MONTH", "STATE"]
  
  print "  Sensor registers (with 10ms delays):"
  for i := 0; i < sensor-regs.size; i++:
    reg := sensor-regs[i]
    name := sensor-names[i]
    sleep --ms=10  // Delay before sensor register access
    value := camera.read-reg reg
    sleep --ms=10  // Delay after sensor register access
    print "    0x$(%02x reg) ($name): 0x$(%02x value)"
    
    if value != 0x00:
      print "    ✅ Sensor register $name responding!"
