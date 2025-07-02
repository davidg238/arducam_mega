// Find the actual sensor format registers and valid values

import spi
import gpio

main:
  print "=== FIND SENSOR FORMAT REGISTERS TEST ==="
  print "Scanning for real sensor registers and format controls"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "SPI device created"
    
    print "\nStep 1: Initialize I2C tunnel"
    init-i2c-tunnel device
    
    print "\nStep 2: Scan for sensor registers with real data"
    scan-for-real-registers device
    
    print "\nStep 3: Test known format-related register addresses"
    test-format-registers device
    
    print "\nStep 4: Test JPEG encoding enable sequences"
    test-jpeg-enable-sequences device
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException during format register search: $exception"
  
  print "\n=== FIND SENSOR FORMAT REGISTERS TEST COMPLETE ==="

init-i2c-tunnel device -> none:
  print "  Initializing I2C tunnel..."
  write-reg-fpga device 0x07 0x40
  sleep --ms=50
  write-reg-fpga device 0x07 0x00
  sleep --ms=50
  write-reg-fpga device 0x0A 0x78
  sleep --ms=50

scan-for-real-registers device -> none:
  print "  Scanning sensor register space for real data..."
  
  // Scan common sensor register ranges
  register-ranges := [
    [0x3000, 0x3010, "Sensor ID range"],
    [0x3800, 0x3810, "Sensor config range"],
    [0x4000, 0x4010, "Format control range"],
    [0x4300, 0x4310, "JPEG control range"],
    [0x5000, 0x5010, "Image processing range"],
  ]
  
  real-registers := []
  
  register-ranges.do: | range |
    start := range[0]
    end := range[1]
    name := range[2]
    print "    Scanning $name (0x$(%04x start) - 0x$(%04x end)):"
    
    for addr := start; addr < end; addr++:
      value := read-sensor-register device addr
      if value != 0xFF:
        print "      0x$(%04x addr): 0x$(%02x value) ← REAL DATA!"
        real-registers.add [addr, value]
      
      sleep --ms=5  // Small delay between reads
  
  print "  Found $(real-registers.size) registers with real data"
  
  // Test if any of these registers are writable
  if real-registers.size > 0:
    print "  Testing if real registers are writable..."
    real-registers.do: | reg-info |
      addr := reg-info[0]
      original := reg-info[1]
      
      // Try writing a different value
      test-value := (original + 1) & 0xFF
      write-sensor-register device addr test-value
      
      new-value := read-sensor-register device addr
      if new-value != original:
        print "    0x$(%04x addr): WRITABLE! Changed from 0x$(%02x original) to 0x$(%02x new-value)"
      else:
        print "    0x$(%04x addr): Read-only (stayed 0x$(%02x original))"
      
      sleep --ms=10

