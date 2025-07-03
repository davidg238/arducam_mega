// Test current state of ArduCam communication

import spi
import gpio

main:
  print "=== ARDUCAM CURRENT STATE TEST ==="
  print "Testing communication with ArduCam..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created successfully"
    
    // Test basic register reads
    print "\nTesting register reads..."
    test1 := read-reg device 0x00
    test2 := read-reg device 0x40  // Sensor ID
    test3 := read-reg device 0x41  // Year ID
    
    print "  Register 0x00: 0x$(%02x test1)"
    print "  Register 0x40: 0x$(%02x test2)"
    print "  Register 0x41: 0x$(%02x test3)"
    
    // Test ArduCam JPEG command
    print "\nSending JPEG format command..."
    jpeg-cmd := #[0x55, 0x01, 0x11, 0xAA]
    device.write jpeg-cmd
    sleep --ms=100
    print "✅ JPEG command sent"
    
    // Take picture
    print "\nTaking picture..."
    pic-cmd := #[0x55, 0x10, 0xAA]
    device.write pic-cmd
    sleep --ms=3000
    print "✅ Picture command sent"
    
    // Check FIFO size
    print "\nReading FIFO size..."
    fifo-size := read-fifo-size device
    print "  FIFO size: $fifo-size bytes"
    
    if fifo-size > 0:
      print "\nReading FIFO header..."
      device.write #[0x3D]  // Single FIFO read
      header := device.read 20
      print "  First 10 bytes:"
      for i := 0; i < 10 and i < header.size; i++:
        print "    [$i]: 0x$(%02x header[i])"
      
      // Check for JPEG header
      if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
        print "  🎉 JPEG HEADER FOUND! 🎉"
      else:
        print "  ❌ No JPEG header (got 0x$(%02x header[0]) 0x$(%02x header[1]))"
    else:
      print "  ❌ No image data in FIFO"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== TEST COMPLETE ==="

read-reg device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

read-fifo-size device/spi.Device -> int:
  len1 := read-reg device 0x45
  len2 := read-reg device 0x46
  len3 := read-reg device 0x47
  return ((len3 << 16) | (len2 << 8) | len1) & 0xFFFFFF
