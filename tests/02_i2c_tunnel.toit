// 02: I2C tunnel initialization and testing

import spi
import gpio

main:
  print "=== 02: I2C TUNNEL ==="
  print "Testing I2C tunnel setup step by step..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created successfully"
    
    print "\n=== STEP 1: Basic SPI Test ==="
    // First, test if basic SPI is working at all
    basic-regs := [0x00, 0x01, 0x02, 0x07, 0x44, 0x0A]
    basic-regs.do: | reg |
      val := read-reg device reg
      print "  Register 0x$(%02x reg): 0x$(%02x val)"
    
    print "\n=== STEP 2: Reset Sensor ==="
    // Reset the sensor first
    print "  Resetting sensor..."
    write-reg device 0x07 0x40  // CAM_REG_SENSOR_RESET = CAM_SENSOR_RESET_ENABLE
    sleep --ms=500  // Give time for reset
    
    // Check sensor state after reset
    state-after-reset := read-reg device 0x44
    print "  Sensor state after reset: 0x$(%02x state-after-reset)"
    
    print "\n=== STEP 3: Set I2C Device Address ==="
    // Set the I2C device address (critical for tunnel)
    device-address := 0x78
    print "  Setting I2C device address to 0x$(%02x device-address)..."
    write-reg device 0x0A device-address  // CAM_REG_DEBUG_DEVICE_ADDRESS
    
    // Verify the address was set
    readback-address := read-reg device 0x0A
    print "  I2C device address readback: 0x$(%02x readback-address)"
    
    tunnel-working := false
    if readback-address == device-address:
      print "  ✅ I2C device address set successfully!"
      tunnel-working = true
    else:
      print "  ❌ I2C device address not set correctly"
    
    print "\n=== STEP 4: Wait for I2C Idle ==="
    // Now try to wait for I2C idle
    print "  Waiting for I2C to become idle..."
    
    idle-achieved := false
    for attempt := 0; attempt < 10; attempt++:
      state := read-reg device 0x44  // CAM_REG_SENSOR_STATE
      state-bits := state & 0x03
      
      print "  Attempt $attempt: state=0x$(%02x state), bits=0x$(%02x state-bits)"
      
      if state-bits == 0x02:  // CAM_REG_SENSOR_STATE_IDLE
        print "  ✅ I2C idle achieved!"
        idle-achieved = true
        break
      
      if state == 0x55:
        print "  ⚠️  Still getting 0x55 - I2C tunnel not working"
      else if state == 0x00:
        print "  ⚠️  Sensor state is 0x00 - may be normal during init"
      else:
        print "  ⚠️  Sensor state is 0x$(%02x state) - unexpected value"
      
      sleep --ms=100
    
    print "\n=== STEP 5: Test Register Writes ==="
    // Try writing to sensor registers through tunnel
    print "  Testing format register write through I2C tunnel..."
    
    format-before := read-reg device 0x20  // CAM_REG_FORMAT
    print "    Format before: 0x$(%02x format-before)"
    
    write-reg device 0x20 0x01  // JPEG format
    sleep --ms=100
    
    format-after := read-reg device 0x20
    print "    Format after: 0x$(%02x format-after)"
    
    if format-after == 0x01:
      print "    ✅ Format register write successful - I2C tunnel working!"
      tunnel-working = true
    else:
      print "    ❌ Format register write failed - I2C tunnel not working"
    
    // Summary
    print "\n=== I2C TUNNEL SUMMARY ==="
    if tunnel-working:
      print "  ✅ I2C tunnel is working - register-based capture should work"
      print "  ✅ Can proceed with C-style takePicture approach"
    else:
      print "  ❌ I2C tunnel is NOT working - this is the core issue"
      print "  ❌ Register writes don't reach sensor - need tunnel fix"
      print "  ⚠️  All subsequent capture tests will fail without I2C tunnel"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 02: I2C TUNNEL COMPLETE ==="

read-reg device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-reg device/spi.Device addr/int value/int -> none:
  command := #[addr | 0x80, value]
  device.write command
