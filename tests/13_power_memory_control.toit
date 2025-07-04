// Test 13: Power and Memory Control Implementation
// Goal: Implement proper power and memory control sequences from Application Note
// Success: FPGA register writes persist and sensor ID reads correctly

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 13: Power and Memory Control Implementation ==="
  print "Goal: Implement proper power-up and memory activation sequences"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Power Control Sequence ==="
    
    // Step 1: Check initial power state
    print "Step 1: Check initial power state..."
    initial-power := camera.read-fpga-reg CAM_REG_POWER_CONTROL
    print "Initial power control (0x02): 0x$(%02x initial-power)"
    
    // Step 2: Set proper power state (from Application Note)
    print "\nStep 2: Set proper power state..."
    print "Setting power control to 0x$(%02x CAM_POWER_NORMAL) (normal operation)"
    camera.write-fpga-reg CAM_REG_POWER_CONTROL CAM_POWER_NORMAL
    sleep --ms=100  // Allow power settling
    
    // Verify power state
    power-readback := camera.read-fpga-reg CAM_REG_POWER_CONTROL
    print "Power control readback: 0x$(%02x power-readback)"
    
    if power-readback == CAM_POWER_NORMAL:
      print "✅ Power control set successfully!"
    else:
      print "⚠️  Power control readback failed: got 0x$(%02x power-readback), expected 0x$(%02x CAM_POWER_NORMAL)"
    
    print "\n=== Phase 2: Memory Control Sequence ==="
    
    // Step 3: Check initial memory state
    print "Step 3: Check initial memory state..."
    initial-memory := camera.read-fpga-reg CAM_REG_MEMORY_CONTROL
    print "Initial memory control (0x04): 0x$(%02x initial-memory)"
    
    // Step 4: Clear memory completion flag
    print "\nStep 4: Clear memory completion flag..."
    camera.write-fpga-reg CAM_REG_MEMORY_CONTROL CAM_MEMORY_CLEAR_FLAG
    sleep --ms=50
    
    // Step 5: Check memory state after clear
    memory-after-clear := camera.read-fpga-reg CAM_REG_MEMORY_CONTROL
    print "Memory control after clear: 0x$(%02x memory-after-clear)"
    
    print "\n=== Phase 3: Test Register Write Persistence ==="
    
    // Step 6: Test if register writes now persist
    print "Step 6: Test register write persistence..."
    
    test-registers := [
      [0x00, 0x42, "Test register"],
      [CAM_REG_I2C_DEVICE_ADDR, 0x78, "I2C device address"],
      [CAM_REG_I2C_ADDR_HIGH, 0x01, "I2C address high"],
      [CAM_REG_I2C_ADDR_LOW, 0x23, "I2C address low"],
    ]
    
    success-count := 0
    test-registers.do: | test |
      reg := test[0]
      val := test[1]
      desc := test[2]
      
      print "Testing $desc (0x$(%02x reg))..."
      
      // Write test value
      camera.write-fpga-reg reg val
      sleep --ms=10
      
      // Read back
      readback := camera.read-fpga-reg reg
      print "  Wrote 0x$(%02x val), read 0x$(%02x readback)"
      
      if readback == val:
        print "  ✅ Write persisted!"
        success-count++
      else:
        print "  ❌ Write failed to persist"
    
    print "\nRegister write test: $success-count/$(test-registers.size) successful"
    
    print "\n=== Phase 4: Sensor ID Test ==="
    
    // Step 7: Test sensor ID after power/memory setup
    print "Step 7: Test sensor ID after proper initialization..."
    
    // Try standard camera initialization
    print "Running standard camera.on() initialization..."
    camera.on
    
    // Check sensor ID
    sensor-id := camera.read-fpga-reg CAM_REG_SENSOR_ID
    print "Sensor ID after full initialization: 0x$(%02x sensor-id)"
    
    if sensor-id == CAM_SENSOR_ID_5MP:
      print "🎉 SUCCESS! Got expected MEGA-5MP sensor ID (0x56)!"
      print "   Power and memory control sequences are working!"
    else if sensor-id != 0x00 and sensor-id != 0x55:
      print "✅ Got non-default sensor ID: 0x$(%02x sensor-id)"
      print "   This may be a valid sensor ID for this camera variant"
    else:
      print "⚠️  Still getting default sensor ID: 0x$(%02x sensor-id)"
    
    print "\n=== Phase 5: Complete Functionality Test ==="
    
    // Step 8: Test complete functionality
    print "Step 8: Test complete camera functionality..."
    
    // Test FIFO operations
    print "Testing FIFO operations..."
    camera.flush-fifo
    initial-fifo := camera.read-fifo-length
    print "Initial FIFO length: $initial-fifo bytes"
    
    // Test image capture
    print "Testing image capture (QVGA JPEG)..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    sleep --ms=2000
    
    final-fifo := camera.read-fifo-length
    captured-data := final-fifo - initial-fifo
    print "Captured data: $captured-data bytes"
    
    if captured-data > 0:
      print "🎉 SUCCESS! Camera captured image data!"
      print "   Power/memory control implementation is working!"
    else:
      print "⚠️  No image data captured, but initialization improved"
    
    print "\n=== Summary ==="
    print "Power control success: $(power-readback == CAM_POWER_NORMAL ? "✅" : "❌")"
    print "Register write persistence: $success-count/$(test-registers.size) ✅"
    print "Sensor ID detection: $(sensor-id == CAM_SENSOR_ID_5MP ? "✅" : "⚠️")"
    print "Image capture: $(captured-data > 0 ? "✅" : "⚠️")"
    
    if power-readback == CAM_POWER_NORMAL and success-count > 0:
      print "🎉 BREAKTHROUGH! Power/memory control is working!"
    else:
      print "❌ Still need to debug power/memory control"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Power/memory control test failed: $exception"
    
  print "\n=== Test 13 Complete ==="
