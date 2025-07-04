// Test I2C tunnel reads for sensor registers
// This should be the correct way to read sensor ID, version info, etc.

import arducam_mega show *
import spi
import gpio

main:
  print "=== I2C TUNNEL SENSOR READS ==="
  print "Testing proper I2C tunnel reads for sensor registers..."
  
  try:
    // STEP 1: Initialize camera
    print "\nStep 1: Initializing camera..."
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on  // Initialize camera
    print "✅ Camera initialized"
    
    // STEP 2: Test FPGA register reads (direct SPI)
    print "\nStep 2: Testing FPGA register reads (direct SPI)..."
    fpga-regs := [
      [0x00, "Test register"],
      [0x04, "FIFO control"],
      [0x07, "FIFO control 2"]
    ]
    
    fpga-regs.do: | reg-info |
      addr := reg-info[0]
      name := reg-info[1]
      val := camera.read-reg addr  // Direct SPI read
      print "  FPGA 0x$(%02x addr) ($name): 0x$(%02x val)"
    
    // STEP 3: Test sensor register reads (via I2C tunnel)
    print "\nStep 3: Testing sensor register reads (via I2C tunnel)..."
    sensor-regs := [
      [0x40, "Sensor ID"],
      [0x41, "Year ID"],
      [0x42, "Month ID"],
      [0x43, "Day ID"],
      [0x44, "Sensor state"]
    ]
    
    sensor-regs.do: | reg-info |
      addr := reg-info[0]
      name := reg-info[1]
      val := camera.read-sensor-reg addr  // I2C tunnel read
      print "  SENSOR 0x$(%02x addr) ($name): 0x$(%02x val)"
    
    // STEP 4: Compare results
    print "\nStep 4: Analysis..."
    
    // Try reading sensor ID via I2C tunnel
    sensor-id := camera.read-sensor-reg 0x40
    if sensor-id == 0x56:  // Expected MEGA-5MP ID
      print "🎉 MEGA-5MP SENSOR DETECTED via I2C tunnel!"
    else if sensor-id != 0x00 and sensor-id != 0x55:
      print "✅ Real sensor ID via I2C: 0x$(%02x sensor-id)"
    else:
      print "⚠️  Sensor ID via I2C still problematic: 0x$(%02x sensor-id)"
    
    // Try reading version info via I2C tunnel
    year := camera.read-sensor-reg 0x41
    month := camera.read-sensor-reg 0x42
    day := camera.read-sensor-reg 0x43
    
    print "  Version via I2C tunnel: $year/$month/$day"
    
    if year > 0 and month > 0 and day > 0:
      print "✅ SUCCESS: Real version info via I2C tunnel!"
    else:
      print "⚠️  Version info still not available via I2C"
    
    print "\n=== I2C TUNNEL SENSOR READS COMPLETE ==="
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
