// Test both FPGA and I2C sensor register access mechanisms

import arducam_mega show *
import spi
import gpio

main:
  print "=== DUAL REGISTER ACCESS TEST ==="
  print "Testing FPGA registers vs I2C sensor registers"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nStep 1: Test FPGA registers (direct SPI)"
    test-fpga-registers camera
    
    print "\nStep 2: Initialize I2C tunnel"
    init-i2c-tunnel camera
    
    print "\nStep 3: Test I2C sensor registers (via tunnel)"
    test-i2c-sensor-registers camera
    
    print "\nStep 4: Test debug register mechanism"
    test-debug-register-access camera
    
    print "\nStep 5: Test JPEG format with proper mechanism"
    test-jpeg-format-proper camera
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during dual register test: $exception"
  
  print "\n=== DUAL REGISTER ACCESS TEST COMPLETE ==="

test-fpga-registers camera -> none:
  print "  Testing FPGA/CPLD registers (should work immediately)..."
  
  // These should be direct FPGA registers that don't need I2C tunnel
  fpga-registers := [
    [0x00, "Test register"],
    [0x01, "Frames captured"],
    [0x04, "FIFO control"],
    [0x07, "Reset register"],
    [0x0A, "Debug device address"],
  ]
  
  fpga-registers.do: | reg-info |
    addr := reg-info[0]
    name := reg-info[1]
    
    // Test read
    value := camera.read-reg addr
    print "    FPGA reg 0x$(%02x addr) ($name): 0x$(%02x value)"
    
    // Test write (for writeable registers)
    if addr == 0x00:  // Test register
      camera.write-reg addr 0x55
      sleep --ms=2
      readback := camera.read-reg addr
      if readback == 0x55:
        print "      ✅ FPGA register write/read works!"
      else:
        print "      ❌ FPGA register write failed (got 0x$(%02x readback))"

init-i2c-tunnel camera -> none:
  print "  Initializing I2C tunnel for sensor registers..."
  
  // Arduino sequence for I2C tunnel setup
  print "    Step 1: Reset sensor"
  camera.write-reg 0x07 0x40  // CAM_REG_SENSOR_RESET, CAM_SENSOR_RESET_ENABLE
  sleep --ms=10
  
  print "    Step 2: Set I2C device address"
  camera.write-reg 0x0A 0x78  // CAM_REG_DEBUG_DEVICE_ADDRESS, deviceAddress
  sleep --ms=10
  
  print "    Step 3: Test I2C tunnel readiness"
  // Try to wait for I2C idle
  tunnel-ready := false
  for attempt := 0; attempt < 10; attempt++:
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    state-bits := sensor-state & 0x03
    if state-bits == 0x02:  // CAM_REG_SENSOR_STATE_IDLE
      print "    ✅ I2C tunnel ready! (state=0x$(%02x sensor-state))"
      tunnel-ready = true
      break
    sleep --ms=5
  
  if not tunnel-ready:
    print "    ⚠️  I2C tunnel not immediately ready, continuing anyway..."

test-i2c-sensor-registers camera -> none:
  print "  Testing I2C sensor registers (need tunnel)..."
  
  // These should be sensor registers accessed via I2C tunnel
  i2c-registers := [
    [0x20, "Image format"],
    [0x21, "Capture resolution"],
    [0x22, "Brightness control"],
    [0x40, "Sensor ID"],
    [0x44, "Sensor state"],
  ]
  
  i2c-registers.do: | reg-info |
    addr := reg-info[0]
    name := reg-info[1]
    
    print "    I2C reg 0x$(%02x addr) ($name):"
    
    // Test read
    value-before := camera.read-reg addr
    print "      Before: 0x$(%02x value-before)"
    
    // Test write (for writeable registers)
    if addr == 0x20:  // Format register
      print "      Testing JPEG format write..."
      camera.write-reg addr 0x01  // JPEG format
      
      // Wait for I2C operation
      i2c-success := wait-for-i2c-idle camera 5
      
      if i2c-success:
        value-after := camera.read-reg addr
        print "      After: 0x$(%02x value-after)"
        
        if value-after == 0x01:
          print "      ✅ I2C sensor register write successful!"
        else:
          print "      ⚠️  I2C wait succeeded but value not set"
      else:
        print "      ❌ I2C tunnel timeout"
    
    sleep --ms=10

