// Test proper FIFO handling like C code

import spi
import gpio

CAM_REG_FORMAT                    ::= 0x20
CAM_REG_CAPTURE_RESOLUTION        ::= 0x21
CAM_REG_SENSOR_STATE              ::= 0x44
CAM_REG_SENSOR_STATE_IDLE         ::= 0x02
CAM_IMAGE_PIX_FMT_JPG             ::= 0x01
CAM_IMAGE_MODE_QVGA               ::= 0x01
CAM_SET_CAPTURE_MODE              ::= 0x00
ARDUCHIP_FIFO                     ::= 0x04
ARDUCHIP_FIFO_2                   ::= 0x07
FIFO_CLEAR_ID_MASK                ::= 0x01
FIFO_CLEAR_MASK                   ::= 0x80
FIFO_START_MASK                   ::= 0x02
ARDUCHIP_TRIG                     ::= 0x44
CAP_DONE_MASK                     ::= 0x04
FIFO_SIZE1                        ::= 0x45
FIFO_SIZE2                        ::= 0x46
FIFO_SIZE3                        ::= 0x47

main:
  print "=== PROPER FIFO HANDLING TEST ==="
  print "Following C code FIFO protocol exactly..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created successfully"
    
    // Step 1: Set format using register write (like C code)
    print "\nStep 1: Setting JPEG format via register 0x20..."
    write-reg device CAM_REG_FORMAT CAM_IMAGE_PIX_FMT_JPG
    wait-idle device
    
    // Step 2: Set resolution
    print "\nStep 2: Setting QVGA resolution..."
    write-reg device CAM_REG_CAPTURE_RESOLUTION (CAM_SET_CAPTURE_MODE | CAM_IMAGE_MODE_QVGA)
    wait-idle device
    
    // Step 3: Proper FIFO handling (like C cameraSetCapture)
    print "\nStep 3: FIFO handling..."
    
    // 3a: Flush FIFO (like C cameraFlushFifo)
    print "  Flushing FIFO with ARDUCHIP_FIFO_2..."
    write-reg device ARDUCHIP_FIFO_2 FIFO_CLEAR_MASK  // 0x07, 0x80
    
    // 3b: Clear FIFO flag (like C cameraClearFifoFlag)
    print "  Clearing FIFO flag..."
    write-reg device ARDUCHIP_FIFO FIFO_CLEAR_ID_MASK  // 0x04, 0x01
    
    // 3c: Start capture (like C cameraStartCapture)
    print "  Starting capture..."
    write-reg device ARDUCHIP_FIFO FIFO_START_MASK  // 0x04, 0x02
    
    // Step 4: Wait for capture complete (like C cameraSetCapture)
    print "\nStep 4: Waiting for capture complete..."
    wait-count := 0
    while wait-count < 100:
      trig-reg := read-reg device ARDUCHIP_TRIG
      if (trig-reg & CAP_DONE_MASK) != 0:
        print "  ✅ Capture complete after $(wait-count * 100)ms"
        break
      sleep --ms=100
      wait-count++
    
    if wait-count >= 100:
      print "  ⚠️  Capture timeout - continuing anyway"
    
    // Step 5: Read FIFO size (like C cameraReadFifoLength)
    print "\nStep 5: Reading FIFO size..."
    fifo-size := read-fifo-size device
    print "  FIFO size: $fifo-size bytes"
    
    if fifo-size == 0:
      print "  ❌ No image data captured"
      return
    
    // Step 6: Read FIFO data - try burst read first
    print "\nStep 6: Reading FIFO data..."
    
    // Try burst FIFO read (0x3C) first
    print "  Trying burst FIFO read (0x3C)..."
    device.write #[0x3C]  // Burst FIFO read
    burst-header := device.read 20
    print "  Burst read first 10 bytes:"
    for i := 0; i < 10 and i < burst-header.size; i++:
      print "    [$i]: 0x$(%02x burst-header[i])"
    
    if burst-header.size >= 2 and burst-header[0] == 0xFF and burst-header[1] == 0xD8:
      print "  🎉 JPEG HEADER FOUND WITH BURST READ! 🎉"
      print "  ✅ ArduCam MEGA JPEG format is WORKING!"
      return
    
    // If burst didn't work, try single read
    print "  Trying single FIFO read (0x3D)..."
    device.write #[0x3D]  // Single FIFO read
    single-header := device.read 20
    print "  Single read first 10 bytes:"
    for i := 0; i < 10 and i < single-header.size; i++:
      print "    [$i]: 0x$(%02x single-header[i])"
    
    if single-header.size >= 2 and single-header[0] == 0xFF and single-header[1] == 0xD8:
      print "  🎉 JPEG HEADER FOUND WITH SINGLE READ! 🎉"
      print "  ✅ ArduCam MEGA JPEG format is WORKING!"
    else:
      print "  ❌ No JPEG header found in either read method"
      print "    Burst: 0x$(%02x burst-header[0]) 0x$(%02x burst-header[1])"
      print "    Single: 0x$(%02x single-header[0]) 0x$(%02x single-header[1])"
      
      // Analyze the pattern
      if burst-header[0] == 0x55 and single-header[0] == 0x55:
        print "  ⚠️  Still getting 0x55 pattern - FIFO may not be capturing"
        print "  ⚠️  This suggests the sensor may not be properly initialized"
      else:
        print "  ⚠️  Got different data - may be raw format"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== PROPER FIFO HANDLING TEST COMPLETE ==="

read-reg device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

write-reg device/spi.Device addr/int value/int -> none:
  command := #[addr | 0x80, value]  // Set bit 7 for write
  device.write command

wait-idle device/spi.Device -> none:
  // Wait for I2C to be idle
  timeout := 100
  while timeout > 0:
    state := read-reg device CAM_REG_SENSOR_STATE
    if (state & CAM_REG_SENSOR_STATE_IDLE) != 0:
      return
    sleep --ms=10
    timeout--
  print "  ⚠️  I2C idle timeout"

read-fifo-size device/spi.Device -> int:
  len1 := read-reg device FIFO_SIZE1
  len2 := read-reg device FIFO_SIZE2
  len3 := read-reg device FIFO_SIZE3
  return ((len3 << 16) | (len2 << 8) | len1) & 0xFFFFFF
