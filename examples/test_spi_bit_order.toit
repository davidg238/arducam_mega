// Test Suite 4: SPI Bit Ordering and Transaction Format
// Check if our SPI transaction format matches what Arduino does

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI BIT ORDER AND FORMAT TEST SUITE ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  // Use 4MHz mode 0 (most common Arduino settings)
  camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=0
  
  print "\n--- Test 1: Current transaction format ---"
  test-current-format camera
  
  print "\n--- Test 2: Different write formats ---"
  test-write-formats camera
  
  print "\n--- Test 3: Different read formats ---"
  test-read-formats camera
  
  print "\n--- Test 4: Multi-byte transactions ---"
  test-multi-byte-transactions camera
  
  print "\n--- Test 5: Register address formatting ---"
  test-address-formats camera
  
  print "\n=== BIT ORDER TEST COMPLETE ==="

test-current-format camera -> none:
  print "  Testing current read-reg/write-reg format..."
  
  try:
    // Show what our current implementation does
    print "  Current write-reg format: [0x80 | addr, value]"
    print "  Current read-reg format: [addr & 0x7F] -> read 1 byte"
    
    // Test it
    initial := camera.read-reg 0x00
    camera.write-reg 0x00 0x33
    readback := camera.read-reg 0x00
    
    print "  Initial: 0x$(%02x initial), Wrote: 0x33, Read: 0x$(%02x readback)"
    
    if readback == 0x33:
      print "  ✅ Current format works!"
    else:
      print "  ❌ Current format failed"
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Current format test failed: $exception"

test-write-formats camera -> none:
  print "  Testing different write transaction formats..."
  
  cs-pin := gpio.Pin 22
  
  // Format 1: Current (address | 0x80, value)
  print "  Format 1: [addr|0x80, value]"
  test-write-format camera "F1" 0x00 0xAA: 
    #[0x80, 0xAA]
  
  // Format 2: Just address, value
  print "  Format 2: [addr, value]"
  test-write-format camera "F2" 0x00 0xBB:
    #[0x00, 0xBB]
  
  // Format 3: Address with different bit pattern
  print "  Format 3: [addr|0x40, value]"
  test-write-format camera "F3" 0x00 0xCC:
    #[0x40, 0xCC]
    
  // Format 4: Three-byte format
  print "  Format 4: [addr|0x80, value, dummy]"
  test-write-format camera "F4" 0x00 0xDD:
    #[0x80, 0xDD, 0x00]

test-write-format camera name addr value data-bytes -> none:
  try:
    cs-pin := gpio.Pin 22
    
    cs-pin.set 0  // CS low
    camera.camera.write data-bytes
    cs-pin.set 1  // CS high
    sleep --ms=2
    
    // Try to read back
    readback := camera.read-reg addr
    print "    $name: Wrote 0x$(%02x value), Read: 0x$(%02x readback)"
    
    if readback == value:
      print "    ✅ $name format works!"
    
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ $name format failed: $exception"

test-read-formats camera -> none:
  print "  Testing different read transaction formats..."
  
  // First, write a known value
  camera.write-reg 0x00 0x77
  sleep --ms=2
  
  // Format 1: Current (send addr, read 1 byte)
  print "  Read Format 1: send [addr], read 1 byte"
  test-read-format camera "R1" 0x00:
    camera.camera.write #[0x00]
    camera.camera.read 1
  
  // Format 2: Send addr, dummy, read 1 byte  
  print "  Read Format 2: send [addr, 0x00], read 1 byte"
  test-read-format camera "R2" 0x00:
    camera.camera.write #[0x00, 0x00]
    camera.camera.read 1
    
  // Format 3: Single transfer
  print "  Read Format 3: transfer [addr, 0x00]"
  test-read-format camera "R3" 0x00:
    result := #[0x00, 0x00]
    camera.camera.transfer result
    #[result[1]]  // Return second byte

test-read-format camera name addr block -> none:
  try:
    cs-pin := gpio.Pin 22
    
    cs-pin.set 0  // CS low
    result := block.call
    cs-pin.set 1  // CS high
    
    value := result[0]
    print "    $name: Read 0x$(%02x value)"
    
    if value == 0x77:
      print "    ✅ $name format works!"
      
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ $name format failed: $exception"

test-multi-byte-transactions camera -> none:
  print "  Testing multi-byte transactions..."
  
  try:
    // Test reading multiple registers in one transaction
    cs-pin := gpio.Pin 22
    
    print "  Multi-read test: registers 0x00-0x02"
    cs-pin.set 0
    camera.camera.write #[0x00]  // Start at register 0x00
    result := camera.camera.read 3  // Read 3 bytes
    cs-pin.set 1
    
    print "    Multi-read: 0x$(%02x result[0]) 0x$(%02x result[1]) 0x$(%02x result[2])"
    
    // Compare with individual reads
    r0 := camera.read-reg 0x00
    r1 := camera.read-reg 0x01  
    r2 := camera.read-reg 0x02
    print "    Individual: 0x$(%02x r0) 0x$(%02x r1) 0x$(%02x r2)"
    
    if result[0] == r0 and result[1] == r1 and result[2] == r2:
      print "    ✅ Multi-byte read matches individual reads"
    else:
      print "    ❌ Multi-byte read differs from individual reads"
      
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ Multi-byte test failed: $exception"

test-address-formats camera -> none:
  print "  Testing different address bit patterns..."
  
  // Test if address needs specific formatting
  test-addresses := [0x00, 0x01, 0x02, 0x40, 0x41, 0x44]
  test-names := ["TEST1", "FRAMES", "POWER", "SENSOR_ID", "YEAR", "STATE"]
  
  for i := 0; i < test-addresses.size; i++:
    addr := test-addresses[i]
    name := test-names[i]
    
    // Read with current format
    value1 := camera.read-reg addr
    
    // Read with alternative format (no masking)
    cs-pin := gpio.Pin 22
    cs-pin.set 0
    camera.camera.write #[addr]  // Don't mask with 0x7F
    result := camera.camera.read 1
    cs-pin.set 1
    value2 := result[0]
    
    print "    0x$(%02x addr) ($name): masked=0x$(%02x value1), raw=0x$(%02x value2)"
    
    if value1 != value2:
      print "    ⚠️  Different results with/without address masking!"
