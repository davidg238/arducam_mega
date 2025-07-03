// Test corrected format protocol - follow C code exactly

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
FIFO_CLEAR_MASK                   ::= 0x01
FIFO_START_MASK                   ::= 0x02
ARDUCHIP_TRIG                     ::= 0x44
CAP_DONE_MASK                     ::= 0x04
FIFO_SIZE1                        ::= 0x45
FIFO_SIZE2                        ::= 0x46
FIFO_SIZE3                        ::= 0x47

main:
  print "=== CORRECTED FORMAT TEST ==="
  print "Following C code protocol exactly..."
  
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
    
    // Verify format was set
    format-check := read-reg device CAM_REG_FORMAT
    print "  Format register now: 0x$(%02x format-check)"
    if format-check == CAM_IMAGE_PIX_FMT_JPG:
      print "  ✅ JPEG format set successfully!"
    else:
      print "  ⚠️  Format not set correctly (expected 0x01, got 0x$(%02x format-check))"
    
    // Step 2: Set resolution
    print "\nStep 2: Setting QVGA resolution..."
    write-reg device CAM_REG_CAPTURE_RESOLUTION (CAM_SET_CAPTURE_MODE | CAM_IMAGE_MODE_QVGA)
    wait-idle device
    
    // Step 3: Clear FIFO
    print "\nStep 3: Clearing FIFO..."
    write-reg device ARDUCHIP_FIFO FIFO_CLEAR_MASK
    
    // Step 4: Start capture
    print "\nStep 4: Starting capture..."
    write-reg device ARDUCHIP_FIFO FIFO_START_MASK
    
    // Step 5: Wait for capture complete
    print "\nStep 5: Waiting for capture complete..."
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
    
    // Step 6: Read FIFO size
    print "\nStep 6: Reading FIFO size..."
    fifo-size := read-fifo-size device
    print "  FIFO size: $fifo-size bytes"
    
    if fifo-size == 0:
      print "  ❌ No image data captured"
      return
    
    // Step 7: Read FIFO data
    print "\nStep 7: Reading FIFO header..."
    device.write #[0x3D]  // Single FIFO read
    header := device.read 20
    print "  First 10 bytes:"
    for i := 0; i < 10 and i < header.size; i++:
      print "    [$i]: 0x$(%02x header[i])"
    
    // Check for JPEG header
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "  🎉 JPEG HEADER FOUND! 🎉"
      print "  ✅ ArduCam MEGA JPEG format is WORKING!"
    else:
      print "  ❌ No JPEG header found"
      print "    Expected: 0xFF 0xD8"
      print "    Got: 0x$(%02x header[0]) 0x$(%02x header[1])"
      
      // Check if it's still all 0x55 (uninitialized)
      if header[0] == 0x55 and header[1] == 0x55:
        print "  ⚠️  Still getting 0x55 pattern - FIFO may not be initialized"
      else:
        print "  ⚠️  Got different data - may be raw format or different encoding"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== CORRECTED FORMAT TEST COMPLETE ==="

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