test-format-registers device -> none:
  print "  Testing known format-related register addresses..."
  
  // Common sensor format register addresses from various camera sensors
  format-candidates := [
    [0x3820, "Image orientation"],
    [0x4300, "Format control"],
    [0x4301, "Format control 2"],
    [0x501F, "ISP format control"],
    [0x5000, "ISP control"],
    [0x5001, "ISP control 2"],
    [0x3008, "System control"],
    [0x300E, "Clock control"],
  ]
  
  working-format-regs := []
  
  format-candidates.do: | candidate |
    addr := candidate[0]
    name := candidate[1]
    
    print "    Testing $name (0x$(%04x addr)):"
    
    before := read-sensor-register device addr
    print "      Before: 0x$(%02x before)"
    
    if before != 0xFF:
      print "        ✅ Register exists!"
      
      // Test different format values
      test-values := [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
      
      test-values.do: | test-val |
        write-sensor-register device addr test-val
        after := read-sensor-register device addr
        
        if after == test-val:
          print "        ✅ Accepts value 0x$(%02x test-val)!"
          working-format-regs.add [addr, test-val]
        else if after != before:
          print "        ⚠️  Changed to 0x$(%02x after) (not 0x$(%02x test-val))"
        
        sleep --ms=5
      
      // Restore original value
      write-sensor-register device addr before
    else:
      print "        ❌ Register doesn't exist (0xFF)"
    
    sleep --ms=10
  
  print "  Found $(working-format-regs.size) working format registers"

test-jpeg-enable-sequences device -> none:
  print "  Testing JPEG enable sequences..."
  
  // Common JPEG enable sequences from different sensors
  jpeg-sequences := [
    "Sequence 1: Basic JPEG enable",
    "Sequence 2: ISP JPEG enable", 
    "Sequence 3: Format + compression",
  ]
  
  // Sequence 1: Basic JPEG enable
  print "    Testing Sequence 1: Basic JPEG enable..."
  write-sensor-register device 0x4300 0x30  // Common JPEG enable value
  sleep --ms=50
  write-sensor-register device 0x4301 0x01  // JPEG format
  sleep --ms=50
  result1 := test-capture-and-check device "Sequence 1"
  
  // Sequence 2: ISP JPEG enable  
  print "    Testing Sequence 2: ISP JPEG enable..."
  write-sensor-register device 0x5000 0x87  // Enable ISP modules
  sleep --ms=50
  write-sensor-register device 0x501F 0x01  // Set ISP format to JPEG
  sleep --ms=50
  result2 := test-capture-and-check device "Sequence 2"
  
  // Sequence 3: Combined approach
  print "    Testing Sequence 3: Combined approach..."
  write-sensor-register device 0x4300 0x30
  sleep --ms=20
  write-sensor-register device 0x4301 0x01
  sleep --ms=20
  write-sensor-register device 0x5000 0x87
  sleep --ms=20
  write-sensor-register device 0x501F 0x01
  sleep --ms=50
  result3 := test-capture-and-check device "Sequence 3"
  
  // Report results
  results := [result1, result2, result3]
  for i := 0; i < results.size; i++:
    if results[i]:
      print "    ✅ $(jpeg-sequences[i]) - SUCCESS!"
    else:
      print "    ❌ $(jpeg-sequences[i]) - Failed"

test-capture-and-check device sequence-name/string -> bool:
  print "      Testing capture with $sequence-name..."
  
  // Trigger capture via FPGA
  write-reg-fpga device 0x04 0x02  // Start capture
  sleep --ms=2000  // Wait for capture
  
  // Check FIFO
  fifo-size := read-fifo-size device
  print "        FIFO size: $fifo-size bytes"
  
  if fifo-size > 1000:  // Some reasonable threshold
    // Check for JPEG header
    header := read-fifo-data device 10
    
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "        ✅ JPEG header found!"
      return true
    else:
      print "        ❌ No JPEG header: 0x$(%02x header[0]) 0x$(%02x header[1])"
  else:
    print "        ❌ Insufficient data captured"
  
  return false

read-fifo-size device -> int:
  // Read FIFO size from FPGA registers
  len1 := read-reg-arduino device 0x45  // FIFO_SIZE1
  len2 := read-reg-arduino device 0x46  // FIFO_SIZE2  
  len3 := read-reg-arduino device 0x47  // FIFO_SIZE3
  return ((len3 << 16) | (len2 << 8) | len1) & 0xFFFFFF

read-fifo-data device size/int -> ByteArray:
  // Read data from FIFO
  write-reg-fpga device 0x3C 0x00  // Set FIFO burst read
  
  // Use SPI to read FIFO data
  data := ByteArray size
  device.write #[0x3C]  // FIFO read command
  responses := device.read size
  
  for i := 0; i < size; i++:
    data[i] = responses[i]
  
  return data

// Sensor register access via debug mechanism
read-sensor-register device addr/int -> int:
  write-reg-fpga device 0x0B (addr >> 8) & 0xFF
  sleep --ms=2
  write-reg-fpga device 0x0C addr & 0xFF
  sleep --ms=2
  write-reg-fpga device 0x07 0x01
  sleep --ms=10
  return read-reg-arduino device 0x48

write-sensor-register device addr/int value/int -> none:
  write-reg-fpga device 0x0B (addr >> 8) & 0xFF
  sleep --ms=2
  write-reg-fpga device 0x0C addr & 0xFF
  sleep --ms=2
  write-reg-fpga device 0x0D value
  sleep --ms=10

write-reg-fpga device addr/int value/int -> none:
  device.write #[addr | 0x80, value]

read-reg-arduino device addr/int -> int:
  command := #[addr & 0x7F, 0x00, 0x00]
  device.write command
  responses := device.read 3
  return responses[2]
