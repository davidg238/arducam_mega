// Test 30: I2C Sensor Configuration
// Goal: Test if we can configure the image sensor via I2C tunnel
// Success: Successfully read/write image sensor registers

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 30: I2C Sensor Configuration ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "STEP 2: Test I2C tunnel functionality..."
    
    // Verify I2C address is set
    i2c-addr := camera.read-fpga-reg 0x0A
    print "I2C device address: 0x$(%02x i2c-addr)"
    
    if i2c-addr != 0x78:
      print "Setting I2C address to 0x78..."
      camera.write-fpga-reg 0x0A 0x78
      i2c-addr = camera.read-fpga-reg 0x0A
      print "I2C address after set: 0x$(%02x i2c-addr)"
    
    print "STEP 3: Try to read image sensor registers via I2C tunnel..."
    
    // Try to read some sensor registers via I2C tunnel
    // Based on the reference, sensor registers are accessed differently
    
    sensor-test-regs := [
      0x0000,  // Common sensor ID register
      0x0001,  // Another ID register
      0x0002,  // Version register
      0x3000,  // Control register (common in sensors)
      0x3001,  // Another control register
    ]
    
    sensor-test-regs.do: | sensor-reg |
      print "Reading sensor register 0x$(%04x sensor-reg)..."
      
      try:
        // Set up I2C tunnel read
        // High byte of address
        camera.write-fpga-reg 0x0B (sensor-reg >> 8)
        // Low byte of address  
        camera.write-fpga-reg 0x0C (sensor-reg & 0xFF)
        // Trigger I2C read
        camera.write-fpga-reg 0x07 0x01  // I2C read mode
        sleep --ms=10
        
        // Read result from sensor data register
        sensor-value := camera.read-fpga-reg 0x48
        print "  Sensor 0x$(%04x sensor-reg): 0x$(%02x sensor-value)"
        
        if sensor-value != 0x00 and sensor-value != 0xFF:
          print "  ✅ Got valid sensor data!"
        else:
          print "  ⚠️  Default value"
          
      finally: | is-exception exception |
        if is-exception:
          print "  ❌ Error reading sensor register: $exception"
    
    print "STEP 4: Try sensor configuration for image capture..."
    
    // Based on typical sensor configs, try setting some basic registers
    sensor-configs := [
      [0x3000, 0x01, "Enable sensor"],
      [0x3001, 0x00, "Normal operation"],
      [0x0100, 0x01, "Start streaming (standard)"],
    ]
    
    sensor-configs.do: | config |
      reg := config[0]
      val := config[1]
      desc := config[2]
      
      print "Setting sensor $desc (0x$(%04x reg) = 0x$(%02x val))..."
      
      try:
        // Set up I2C tunnel write
        camera.write-fpga-reg 0x0B (reg >> 8)
        camera.write-fpga-reg 0x0C (reg & 0xFF)
        camera.write-fpga-reg 0x0D val  // Data to write
        // Trigger I2C write (different from read)
        camera.write-fpga-reg 0x07 0x02  // I2C write mode
        sleep --ms=50
        
        print "  ✅ Sensor config sent"
        
      finally: | is-exception exception |
        if is-exception:
          print "  ❌ Error configuring sensor: $exception"
    
    print "STEP 5: Test capture after sensor configuration..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    
    before := camera.read-fifo-length
    
    # Send capture commands
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    sleep --ms=3000
    
    after := camera.read-fifo-length
    captured := after - before
    
    print "Capture after sensor config: $captured bytes"
    
    if captured > 0:
      print "🎉 SUCCESS! Sensor configuration enabled capture!"
    else:
      print "❌ Still no capture data"
    
    print "\n=== I2C Tunnel Results ==="
    print "I2C address setup: $(i2c-addr == 0x78 ? "✅" : "❌")"
    print "Sensor register access: Need to check individual results above"
    print "Image capture after config: $(captured > 0 ? "✅" : "❌")"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 30 Complete ==="