test-debug-register-access camera -> none:
  print "  Testing debug register mechanism (advanced I2C)..."
  
  // Test the debug register mechanism used for direct sensor access
  // This is used for advanced sensor configuration
  
  print "    Testing sensor register 0x3000 (example)..."
  
  sensor-reg := 0x3000
  test-value := 0x12
  
  // Arduino: writeReg(camera, CAM_REG_DEBUG_REGISTER_HIGH, register_high);
  camera.write-reg 0x0B (sensor-reg >> 8) & 0xFF  // High byte
  wait-for-i2c-idle camera 3
  
  // Arduino: writeReg(camera, CAM_REG_DEBUG_REGISTER_LOW, register_low);
  camera.write-reg 0x0C sensor-reg & 0xFF  // Low byte
  wait-for-i2c-idle camera 3
  
  // Arduino: writeReg(camera, CAM_REG_DEBUG_REGISTER_VALUE, value);
  camera.write-reg 0x0D test-value  // Value
  
  if wait-for-i2c-idle camera 10:
    print "    ✅ Debug register mechanism completed"
  else:
    print "    ❌ Debug register mechanism timed out"

test-jpeg-format-proper camera -> none:
  print "  Testing JPEG format with proper I2C mechanism..."
  
  // Follow exact Arduino takePicture sequence for JPEG
  print "    Setting pixel format to JPEG (Arduino sequence)..."
  
  // Arduino: writeReg(camera, CAM_REG_FORMAT, pixel_format);
  camera.write-reg 0x20 0x01  // CAM_REG_FORMAT, CAM_IMAGE_PIX_FMT_JPG
  
  // Arduino: waitI2cIdle(camera);
  if wait-for-i2c-idle camera 10:
    print "    ✅ JPEG format set, checking..."
    
    format-check := camera.read-reg 0x20
    print "    Format register: 0x$(%02x format-check)"
    
    if format-check == 0x01:
      print "    ✅ JPEG format confirmed! Now setting resolution..."
      
      // Arduino: writeReg(camera, CAM_REG_CAPTURE_RESOLUTION, CAM_SET_CAPTURE_MODE | mode);
      camera.write-reg 0x21 (0x00 | 0x01)  // CAM_SET_CAPTURE_MODE | CAM_IMAGE_MODE_QVGA
      
      // Arduino: waitI2cIdle(camera);
      if wait-for-i2c-idle camera 10:
        print "    ✅ Resolution set! Testing capture..."
        
        // Test capture
        camera.set-capture
        sleep --ms=3000  // Wait for capture
        
        image-size := camera.image-available
        print "    Captured image size: $image-size bytes"
        
        if image-size > 0:
          // Check JPEG header
          camera.set-fifo-burst
          header := camera.read-buffer 20
          
          print "    First 10 bytes:"
          for i := 0; i < 10; i++:
            print "      [$i]: 0x$(%02x header[i])"
          
          if header[0] == 0xFF and header[1] == 0xD8:
            print "    ✅ VALID JPEG! I2C tunnel working perfectly!"
          else:
            print "    ❌ Still no JPEG header"
        else:
          print "    ❌ No image captured"
      else:
        print "    ❌ Resolution setting I2C timeout"
    else:
      print "    ❌ JPEG format not set properly"
  else:
    print "    ❌ JPEG format I2C timeout"

wait-for-i2c-idle camera timeout-seconds/int -> bool:
  timeout := timeout-seconds * 25  // Convert to 2ms units
  while timeout > 0:
    sensor-state := camera.read-reg 0x44
    state-bits := sensor-state & 0x03
    if state-bits == 0x02:  // CAM_REG_SENSOR_STATE_IDLE
      return true
    sleep --ms=2
    timeout--
  return false
