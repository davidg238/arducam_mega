// Deep debug of SPI register read protocol

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI PROTOCOL DEBUG ==="
  print "Goal: Understand why all registers return same value"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\n1. Test different read protocols side-by-side"
    test-read-protocols camera
    
    print "\n2. Test different SPI approaches"
    test-different-approaches camera
    
    print "\n3. Test different registers expected to have different values"
    test-known-different-registers camera
    
    print "\n4. Test register after writes"
    test-after-writes camera
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== SPI PROTOCOL DEBUG COMPLETE ==="

test-read-protocols camera -> none:
  print "  Comparing different read approaches for register 0x00:"
  
  // Method 1: Current camera method
  val1 := camera.read-reg 0x00
  print "    Method 1 (current): 0x$(%02x val1)"
  
  // Method 2: Manual 3-byte sequence
  camera.camera.write #[0x00, 0x00, 0x00]
  result2 := camera.camera.read 3
  val2 := result2[2]
  print "    Method 2 (3-byte): 0x$(%02x val2) [bytes: 0x$(%02x result2[0]) 0x$(%02x result2[1]) 0x$(%02x result2[2])]" 
  
  // Method 3: Single byte read  
  camera.camera.write #[0x00]
  result3 := camera.camera.read 1
  val3 := result3[0]
  print "    Method 3 (1-byte): 0x$(%02x val3)"
  
  // Method 4: Two byte read
  camera.camera.write #[0x00]
  result4 := camera.camera.read 2  
  val4a := result4[0]
  val4b := result4[1]
  print "    Method 4 (2-byte): first=0x$(%02x val4a), second=0x$(%02x val4b)"
  
  print "    Analysis: Looking for which method gives different results..."

test-different-approaches camera -> none:
  print "  Testing different SPI timing approaches:"
  
  // Test with different delays
  delays := [0, 1, 5, 10, 20]
  
  delays.do: | delay |
    camera.camera.write #[0x00, 0x00, 0x00]
    sleep --ms=delay
    result := camera.camera.read 3
    print "    Delay $delay ms: 0x$(%02x result[0]) 0x$(%02x result[1]) 0x$(%02x result[2])"
  
  print "    Looking for timing that gives different results..."

test-known-different-registers camera -> none:
  print "  Testing registers that SHOULD have different values:"
  
  // These registers should definitely be different
  test-regs := [
    [0x00, "TEST1 (should be writable)"],
    [0x02, "POWER (should show power state)"],  
    [0x04, "FIFO (should show FIFO state)"],
    [0x40, "SENSOR_ID (should be hardware ID)"],
    [0x44, "SENSOR_STATE (should show current state)"],
    [0x45, "FIFO_SIZE1 (should vary with FIFO)"],
    [0x46, "FIFO_SIZE2 (should vary with FIFO)"],
    [0x47, "FIFO_SIZE3 (should vary with FIFO)"]
  ]
  
  test-regs.do: | reg-info |
    reg := reg-info[0]
    name := reg-info[1]
    
    value := camera.read-reg reg
    print "    0x$(%02x reg) ($name): 0x$(%02x value)"
  
  print "    If all values are the same, our read protocol is definitely wrong!"

test-after-writes camera -> none:
  print "  Testing register values after known writes:"
  
  // Test the test register which should be writable
  initial := camera.read-reg 0x00
  print "    Initial test reg (0x00): 0x$(%02x initial)"
  
  // Write a known pattern
  camera.write-reg 0x00 0xAA
  sleep --ms=10
  after-write := camera.read-reg 0x00
  print "    After writing 0xAA: 0x$(%02x after-write)"
  
  // Write another pattern
  camera.write-reg 0x00 0x55
  sleep --ms=10
  after-write2 := camera.read-reg 0x00
  print "    After writing 0x55: 0x$(%02x after-write2)"
  
  if after-write == 0xAA:
    print "    ✅ Write/read working perfectly!"
  else if after-write != initial:
    print "    ⚠️  Write changed value but not to expected"
  else:
    print "    ❌ Write had no effect - write protocol issue"
