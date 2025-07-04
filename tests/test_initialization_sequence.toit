// Test proper ArduCam initialization sequence
// This implements the exact C code cameraBegin() sequence

import arducam_mega show *
import spi
import gpio

// Constants needed for test
CAM_IMAGE_PIX_FMT_JPG ::= 1
CAM_IMAGE_MODE_QVGA ::= 0x01

main:
  print "=== ARDUCAM INITIALIZATION SEQUENCE TEST ==="
  print "Testing C code cameraBegin() implementation..."
  
  try:
    // Create camera instance
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    
    print "\nStep 1: Test state before initialization"
    test-register-state camera "before initialization"
    
    print "\nStep 2: Execute proper initialization"
    camera.on  // This should now follow C code sequence
    
    print "\nStep 3: Test state after initialization"
    test-register-state camera "after initialization"
    
    print "\nStep 4: Test ArduCam command protocol"
    test-arducam-commands camera
    
    print "\nStep 5: Test image capture readiness"
    test-capture-readiness camera
    
    print "\n✅ Initialization sequence test complete!"
    
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception during test: $exception"
    else:
      print "\n✅ Test completed successfully!"
  
  print "\n=== INITIALIZATION SEQUENCE TEST COMPLETE ==="

test-register-state camera context/string -> none:
  print "  Testing register state ($context):"
  
  // Test key registers that should change after proper init
  test-regs := [
    [0x00, "Test register"],
    [0x40, "Sensor ID"],
    [0x41, "Year ID"],
    [0x42, "Month ID"],
    [0x43, "Day ID"],
    [0x44, "Sensor state"],
    [0x45, "FIFO size 1"]
  ]
  
  all-55 := true
  test-regs.do: | reg-info |
    addr := reg-info[0]
    name := reg-info[1]
    val := camera.read-reg addr
    print "    0x$(%02x addr) ($name): 0x$(%02x val)"
    if val != 0x55: all-55 = false
  
  if all-55:
    print "  ❌ All registers still return 0x55 - communication issue"
  else:
    print "  ✅ Got varied register values - communication working!"

test-arducam-commands camera -> none:
  print "  Testing ArduCam command protocol..."
  
  // Test JPEG format command
  print "    Sending JPEG format command (0x55 0x01 0x11 0xAA)..."
  camera.send-arducam-format-command CAM_IMAGE_PIX_FMT_JPG CAM_IMAGE_MODE_QVGA
  
  // Test take picture command
  print "    Sending take picture command (0x55 0x10 0xAA)..."
  camera.send-arducam-capture-command
  
  print "    ✅ Command protocol test complete"

test-capture-readiness camera -> none:
  print "  Testing capture readiness..."
  
  // Test FIFO size after commands
  fifo-size := camera.read-fifo-length
  print "    FIFO size: $fifo-size bytes"
  
  if fifo-size > 0 and fifo-size < 10_000_000:  // Reasonable size
    print "    ✅ FIFO size looks reasonable"
  else:
    print "    ⚠️  FIFO size seems unrealistic: $fifo-size"
  
  // Test first few bytes of FIFO
  print "    Reading first 5 bytes from FIFO..."
  try:
    camera.set-fifo-burst
    bytes := []
    for i := 0; i < 5; i++:
      byte := camera.read-byte
      bytes.add byte
      print "      Byte $i: 0x$(%02x byte)"
    
    // Check if all bytes are 0x55 (communication issue)
    all-55 := bytes.every: it == 0x55
    if all-55:
      print "    ❌ FIFO data all 0x55 - communication issue"
    else:
      print "    ✅ FIFO contains varied data"
    
  finally: | is-exception exception |
    if is-exception:
      print "    ⚠️  Exception reading FIFO: $exception"
