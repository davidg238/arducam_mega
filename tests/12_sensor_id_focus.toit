// Test 12: Focus on Getting Correct Sensor ID
// Goal: Try different approaches to get sensor ID = 0x56 (MEGA-5MP)
// Success: Sensor ID reads as 0x56 after proper initialization

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 12: Focus on Getting Correct Sensor ID ==="
  print "Goal: Get sensor ID to read 0x56 (MEGA-5MP expected value)"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\nSD card removed - testing without SPI bus interference"
    
    // Test 1: Raw sensor ID read (before any initialization)
    print "\nTest 1: Sensor ID before any initialization..."
    raw-sensor-id := camera.read-fpga-reg 0x40
    print "Raw sensor ID: 0x$(%02x raw-sensor-id)"
    
    // Test 2: After standard initialization
    print "\nTest 2: After camera.on() initialization..."
    camera.on
    print "✅ Camera initialization complete"
    
    after-init-sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID after init: 0x$(%02x after-init-sensor-id)"
    
    if after-init-sensor-id == 0x56:
      print "🎉 SUCCESS! Got expected MEGA-5MP sensor ID!"
      return
    
    // Test 3: Try additional reset sequences
    print "\nTest 3: Trying additional reset sequences..."
    
    reset-sequences := [
      [0x07, 0x40, "Standard sensor reset"],
      [0x07, 0x80, "Alternative reset value"],
      [0x07, 0xC0, "Combined reset flags"],
      [0x00, 0x55, "Test register activation"],
    ]
    
    reset-sequences.do: | seq |
      reg := seq[0]
      val := seq[1]
      desc := seq[2]
      
      print "  Trying $desc (0x$(%02x val) to 0x$(%02x reg))..."
      camera.write-fpga-reg reg val
      sleep --ms=200  // Longer wait
      
      sensor-id := camera.read-fpga-reg 0x40
      print "    Sensor ID: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    🎉 SUCCESS! $desc worked!"
        return
    
    // Test 4: Try different SPI configurations
    print "\nTest 4: Trying different SPI configurations..."
    
    configs := [
      [4_000_000, 0, "4MHz Mode 0 (Arduino standard)"],
      [8_000_000, 0, "8MHz Mode 0 (Arduino fast)"],
      [1_000_000, 1, "1MHz Mode 1"],
      [1_000_000, 2, "1MHz Mode 2"],
      [1_000_000, 3, "1MHz Mode 3"],
    ]
    
    configs.do: | config |
      freq := config[0]
      mode := config[1]
      desc := config[2]
      
      print "  Testing $desc..."
      
      // Create new device with different config
      test-device := spi-bus.device --cs=cs --frequency=freq --mode=mode
      
      // Read sensor ID with this config
      test-device.write #[0x40, 0x00, 0x00]
      response := test-device.read 3
      sensor-id := response[2]
      
      print "    Sensor ID with $desc: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    🎉 SUCCESS! $desc gives correct sensor ID!"
        return
    
    // Test 5: Multiple initialization attempts
    print "\nTest 5: Multiple initialization attempts..."
    
    5.repeat: | i |
      print "  Initialization attempt $(i + 1)..."
      
      // Reset and reinitialize
      camera.write-fpga-reg 0x07 0x40
      sleep --ms=100
      
      // Read sensor ID
      sensor-id := camera.read-fpga-reg 0x40
      print "    Attempt $(i + 1) sensor ID: 0x$(%02x sensor-id)"
      
      if sensor-id == 0x56:
        print "    🎉 SUCCESS on attempt $(i + 1)!"
        return
      
      if sensor-id != 0x00:
        print "    ⚠️  Got non-zero value: 0x$(%02x sensor-id) - may be progress"
    
    // Test 6: Check if sensor ID is in a different register
    print "\nTest 6: Check alternative sensor ID locations..."
    
    id-registers := [0x40, 0x41, 0x42, 0x43, 0x44, 0x49, 0x00, 0x01]
    id-registers.do: | reg |
      value := camera.read-fpga-reg reg
      print "  Register 0x$(%02x reg): 0x$(%02x value)"
      
      if value == 0x56:
        print "    🎉 Found sensor ID 0x56 in register 0x$(%02x reg)!"
        return
    
    // Test 7: Try reading with C code exact protocol
    print "\nTest 7: C code exact register read protocol..."
    
    // The C code does: readReg(camera, CAM_REG_SENSOR_ID)
    // which translates to busRead(camera, 0x40 & 0x7F)
    
    print "  Using exact C code busRead protocol..."
    camera.camera.write #[0x40 & 0x7F]  // First transfer: address only
    response1 := camera.camera.read 1
    
    camera.camera.write #[0x00]  // Second transfer: dummy
    response2 := camera.camera.read 1
    
    camera.camera.write #[0x00]  // Third transfer: dummy
    response3 := camera.camera.read 1
    
    c-style-sensor-id := response3[0]
    print "  C-style sensor ID: 0x$(%02x c-style-sensor-id)"
    
    if c-style-sensor-id == 0x56:
      print "  🎉 SUCCESS! C-style protocol gives correct sensor ID!"
      return
    
    print "\nAnalysis:"
    print "- Raw sensor ID: 0x$(%02x raw-sensor-id)"
    print "- After init sensor ID: 0x$(%02x after-init-sensor-id)"
    print "- C-style sensor ID: 0x$(%02x c-style-sensor-id)"
    
    if raw-sensor-id == after-init-sensor-id:
      print "- Initialization doesn't change sensor ID register"
      print "- May need different initialization approach"
    else:
      print "- Initialization does affect sensor ID register"
      print "- Progress being made"
    
    if after-init-sensor-id == 0x00:
      print "- All registers returning 0x00 suggests clean device state"
      print "- SD card removal was successful"
      print "- Camera may need additional activation sequence"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Sensor ID focus test failed: $exception"
    
  print "\n=== Test 12 Complete ==="
