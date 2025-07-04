// Test 4: Sensor Reset Sequence Test
// Goal: Test the sensor reset sequence (first step in C code initialization)
// Success: Sensor reset triggers expected state changes

import gpio
import spi

read-register device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-register device/spi.Device addr/int value/int -> none:
  command := #[addr | 0x80, value]
  device.write command

main:
  print "=== Test 4: Sensor Reset Sequence Test ==="
  print "Goal: Test sensor reset sequence (first C code initialization step)"
  
  try:
    // Initialize SPI
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    device := spi-bus.device --cs=cs --frequency=100_000 --mode=0
    
    print "✅ SPI device initialized"
    
    // Test 4a: Read state before reset
    print "\nTest 4a: Read register states before reset..."
    
    key-registers := [0x00, 0x07, 0x40, 0x41, 0x42, 0x43, 0x44, 0x49]
    before-values := {:}
    
    key-registers.do: | reg |
      value := read-register device reg
      before-values[reg] = value
      print "  Register 0x$(%02x reg): 0x$(%02x value)"
    
    // Test 4b: Execute sensor reset sequence
    print "\nTest 4b: Executing sensor reset sequence..."
    print "  C code: writeReg(camera, CAM_REG_SENSOR_RESET, CAM_SENSOR_RESET_ENABLE)"
    print "  Translation: write 0x40 to register 0x07"
    
    // CAM_REG_SENSOR_RESET = 0x07, CAM_SENSOR_RESET_ENABLE = 0x40
    print "  Writing 0x40 to register 0x07..."
    write-register device 0x07 0x40
    
    // Wait for reset to complete (C code does waitI2cIdle after this)
    print "  Waiting for reset to complete..."
    sleep --ms=100
    
    // Test 4c: Read state after reset
    print "\nTest 4c: Read register states after reset..."
    
    after-values := {:}
    changes := []
    
    key-registers.do: | reg |
      value := read-register device reg
      after-values[reg] = value
      before := before-values[reg]
      
      if value != before:
        changes.add "0x$(%02x reg): 0x$(%02x before) -> 0x$(%02x value)"
      
      print "  Register 0x$(%02x reg): 0x$(%02x value) (was 0x$(%02x before))"
    
    // Test 4d: Analyze reset effects
    print "\nTest 4d: Analyzing reset effects..."
    
    if changes.is-empty:
      print "  ⚠️  No register changes detected after reset"
      print "     Possible causes:"
      print "     - Reset command not reaching device"
      print "     - Device already in reset state"
      print "     - Hardware not responding to reset"
    else:
      print "  ✅ Register changes detected:"
      changes.do: print "    $it"
    
    // Test 4e: Check sensor ID after reset
    print "\nTest 4e: Check sensor ID after reset..."
    
    sensor-id := read-register device 0x40
    print "  Sensor ID after reset: 0x$(%02x sensor-id)"
    
    if sensor-id == 0x56:
      print "  ✅ SUCCESS: Got expected MEGA-5MP sensor ID after reset!"
      print "     This indicates reset sequence worked and device is responding"
    else if sensor-id == 0x00:
      print "  ⚠️  Still getting 0x00 after reset"
      print "     Device may need additional initialization steps"
    else:
      print "  ⚠️  Unexpected sensor ID: 0x$(%02x sensor-id)"
    
    // Test 4f: Check if reset affected write capability
    print "\nTest 4f: Test write capability after reset..."
    
    // Test if reset enabled register writes
    write-register device 0x0A 0x78  // Try the critical I2C address
    sleep --ms=10
    readback := read-register device 0x0A
    
    if readback == 0x78:
      print "  ✅ SUCCESS: Register writes work after reset!"
      print "     Reset may have been the missing initialization step"
    else:
      print "  ⚠️  Register writes still not persisting after reset"
      print "     Reset alone is not sufficient to enable writes"
    
    print "\nAnalysis:"
    print "  Reset is the first critical step in ArduCam initialization"
    print "  Expected: Reset should enable communication and make sensor ID readable"
    print "  If sensor ID becomes 0x56 after reset -> hardware is working correctly"
    print "  If no changes after reset -> hardware or protocol issue"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Sensor reset test failed: $exception"
    
  print "\n=== Test 4 Complete ==="
