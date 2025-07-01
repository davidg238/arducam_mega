// Test Suite 1: SPI Frequencies
// Arduino typically uses 1-8MHz, let's test a range

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI FREQUENCY TEST SUITE ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Test frequencies from very slow to fast
  frequencies := [
    100_000,    // 100kHz - very conservative
    250_000,    // 250kHz
    500_000,    // 500kHz  
    1_000_000,  // 1MHz - current setting
    2_000_000,  // 2MHz
    4_000_000,  // 4MHz - common Arduino default
    8_000_000,  // 8MHz - faster Arduino setting
    10_000_000, // 10MHz - aggressive
  ]
  
  frequencies.do: | freq |
    print "\n--- Testing frequency: $freq Hz ---"
    
    try:
      // Create camera with this frequency
      camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
      
      // Override the SPI device with new frequency
      camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=0
      
      print "SPI device created at $freq Hz"
      
      // Test basic register communication
      success := test-basic-communication camera freq
      
      if success:
        print "✅ SUCCESS at $freq Hz - testing camera initialization..."
        test-camera-init camera freq
      else:
        print "❌ FAILED at $freq Hz"
        
    finally: | is-exception exception |
      if is-exception:
        print "❌ ERROR at $freq Hz: $exception"
  
  print "\n=== FREQUENCY TEST COMPLETE ==="

test-basic-communication camera freq -> bool:
  // Test the basic register read/write that was failing
  try:
    // Test 1: Read test register
    initial := camera.read-reg 0x00
    print "  Initial test reg: 0x$(%02x initial)"
    
    // Test 2: Write and read back
    camera.write-reg 0x00 0x55
    sleep --ms=5  // Small delay
    readback := camera.read-reg 0x00
    print "  Wrote 0x55, read: 0x$(%02x readback)"
    
    if readback == 0x55:
      print "  ✅ Basic SPI communication WORKS at $freq Hz"
      return true
    else:
      print "  ❌ Basic SPI communication failed at $freq Hz"
      return false
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Exception during basic test at $freq Hz: $exception"
      return false

test-camera-init camera freq -> none:
  // Test the camera initialization that was hanging
  try:
    print "  Testing reset sequence..."
    
    // This is where it was hanging before
    camera.write-reg 0x07 0x40  // CAM_REG_SENSOR_RESET with CAM_SENSOR_RESET_ENABLE
    sleep --ms=10
    print "  Reset command sent successfully at $freq Hz"
    
    // Try reading sensor state
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    print "  Sensor state after reset: 0x$(%02x sensor-state)"
    
    // Try reading a sensor ID register
    sensor-id := camera.read-reg 0x40  // CAM_REG_SENSOR_ID
    print "  Sensor ID: 0x$(%02x sensor-id)"
    
    if sensor-id != 0x00:
      print "  ✅ Sensor responding at $freq Hz! ID: 0x$(%02x sensor-id)"
    else:
      print "  ❌ Sensor not responding at $freq Hz (ID still 0x00)"
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Exception during init test at $freq Hz: $exception"
