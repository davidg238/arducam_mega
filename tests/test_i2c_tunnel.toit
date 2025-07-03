// Test I2C tunnel initialization step by step

import spi
import gpio

CAM_REG_SENSOR_RESET              ::= 0x07
CAM_REG_SENSOR_STATE              ::= 0x44
CAM_REG_DEBUG_DEVICE_ADDRESS      ::= 0x0A
CAM_REG_SENSOR_STATE_IDLE         ::= 0x02
CAM_SENSOR_RESET_ENABLE           ::= 0x40

main:
  print "=== I2C TUNNEL INITIALIZATION TEST ==="
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
    write-reg device CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE
    sleep --ms=500  // Give time for reset
    
    // Check sensor state after reset
    state-after-reset := read-reg device CAM_REG_SENSOR_STATE
    print "  Sensor state after reset: 0x$(%02x state-after-reset)"
    
    print "\n=== STEP 3: Set I2C Device Address ==="
    // Set the I2C device address
    device-address := 0x78
    print "  Setting I2C device address to 0x$(%02x device-address)..."
    write-reg device CAM_REG_DEBUG_DEVICE_ADDRESS device-address
    
    // Verify the address was set
    readback-address := read-reg device CAM_REG_DEBUG_DEVICE_ADDRESS
    print "  I2C device address readback: 0x$(%02x readback-address)"
    
    if readback-address == device-address:
      print "  ✅ I2C device address set successfully!"
    else:
      print "  ❌ I2C device address not set correctly"
    
    print "\n=== STEP 4: Wait for I2C Idle ==="
    // Now try to wait for I2C idle
    print "  Waiting for I2C to become idle..."
    
    for attempt := 0; attempt < 20; attempt++:
      state := read-reg device CAM_REG_SENSOR_STATE
      state-bits := state & 0x03
      
      print "  Attempt $attempt: state=0x$(%02x state), bits=0x$(%02x state-bits)"
      
      if state-bits == CAM_REG_SENSOR_STATE_IDLE:
        print "  ✅ I2C idle achieved!"
        break
      
      if state == 0x55:
        print "  ⚠️  Still getting 0x55 - possible SPI issue"
      else if state == 0x00:
        print "  ⚠️  Sensor state is 0x00 - may be normal during init"
      else:
        print "  ⚠️  Sensor state is 0x$(%02x state) - unexpected value"
      
      sleep --ms=100
    
    print "\n=== STEP 5: Alternative I2C Test ==="
    // Try different approaches to establish I2C communication
    
    // Try writing to different I2C debug registers
    print "  Testing I2C debug registers..."
    debug-regs := [0x0A, 0x0B, 0x0C, 0x0D, 0x0E]
    debug-regs.do: | reg |
      before := read-reg device reg
      write-reg device reg 0x12  // Test value
      after := read-reg device reg
      print "    Debug reg 0x$(%02x reg): 0x$(%02x before) -> 0x$(%02x after)"
    
    // Try a full sensor reset cycle
    print "\n  Trying full reset cycle..."
    write-reg device CAM_REG_SENSOR_RESET 0x00  // Clear reset
    sleep --ms=100
    state1 := read-reg device CAM_REG_SENSOR_STATE
    
    write-reg device CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE  // Set reset
    sleep --ms=100
    state2 := read-reg device CAM_REG_SENSOR_STATE
    
    write-reg device CAM_REG_SENSOR_RESET 0x00  // Clear reset again
    sleep --ms=500
    state3 := read-reg device CAM_REG_SENSOR_STATE
    
    print "    States: clear=0x$(%02x state1), reset=0x$(%02x state2), final=0x$(%02x state3)"
    
    if state1 != state2 or state2 != state3:
      print "  ✅ Reset cycle shows sensor responding!"
    else:
      print "  ❌ Reset cycle shows no response"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== I2C TUNNEL TEST COMPLETE ==="

read-reg device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-reg device/spi.Device addr/int value/int -> none:
  command := #[addr | 0x80, value]
  device.write command
