// Hardware diagnostic - check if ArduCam is actually connected and powered

import spi
import gpio

main:
  print "=== HARDWARE DIAGNOSTIC ==="
  print "Goal: Determine if ArduCam hardware is connected and responding"
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  print "\n1. Testing different CS pins:"
  test-cs-pins bus
  
  print "\n2. Testing different SPI frequencies:"
  test-frequencies bus
  
  print "\n3. Testing different SPI modes:"
  test-modes bus
  
  print "\n4. Testing GPIO pin states:"
  test-gpio-states
  
  print "\n=== HARDWARE DIAGNOSTIC COMPLETE ==="

test-cs-pins bus -> none:
  // Test all common ESP32 pins that could be CS
  cs-candidates := [5, 15, 22, 23, 25, 26, 27]
  
  cs-candidates.do: | cs-pin |
    try:
      device := bus.device --cs=(gpio.Pin cs-pin) --frequency=1_000_000 --mode=0
      
      // Send simple command and check for non-0x55 response
      device.write #[0x40]  // Sensor ID register
      result := device.read 1
      
      if result[0] != 0x55:
        print "  ⭐ CS Pin $cs-pin: Got 0x$(%02x result[0]) - DIFFERENT RESPONSE!"
      else:
        print "  CS Pin $cs-pin: 0x$(%02x result[0]) (typical no-device response)"
        
    finally: | is-exception exception |
      if is-exception:
        print "  CS Pin $cs-pin: ERROR - $exception"

test-frequencies bus -> none:
  // Test different frequencies to see if timing is the issue
  frequencies := [100_000, 1_000_000, 4_000_000, 8_000_000]
  
  print "  Testing CS pin 22 at different frequencies:"
  
  frequencies.do: | freq |
    try:
      device := bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=0
      
      device.write #[0x40]  // Sensor ID
      result := device.read 1
      
      if result[0] != 0x55:
        print "  ⭐ $freq Hz: Got 0x$(%02x result[0]) - DIFFERENT!"
      else:
        print "  $freq Hz: 0x$(%02x result[0])"
        
    finally: | is-exception exception |
      if is-exception:
        print "  $freq Hz: ERROR - $exception"

test-modes bus -> none:
  // Test different SPI modes
  modes := [0, 1, 2, 3]
  
  print "  Testing CS pin 22 with different SPI modes:"
  
  modes.do: | mode |
    try:
      device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=mode
      
      device.write #[0x40]  // Sensor ID
      result := device.read 1
      
      if result[0] != 0x55:
        print "  ⭐ Mode $mode: Got 0x$(%02x result[0]) - DIFFERENT!"
      else:
        print "  Mode $mode: 0x$(%02x result[0])"
        
    finally: | is-exception exception |
      if is-exception:
        print "  Mode $mode: ERROR - $exception"

test-gpio-states -> none:
  // Check if the GPIO pins are in expected states
  pin-info := [
    [19, "MISO"],
    [23, "MOSI"], 
    [18, "CLK"],
    [22, "CS"],
  ]
  
  pin-info.do: | info |
    pin-num := info[0]
    pin-name := info[1]
    
    try:
      pin := gpio.Pin pin-num
      pin.configure --input
      
      // Read pin state
      state := pin.get
      print "  Pin $pin-num ($pin-name): $state"
      
    finally: | is-exception exception |
      if is-exception:
        print "  Pin $pin-num ($pin-name): ERROR - $exception"
  
  print "\n  NOTE: Expected states when idle:"
  print "    MISO: Usually high (1) when no device or device idle"
  print "    MOSI: Could be 0 or 1"
  print "    CLK: Usually low (0) when idle"
  print "    CS: Usually high (1) when not selected"
