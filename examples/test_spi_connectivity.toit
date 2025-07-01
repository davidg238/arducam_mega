// Test basic SPI connectivity to see if we're actually talking to ArduCam

import arducam_mega show *
import spi
import gpio

main:
  print "=== SPI CONNECTIVITY TEST ==="
  print "Goal: Verify we're actually connected to ArduCam hardware"
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    print "\n1. Test SPI bus creation"
    print "  SPI bus created successfully"
    
    print "\n2. Test different CS pins"
    test-cs-pins bus
    
    print "\n3. Test SPI modes and frequencies"
    test-spi-parameters bus
    
    print "\n4. Test if device responds to known patterns"
    test-response-patterns bus
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== SPI CONNECTIVITY TEST COMPLETE ==="

test-cs-pins bus -> none:
  print "  Testing different CS pins (ArduCam might be on different pin):"
  
  cs-pins := [22, 21, 5, 15, 16, 17]  // Common ESP32 CS pins
  
  cs-pins.do: | cs-num |
    try:
      device := bus.device --cs=(gpio.Pin cs-num) --frequency=1_000_000 --mode=0
      
      // Send a test pattern and see what we get back
      device.write #[0x00, 0x55, 0xAA]
      result := device.read 3
      
      print "    CS pin $cs-num: 0x$(%02x result[0]) 0x$(%02x result[1]) 0x$(%02x result[2])"
      
      // Look for any variation from 0x66
      if result[0] != 0x66 or result[1] != 0x66 or result[2] != 0x66:
        print "      ✅ Different response on CS $cs-num!"
        
    finally: | is-exception exception |
      if is-exception:
        print "    CS pin $cs-num: Error - $exception"

test-spi-parameters bus -> none:
  print "  Testing SPI modes and frequencies on CS 22:"
  
  modes := [0, 1, 2, 3]
  frequencies := [100_000, 1_000_000, 4_000_000, 8_000_000]
  
  modes.do: | mode |
    frequencies.do: | freq |
      try:
        device := bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=mode
        
        device.write #[0x00]
        result := device.read 1
        
        if result[0] != 0x66:
          print "    Mode $mode, $freq Hz: Got 0x$(%02x result[0]) (different!)"
          
      finally: | is-exception exception |
        if is-exception:
          print "    Mode $mode, $freq Hz: Error"
  
  print "    (Only showing non-0x66 responses)"

test-response-patterns bus -> none:
  print "  Testing if device responds to different commands:"
  
  device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
  
  test-commands := [
    [#[0x00], "Read register 0x00"],
    [#[0xFF], "Read register 0xFF"], 
    [#[0x80, 0x55], "Write 0x55 to reg 0x00"],
    [#[0x40], "Read sensor ID"],
    [#[0x44], "Read sensor state"],
    [#[0x12, 0x34, 0x56], "Random pattern"],
    [#[], "Empty command"]
  ]
  
  test-commands.do: | cmd-info |
    command := cmd-info[0]
    description := cmd-info[1]
    
    try:
      if command.size > 0:
        device.write command
        result := device.read (max 1 command.size)
        
        response-str := ""
        result.do: | byte |
          response-str += "0x$(%02x byte) "
          
        print "    $description: $response-str"
        
        // Check for any non-0x66 response
        has-different := false
        result.do: | byte |
          if byte != 0x66:
            has-different = true
            
        if has-different:
          print "      ✅ Got non-0x66 response!"
          
    finally: | is-exception exception |
      if is-exception:
        print "    $description: Error - $exception"
