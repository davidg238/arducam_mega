// Simple JPEG verification after ArduCam protocol success

import spi
import gpio

main:
  print "=== SIMPLE JPEG VERIFICATION TEST ==="
  print "Testing JPEG format after successful ArduCam commands"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "SPI device created"
    
    print "\nStep 1: Send ArduCam JPEG command"
    send-jpeg-command device
    
    print "\nStep 2: Take picture"
    take-picture device
    
    print "\nStep 3: Read and verify FIFO data"
    verify-fifo-data device
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during JPEG verification: $exception"
  
  print "\n=== SIMPLE JPEG VERIFICATION TEST COMPLETE ==="

send-jpeg-command device/spi.Device -> none:
  print "  Sending JPEG + QVGA command..."
  
  // ArduCam command: 0x55 0x01 0x11 0xAA
  // 0x11 = JPEG format (bit[6:4]=1) + QVGA resolution (bit[3:0]=1)
  jpeg-command := #[0x55, 0x01, 0x11, 0xAA]
  device.write jpeg-command
  sleep --ms=100
  
  print "    ✅ JPEG format command sent"

take-picture device/spi.Device -> none:
  print "  Taking picture..."
  
  // ArduCam take picture command: 0x55 0x10 0xAA
  picture-command := #[0x55, 0x10, 0xAA]
  device.write picture-command
  sleep --ms=3000  // Wait for capture
  
  print "    ✅ Picture command sent"

verify-fifo-data device/spi.Device -> none:
  print "  Verifying FIFO data..."
  
  // Read FIFO size using Arduino register protocol
  fifo-size := read-fifo-size device
  print "    FIFO size: $fifo-size bytes"
  
  if fifo-size == 0:
    print "    ❌ No image data captured"
    return
  
  if fifo-size > 16000000:  // > 16MB suggests raw data
    print "    ⚠️  Very large FIFO ($fifo-size bytes) - likely raw format"
  else if fifo-size > 1000000:  // > 1MB
    print "    ❓ Large FIFO ($fifo-size bytes) - could be high-res JPEG or raw"
  else:
    print "    ✅ Reasonable FIFO size ($fifo-size bytes) - good for JPEG"
  
  print "  Reading FIFO header..."
  
  // Try to read FIFO data using single FIFO read command
  // According to ArduCam docs, 0x3D is single FIFO read
  try:
    device.write #[0x3D]  // Single FIFO read command
    header-data := device.read 50  // Read first 50 bytes
    
    print "    First 20 bytes from FIFO:"
    for i := 0; i < 20 and i < header-data.size; i++:
      print "      [$i]: 0x$(%02x header-data[i])"
    
    // Check for JPEG header
    if header-data.size >= 2:
      if header-data[0] == 0xFF and header-data[1] == 0xD8:
        print "    ✅ ✅ ✅ VALID JPEG HEADER FOUND! ✅ ✅ ✅"
        print "    ✅ ArduCam MEGA JPEG format is WORKING!"
        
        // Check for additional JPEG markers
        jpeg-markers := []
        for i := 0; i < header-data.size - 1; i++:
          if header-data[i] == 0xFF:
            marker := header-data[i + 1]
            if marker == 0xE0: jpeg-markers.add "JFIF"
            else if marker == 0xDB: jpeg-markers.add "Quantization"
            else if marker == 0xC0: jpeg-markers.add "Start-of-Frame"
            else if marker == 0xDA: jpeg-markers.add "Start-of-Scan"
        
        if jpeg-markers.size > 0:
          print "    ✅ JPEG structure confirmed: $jpeg-markers"
          
      else:
        print "    ❌ No JPEG header detected"
        print "      Expected: FF D8"
        print "      Got: $(%02x header-data[0]) $(%02x header-data[1])"
        
        // Analyze the format
        if all-bytes-same header-data:
          print "      All bytes same value - likely uninitialized FIFO"
        else:
          print "      Varied data - likely raw image format (RGB/YUV)"
    else:
      print "    ❌ Insufficient data read from FIFO"
      
  finally: | is-exception exception |
    if is-exception:
      print "    FIFO read exception: $exception"

read-fifo-size device/spi.Device -> int:
  // Read FIFO size from registers 0x45, 0x46, 0x47
  len1 := read-reg-arduino device 0x45
  len2 := read-reg-arduino device 0x46
  len3 := read-reg-arduino device 0x47
  return ((len3 << 16) | (len2 << 8) | len1) & 0xFFFFFF

read-reg-arduino device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

all-bytes-same data/ByteArray -> bool:
  if data.size == 0: return true
  first-byte := data[0]
  for i := 1; i < data.size; i++:
    if data[i] != first-byte: return false
  return true
