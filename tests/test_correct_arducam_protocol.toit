// Test the correct ArduCam MEGA command protocol from documentation

import spi
import gpio

main:
  print "=== CORRECT ARDUCAM PROTOCOL TEST ==="
  print "Using proper host communication command protocol"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "SPI device created"
    
    print "\nStep 1: Initialize camera (basic)"
    init-camera-basic device
    
    print "\nStep 2: Set JPEG format using correct protocol"
    set-jpeg-format-correct device
    
    print "\nStep 3: Take picture using correct command"
    take-picture-correct device
    
    print "\nStep 4: Verify JPEG format"
    verify-jpeg-capture device
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during ArduCam protocol test: $exception"
  
  print "\n=== CORRECT ARDUCAM PROTOCOL TEST COMPLETE ==="

init-camera-basic device -> none:
  print "  Basic camera initialization..."
  
  // Initialize I2C tunnel (we know this works)
  write-reg-fpga device 0x07 0x40  // Reset
  sleep --ms=50
  write-reg-fpga device 0x07 0x00  // Clear reset
  sleep --ms=50
  write-reg-fpga device 0x0A 0x78  // Set device address
  sleep --ms=50
  
  sensor-state := read-reg-arduino device 0x44
  print "    Sensor state: 0x$(%02x sensor-state)"

set-jpeg-format-correct device -> none:
  print "  Setting JPEG format using correct ArduCam command protocol..."
  
  // ArduCam command: 0x55 0x01 [parameter] 0xAA
  // Parameter: bit[6:4]=1 (JPEG), bit[3:0]=1 (QVGA 320x240)
  // Parameter = 0x11 (0001 0001 binary)
  
  parameter := 0x11  // JPEG format (1) + QVGA resolution (1)
  
  print "    Sending ArduCam command: 0x55 0x01 0x$(%02x parameter) 0xAA"
  
  // Send the complete ArduCam command
  command := #[0x55, 0x01, parameter, 0xAA]
  device.write command
  
  sleep --ms=100  // Wait for command processing
  
  print "    ✅ JPEG format command sent!"
  
  // Try other format combinations too
  print "    Testing other format combinations:"
  
  // JPEG + VGA (640x480)
  parameter-vga := 0x12  // JPEG (1) + VGA (2)
  print "      Trying JPEG + VGA: 0x55 0x01 0x$(%02x parameter-vga) 0xAA"
  command-vga := #[0x55, 0x01, parameter-vga, 0xAA]
  device.write command-vga
  sleep --ms=100
  
  // RGB565 + QVGA for comparison
  parameter-rgb := 0x21  // RGB565 (2) + QVGA (1)
  print "      Trying RGB565 + QVGA: 0x55 0x01 0x$(%02x parameter-rgb) 0xAA"
  command-rgb := #[0x55, 0x01, parameter-rgb, 0xAA]
  device.write command-rgb
  sleep --ms=100
  
  // Back to JPEG + QVGA
  print "      Setting back to JPEG + QVGA: 0x55 0x01 0x$(%02x parameter) 0xAA"
  device.write command
  sleep --ms=100

take-picture-correct device -> none:
  print "  Taking picture using correct ArduCam command..."
  
  // ArduCam command 0x10: Taking Pictures
  picture-command := #[0x55, 0x10, 0xAA]  // No parameter for take picture
  
  print "    Sending take picture command: 0x55 0x10 0xAA"
  device.write picture-command
  
  sleep --ms=3000  // Wait for capture to complete
  
  print "    Picture command sent, waiting for capture..."
  
  // Check FIFO status
  fifo-size := read-fifo-size device
  print "    FIFO size after capture: $fifo-size bytes"
  
  if fifo-size > 1000:
    print "    ✅ Image data captured!"
  else:
    print "    ❌ No image data in FIFO"

verify-jpeg-capture device -> none:
  print "  Verifying JPEG format..."
  
  fifo-size := read-fifo-size device
  
  if fifo-size == 0:
    print "    ❌ No image data to verify"
    return
  
  print "    Reading image header from FIFO..."
  
  // Set FIFO burst read
  write-reg-fpga device 0x3C 0x00  // Burst FIFO read mode
  
  // Read first bytes using FIFO read command
  device.write #[0x3D]  // Single FIFO read
  header-bytes := device.read 20
  
  print "    First 20 bytes:"
  for i := 0; i < 20; i++:
    print "      [$i]: 0x$(%02x header-bytes[i])"
  
  // Check for JPEG header
  if header-bytes[0] == 0xFF and header-bytes[1] == 0xD8:
    print "    ✅ VALID JPEG HEADER FOUND!"
    print "    ✅ ArduCam MEGA is now producing JPEG images!"
    
    // Look for JPEG end marker
    print "    Checking for JPEG structure..."
    
    // Read more data to check structure
    device.write //[0x3D]
    more-data := device.read 100
    
    jpeg-markers-found := 0
    
    for i := 0; i < more-data.size - 1; i++:
      if more-data[i] == 0xFF:
        marker := more-data[i + 1]
        if marker == 0xE0:
          print "      Found JFIF marker (FF E0)"
          jpeg-markers-found++
        else if marker == 0xDB:
          print "      Found Quantization Table (FF DB)"
          jpeg-markers-found++
        else if marker == 0xC0:
          print "      Found Start of Frame (FF C0)"
          jpeg-markers-found++
        else if marker == 0xDA:
          print "      Found Start of Scan (FF DA)"
          jpeg-markers-found++
    
    if jpeg-markers-found > 0:
      print "    ✅ JPEG structure confirmed! Found $jpeg-markers-found JPEG markers"
      print "    ✅ SUCCESS: ArduCam MEGA JPEG format is working!"
    else:
      print "    ❓ JPEG header found but no internal markers detected"
      
  else:
    print "    ❌ No JPEG header found"
    print "      Expected: FF D8"
    print "      Got: $(%02x header-bytes[0]) $(%02x header-bytes[1])"
    
    // Check what format we got instead
    analyze-image-format header-bytes

analyze-image-format header-bytes/ByteArray -> none:
  print "    Analyzing image format:"
  
  // Check for different formats
  if header-bytes[0] == 0x42 and header-bytes[1] == 0x4D:
    print "      Detected: BMP format"
  else if header-bytes[0] == 0x89 and header-bytes[1] == 0x50:
    print "      Detected: PNG format"
  else if header-bytes.size >= 4 and header-bytes[0] == 0x52 and header-bytes[1] == 0x49 and header-bytes[2] == 0x46 and header-bytes[3] == 0x46:
    print "      Detected: RIFF format (possibly AVI)"
  else:
    // Check for raw RGB data patterns
    all-same := true
    first-byte := header-bytes[0]
    for i := 1; i < (min 10 header-bytes.size); i++:
      if header-bytes[i] != first-byte:
        all-same = false
        break
    
    if all-same:
      print "      Detected: All bytes are 0x$(%02x first-byte) - likely uninitialized/error"
    else:
      print "      Detected: Varied data - likely raw RGB or YUV format"
      print "        Data analysis shows varied bytes - likely raw image format"

read-fifo-size device -> int:
  len1 := read-reg-arduino device 0x45
  len2 := read-reg-arduino device 0x46
  len3 := read-reg-arduino device 0x47
  return ((len3 << 16) | (len2 << 8) | len1) & 0xFFFFFF

write-reg-fpga device/spi.Device addr/int value/int -> none:
  device.write #[addr | 0x80, value]

read-reg-arduino device/spi.Device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]

min a b -> int:
  return a < b ? a : b
