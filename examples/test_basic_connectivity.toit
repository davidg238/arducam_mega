// Basic connectivity test - are we connected to anything?

import arducam_mega show *
import spi
import gpio

main:
  print "=== BASIC CONNECTIVITY TEST ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\n1. Test if MISO pin is floating or connected"
    test-miso-state camera
    
    print "\n2. Test SPI loopback (if MOSI=MISO)"
    test-loopback camera
    
    print "\n3. Test different command patterns"
    test-command-patterns camera
    
    print "\n4. Compare with Arduino known working commands"
    test-arduino-commands camera
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== BASIC CONNECTIVITY TEST COMPLETE ==="

test-miso-state camera -> none:
  print "  Testing MISO pin behavior:"
  
  // Send different patterns and see if MISO responds
  patterns := [#[0x00], #[0xFF], #[0x55], #[0xAA]]
  
  patterns.do: | pattern |
    camera.camera.write pattern
    result := camera.camera.read 1
    
    print "    Send 0x$(%02x pattern[0]) → Get 0x$(%02x result[0])"
  
  print "    Analysis: If all responses are 0x66, MISO might be stuck high"
  print "    Analysis: If all responses are 0x00, MISO might be stuck low"
  print "    Analysis: If all responses are 0xFF, MISO might be floating high"

test-loopback camera -> none:
  print "  Testing SPI loopback (send=receive?):"
  
  // If MOSI is connected to MISO, we should get back what we send
  test-bytes := [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]
  
  loopback-detected := true
  
  test-bytes.do: | send-byte |
    camera.camera.write #[send-byte]
    result := camera.camera.read 1
    recv-byte := result[0]
    
    print "    Send 0x$(%02x send-byte) → Get 0x$(%02x recv-byte)"
    
    if send-byte != recv-byte:
      loopback-detected = false
  
  if loopback-detected:
    print "    ✅ Perfect loopback - MOSI connected to MISO!"
  else:
    print "    ❌ Not loopback - we're connected to a real device"

test-command-patterns camera -> none:
  print "  Testing ArduCam-like command patterns:"
  
  // Test patterns that might trigger different responses
  commands := [
    [#[0x00, 0x00, 0x00], "Arduino read reg 0x00"],
    [#[0x80, 0x55], "Arduino write 0x55 to reg 0x00"],
    [#[0x40, 0x00, 0x00], "Arduino read sensor ID"],
    [#[0x44, 0x00, 0x00], "Arduino read sensor state"]
  ]
  
  commands.do: | cmd-info |
    command := cmd-info[0]
    description := cmd-info[1]
    
    camera.camera.write command
    result := camera.camera.read command.size
    
    result-str := ""
    result.do: | byte |
      result-str += "0x$(%02x byte) "
    
    print "    $description → $result-str"

test-arduino-commands camera -> none:
  print "  Testing exact Arduino SPI sequences:"
  
  // From Arduino examples, these should work
  print "    Testing Arduino test register sequence..."
  
  // Arduino: write test register
  camera.camera.write #[0x80, 0x55]  // Write 0x55 to test reg
  sleep --ms=5
  
  // Arduino: read test register
  camera.camera.write #[0x00, 0x00, 0x00]  // Read test reg
  result := camera.camera.read 3
  
  print "    After Arduino write 0x55: [0x$(%02x result[0]), 0x$(%02x result[1]), 0x$(%02x result[2])]"
  
  if result[2] == 0x55:
    print "    ✅ Arduino sequence works! ArduCam responding correctly!"
  else if result[0] == 0x55 or result[1] == 0x55:
    print "    ⚠️  Arduino sequence partially works - data in wrong position"
  else:
    print "    ❌ Arduino sequence failed - not getting expected response"
