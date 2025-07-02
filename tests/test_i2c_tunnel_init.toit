// Debug I2C tunnel initialization - step by step Arduino replication

import arducam_mega show *
import spi
import gpio

main:
  print "=== I2C TUNNEL INITIALIZATION DEBUG ==="
  print "Replicating Arduino cameraBegin() I2C setup exactly"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nStep 1: Test basic SPI communication"
    test-basic-spi camera
    
    print "\nStep 2: Arduino cameraBegin() sequence"
    test-arduino-begin-sequence camera
    
    print "\nStep 3: Test I2C tunnel functionality"
    test-i2c-tunnel camera
    
    print "\nStep 4: Test register setting after I2C init"
    test-register-setting-post-init camera
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during I2C tunnel debug: $exception"
  
  print "\n=== I2C TUNNEL INITIALIZATION DEBUG COMPLETE ==="

test-basic-spi camera -> none:
  print "  Testing basic SPI communication (should work)..."
  
  // Test reading a few registers to confirm SPI works
  test-regs := [0x00, 0x01, 0x02, 0x40, 0x44]
  test-names := ["Test", "Frames", "Power", "Sensor ID", "Sensor State"]
  
  for i := 0; i < test-regs.size; i++:
    reg := test-regs[i]
    name := test-names[i]
    value := camera.read-reg reg
    print "    Reg 0x$(%02x reg) ($name): 0x$(%02x value)"
  
  print "  SPI communication test complete"

test-arduino-begin-sequence camera -> none:
  print "  Replicating Arduino cameraBegin() exactly..."
  
  // Arduino: writeReg(camera, CAM_REG_SENSOR_RESET, CAM_SENSOR_RESET_ENABLE);
  print "    Step 1: Reset CPLD and camera (Arduino line 1)"
  reset-value := 0x40  // CAM_SENSOR_RESET_ENABLE = (1 << 6)
  print "      Writing 0x$(%02x reset-value) to CAM_REG_SENSOR_RESET (0x07)"
  camera.write-reg 0x07 reset-value
  
  // Arduino: waitI2cIdle(camera); // Wait I2c Idle
  print "    Step 2: Wait I2C idle (Arduino line 2)"
  wait-result := test-wait-i2c-idle camera
  if wait-result:
    print "      ✅ I2C idle achieved!"
  else:
    print "      ❌ I2C idle timeout - this is the problem!"
  
  // Arduino: cameraGetSensorConfig(camera);
  print "    Step 3: Get sensor config (Arduino cameraGetSensorConfig)"
  test-sensor-config camera
  
  // Arduino: writeReg(camera, CAM_REG_DEBUG_DEVICE_ADDRESS, camera->myCameraInfo.deviceAddress);
  print "    Step 4: Set I2C device address (Arduino final step)"
  device-address := 0x78  // From Arduino CameraInfo_5MP.deviceAddress
  print "      Setting device address to 0x$(%02x device-address)"
  camera.write-reg 0x0A device-address  // CAM_REG_DEBUG_DEVICE_ADDRESS
  
  // Arduino: waitI2cIdle(camera);
  print "    Step 5: Final wait I2C idle"
  final-wait := test-wait-i2c-idle camera
  if final-wait:
    print "      ✅ I2C tunnel initialization complete!"
  else:
    print "      ❌ I2C tunnel still not working"

test-wait-i2c-idle camera -> bool:
  print "      Testing wait-I2C-idle (Arduino cameraWaitI2cIdle)..."
  
  // Arduino: while ((readReg(camera, CAM_REG_SENSOR_STATE) & 0X03) != CAM_REG_SENSOR_STATE_IDLE)
  // CAM_REG_SENSOR_STATE = 0x44
  // CAM_REG_SENSOR_STATE_IDLE = (1 << 1) = 0x02
  
  timeout := 25
  while timeout > 0:
    sensor-state := camera.read-reg 0x44
    state-bits := sensor-state & 0x03
    idle-target := 0x02  // CAM_REG_SENSOR_STATE_IDLE
    
    print "        Sensor state: 0x$(%02x sensor-state), bits: 0x$(%02x state-bits), target: 0x$(%02x idle-target)"
    
    if state-bits == idle-target:
      print "        ✅ I2C idle achieved!"
      return true
    
    sleep --ms=2
    timeout--
  
  print "        ❌ I2C idle timeout after 50ms"
  return false

