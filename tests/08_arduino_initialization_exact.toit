// Test 8: Arduino Initialization Exact Sequence
// Goal: Replicate exact Arduino Capture.ino initialization sequence
// Success: Device responds with correct sensor ID after initialization

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 8: Arduino Initialization Exact Sequence ==="
  print "Goal: Replicate Arduino Capture.ino: myCAM.begin() + takePicture()"
  
  try:
    // Arduino: const int CS = 17; (but we use 22)
    // Arduino: Arducam_Mega myCAM( CS );
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\nStep 1: Arduino myCAM.begin() equivalent..."
    // This calls the C library cameraBegin() function
    camera.on
    print "✅ camera.on() completed"
    
    // Check sensor ID after begin()
    sensor-id := camera.read-fpga-reg 0x40
    print "Sensor ID after begin(): 0x$(%02x sensor-id)"
    
    print "\nStep 2: Arduino myCAM.takePicture() equivalent..."
    print "Arduino: myCAM.takePicture(CAM_IMAGE_MODE_WQXGA2, CAM_IMAGE_PIX_FMT_JPG)"
    print "Translation: camera.take-picture(0x09, CAM_IMAGE_PIX_FMT_JPG)"
    
    // Arduino uses WQXGA2 (0x09) and JPG format
    // Try takePicture - may fail but initialization might still work
    take-picture-worked := false
    try:
      camera.take-picture CAM_IMAGE_MODE_WQXGA2 CAM_IMAGE_PIX_FMT_JPG
      print "✅ takePicture() completed without exception"
      take-picture-worked = true
    finally: | is-exception exception |
      if is-exception:
        print "⚠️  takePicture() failed: $exception"
        print "   Continuing to check if initialization had any effect..."
    
    // Check sensor ID after takePicture
    sensor-id = camera.read-fpga-reg 0x40
    print "Sensor ID after takePicture(): 0x$(%02x sensor-id)"
    
    if sensor-id == 0x56:
      print "🎉 SUCCESS! Arduino initialization sequence worked!"
      print "   Sensor ID is now correct: 0x56 (MEGA-5MP)"
      
      // Test if register writes now work
      print "\nTesting if register writes now work..."
      camera.write-fpga-reg 0x0A 0x78
      sleep --ms=10
      readback := camera.read-fpga-reg 0x0A
      
      if readback == 0x78:
        print "✅ Register writes now working!"
      else:
        print "⚠️  Register writes still not working: 0x$(%02x readback)"
      
      return
    
    print "\nStep 3: Try alternative high-level commands..."
    print "Maybe the device needs high-level commands instead of register access"
    
    // Try ArduCam high-level command protocol
    print "Sending format command: 0x55 0x01 0x19 0xAA (JPEG + WQXGA2)"
    format-command := #[0x55, 0x01, 0x19, 0xAA]  // Format=JPEG(1), Resolution=WQXGA2(9)
    camera.camera.write format-command
    sleep --ms=100
    
    print "Sending capture command: 0x55 0x10 0x00 0xAA"
    capture-command := #[0x55, 0x10, 0x00, 0xAA]
    camera.camera.write capture-command
    sleep --ms=500
    
    // Check sensor ID after high-level commands
    sensor-id = camera.read-fpga-reg 0x40
    print "Sensor ID after high-level commands: 0x$(%02x sensor-id)"
    
    if sensor-id == 0x56:
      print "🎉 SUCCESS! High-level commands worked!"
      return
    
    print "\nStep 4: Check all registers after initialization attempts..."
    important-regs := [0x00, 0x01, 0x07, 0x0A, 0x40, 0x41, 0x42, 0x43, 0x44, 0x49]
    
    important-regs.do: | reg |
      value := camera.read-fpga-reg reg
      print "  Register 0x$(%02x reg): 0x$(%02x value)"
    
    print "\nAnalysis:"
    if sensor-id == 0x42:
      print "- Still getting 0x42 for all registers"
      print "- Device is stuck in the same state"
      print "- May need hardware reset or different initialization"
    else:
      print "- Register values changed!"
      print "- Initialization had some effect"
      print "- May need additional steps to reach working state"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Arduino initialization test failed: $exception"
    
  print "\n=== Test 8 Complete ==="
