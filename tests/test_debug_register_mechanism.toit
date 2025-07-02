// Test the debug register mechanism for sensor access

import spi
import gpio

main:
  print "=== DEBUG REGISTER MECHANISM TEST ==="
  print "Testing indirect sensor register access via debug registers"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "SPI device created"
    
    print "\nStep 1: Initialize I2C tunnel (quick version)"
    init-i2c-tunnel-quick device
    
    print "\nStep 2: Test debug register read mechanism"
    test-debug-register-read device
    
    print "\nStep 3: Test debug register write mechanism"
    test-debug-register-write device
    
    print "\nStep 4: Test sensor format setting via debug registers"
    test-format-via-debug device
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during debug register test: $exception"
  
  print "\n=== DEBUG REGISTER MECHANISM TEST COMPLETE ==="

init-i2c-tunnel-quick device -> none:
  print "  Quick I2C tunnel initialization..."
  
  // Reset sensor
  write-reg-fpga device 0x07 0x40
  sleep --ms=50
  write-reg-fpga device 0x07 0x00
  sleep --ms=50
  
  // Set device address
  write-reg-fpga device 0x0A 0x78
  sleep --ms=50
  
  // Check if ready
  sensor-state := read-reg-arduino device 0x44
  state-bits := sensor-state & 0x03
  print "    Sensor state: 0x$(%02x sensor-state), bits: 0x$(%02x state-bits)"
  
  if state-bits == 0x02:
    print "    ✅ I2C tunnel ready for debug register access"
  else:
    print "    ⚠️  I2C tunnel not ready, continuing anyway"

test-debug-register-read device -> none:
  print "  Testing debug register read mechanism..."
  
  // Arduino pattern for reading sensor register via debug mechanism:
  // 1. writeReg(camera, CAM_REG_DEBUG_REGISTER_HIGH, register_high)
  // 2. writeReg(camera, CAM_REG_DEBUG_REGISTER_LOW, register_low)  
  // 3. writeReg(camera, CAM_REG_SENSOR_RESET, CAM_I2C_READ_MODE)
  // 4. Read from SENSOR_DATA register
  
  // Try to read sensor ID register (0x0000) via debug mechanism
  sensor-reg-addr := 0x0000
  print "    Reading sensor register 0x$(%04x sensor-reg-addr) via debug mechanism..."
  
  // Step 1: Set register address high byte
  high-byte := (sensor-reg-addr >> 8) & 0xFF
  print "      Setting debug register high (0x0B) to 0x$(%02x high-byte)..."
  write-reg-fpga device 0x0B high-byte
  sleep --ms=10
  
  // Step 2: Set register address low byte  
  low-byte := sensor-reg-addr & 0xFF
  print "      Setting debug register low (0x0C) to 0x$(%02x low-byte)..."
  write-reg-fpga device 0x0C low-byte
  sleep --ms=10
  
  // Step 3: Trigger I2C read
  print "      Triggering I2C read (setting 0x07 to 0x01)..."
  write-reg-fpga device 0x07 0x01  // CAM_I2C_READ_MODE
  sleep --ms=50  // Wait for I2C operation
  
  // Step 4: Read result from sensor data register
  sensor-data := read-reg-arduino device 0x48  // SENSOR_DATA register
  print "      Sensor data result: 0x$(%02x sensor-data)"
  
  if sensor-data != 0xFF:
    print "      ✅ Debug register read might be working! Got: 0x$(%02x sensor-data)"
  else:
    print "      ❌ Debug register read returned 0xFF"
  
  // Try a few more sensor registers
  test-sensor-regs := [0x0001, 0x0002, 0x0003]
  test-sensor-regs.do: | test-addr |
    result := read-sensor-register-via-debug device test-addr
    print "      Sensor reg 0x$(%04x test-addr): 0x$(%02x result)"

test-debug-register-write device -> none:
  print "  Testing debug register write mechanism..."
  
  // Arduino pattern for writing sensor register via debug mechanism:
  // Similar to read but use CAM_REG_DEBUG_REGISTER_VALUE for the data
  
  test-sensor-addr := 0x0010  // Some test sensor register
  test-value := 0x42
  
  print "    Writing 0x$(%02x test-value) to sensor register 0x$(%04x test-sensor-addr)..."
  
  // Set address
  write-reg-fpga device 0x0B (test-sensor-addr >> 8) & 0xFF
  sleep --ms=10
  write-reg-fpga device 0x0C test-sensor-addr & 0xFF
  sleep --ms=10
  
  // Set value to write
  write-reg-fpga device 0x0D test-value  // CAM_REG_DEBUG_REGISTER_VALUE
  sleep --ms=50
  
  // Read back to see if it worked
  readback := read-sensor-register-via-debug device test-sensor-addr
  print "    Write test: wrote 0x$(%02x test-value), read back 0x$(%02x readback)"
  
  if readback == test-value:
    print "    ✅ Debug register write/read successful!"
  else if readback != 0xFF:
    print "    ⚠️  Debug register responding but value different"
  else:
    print "    ❌ Debug register write failed"

test-format-via-debug device -> none:
  print "  Testing format setting via debug register mechanism..."
  
  // Since direct register access (0x20) didn't work, try accessing
  // the format register via the debug mechanism
  
  // Need to find the actual sensor register address for format
  // This might be different from the FPGA register 0x20
  
  format-sensor-addrs := [0x3820, 0x5000, 0x4300]  // Common format register addresses
  
  format-sensor-addrs.do: | addr |
    print "    Testing format register at sensor address 0x$(%04x addr)..."
    
    // Read current value
    before := read-sensor-register-via-debug device addr
    print "      Before: 0x$(%02x before)"
    
    // Try to write JPEG format value
    write-sensor-register-via-debug device addr 0x01
    
    // Read back
    after := read-sensor-register-via-debug device addr
    print "      After: 0x$(%02x after)"
    
    if after == 0x01:
      print "      ✅ Found working format register at 0x$(%04x addr)!"
    else if after != before:
      print "      ⚠️  Register responded but value different"
    else if before != 0xFF:
      print "      ℹ️  Register exists but might be read-only"

// Read sensor register via debug mechanism
read-sensor-register-via-debug device addr/int -> int:
  write-reg-fpga device 0x0B (addr >> 8) & 0xFF
  sleep --ms=5
  write-reg-fpga device 0x0C addr & 0xFF
  sleep --ms=5
  write-reg-fpga device 0x07 0x01  // Trigger read
  sleep --ms=20
  return read-reg-arduino device 0x48  // Read result

// Write sensor register via debug mechanism
write-sensor-register-via-debug device addr/int value/int -> none:
  write-reg-fpga device 0x0B (addr >> 8) & 0xFF
  sleep --ms=5
  write-reg-fpga device 0x0C addr & 0xFF
  sleep --ms=5
  write-reg-fpga device 0x0D value
  sleep --ms=20

// Write to FPGA register
write-reg-fpga device addr/int value/int -> none:
  device.write #[addr | 0x80, value]

// Read register using Arduino protocol
read-reg-arduino device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]