test-sensor-config camera -> none:
  print "      Reading sensor configuration (Arduino cameraGetSensorConfig)..."
  
  // Arduino reads CAM_REG_SENSOR_ID to determine camera type
  sensor-id := camera.read-reg 0x40  // CAM_REG_SENSOR_ID
  print "        Sensor ID: 0x$(%02x sensor-id)"
  
  // Arduino expected values:
  // SENSOR_5MP = 0x81, SENSOR_5MP_1 = 0x82, SENSOR_5MP_2 = 0x83
  // SENSOR_3MP = 0x84, SENSOR_3MP_1 = 0x85, SENSOR_3MP_2 = 0x86
  // SENSOR_2MP = 0x87
  
  if sensor-id >= 0x81 and sensor-id <= 0x87:
    print "        ✅ Valid sensor ID detected!"
  else if sensor-id == 0xFF:
    print "        ❌ Sensor ID is 0xFF - I2C tunnel not working"
  else:
    print "        ⚠️  Unexpected sensor ID: 0x$(%02x sensor-id)"

test-i2c-tunnel camera -> none:
  print "  Testing I2C tunnel functionality..."
  
  // Test if we can communicate with the actual image sensor
  // The format register (0x20) should be settable if I2C tunnel works
  
  print "    Before I2C test - checking register states:"
  format-before := camera.read-reg 0x20
  power-before := camera.read-reg 0x02
  print "      Format reg (0x20): 0x$(%02x format-before)"
  print "      Power reg (0x02): 0x$(%02x power-before)"
  
  print "    Testing I2C tunnel with format register write..."
  
  // Try to set format to JPEG
  camera.write-reg 0x20 0x01
  
  // Wait for I2C (this should work if tunnel is initialized)
  wait-result := test-wait-i2c-idle camera
  
  if wait-result:
    format-after := camera.read-reg 0x20
    print "      Format after write: 0x$(%02x format-after)"
    
    if format-after == 0x01:
      print "      ✅ I2C tunnel working! Format register set successfully!"
    else:
      print "      ❌ I2C tunnel partial - wait succeeded but register not set"
  else:
    print "      ❌ I2C tunnel not working - wait-idle failed"

test-register-setting-post-init camera -> none:
  print "  Testing register setting after full I2C initialization..."
  
  // Test multiple registers that should be settable via I2C tunnel
  test-registers := [
    [0x20, 0x01, "Format (JPEG)"],
    [0x21, 0x01, "Resolution (QVGA)"],
    [0x22, 0x02, "Brightness"],
  ]
  
  test-registers.do: | test |
    reg-addr := test[0]
    test-value := test[1]
    reg-name := test[2]
    
    print "    Testing $reg-name register (0x$(%02x reg-addr))..."
    
    // Read before
    before := camera.read-reg reg-addr
    print "      Before: 0x$(%02x before)"
    
    // Write test value
    camera.write-reg reg-addr test-value
    
    // Wait I2C
    wait-ok := test-wait-i2c-idle camera
    
    if wait-ok:
      // Read after
      after := camera.read-reg reg-addr
      print "      After: 0x$(%02x after)"
      
      if after == test-value:
        print "      ✅ $reg-name register set successfully!"
      else:
        print "      ❌ $reg-name register not set (expected 0x$(%02x test-value), got 0x$(%02x after))"
    else:
      print "      ❌ $reg-name register test failed - I2C timeout"
    
    sleep --ms=10  // Small delay between tests
