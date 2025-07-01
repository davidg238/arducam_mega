// Master Test Suite: Run all SPI parameter tests systematically
// This will help us identify exactly what Arduino does differently

import arducam_mega show *
import spi
import gpio

main:
  print "==================================================="
  print "    ARDUCAM SPI PARAMETER INVESTIGATION"
  print "    Goal: Match Arduino SPI behavior exactly"
  print "==================================================="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  print "\n1️⃣  TESTING BASIC SPI FUNCTIONALITY"
  print "   (Verify our SPI setup works at all)"
  test-basic-spi-functionality bus
  
  print "\n2️⃣  TESTING SPI FREQUENCIES"
  print "   (Arduino typically uses 1-8MHz)"
  test-frequencies bus
  
  print "\n3️⃣  TESTING SPI MODES"
  print "   (CPOL/CPHA combinations)"
  test-modes bus
  
  print "\n4️⃣  TESTING TIMING AND DELAYS"
  print "   (Arduino SPI lib might have built-in delays)"
  test-timing bus
  
  print "\n5️⃣  TESTING TRANSACTION FORMATS"
  print "   (Bit order, address format, etc.)"
  test-formats bus
  
  print "\n==================================================="
  print "    SPI INVESTIGATION COMPLETE"
  print "    Check output above for working combinations"
  print "==================================================="

test-basic-spi-functionality bus -> none:
  try:
    print "   Creating basic SPI device..."
    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    
    print "   Testing raw SPI transaction..."
    cs-pin := gpio.Pin 22
    cs-pin.set 0
    device.write #[0x00]  // Send command
    result := device.read 1  // Read response
    cs-pin.set 1
    
    print "   Raw SPI result: 0x$(%02x result[0])"
    print "   ✅ Basic SPI hardware is working"
    
  finally: | is-exception exception |
    if is-exception:
      print "   ❌ Basic SPI failed: $exception"
      print "   Check wiring: MISO=19, MOSI=23, CLK=18, CS=22"

test-frequencies bus -> none:
  print "   Testing key frequencies that Arduino might use..."
  
  // Focus on most likely Arduino frequencies
  frequencies := [1_000_000, 4_000_000, 8_000_000]
  
  frequencies.do: | freq |
    success := test-frequency-quick bus freq
    if success:
      print "   ✅ FREQUENCY $freq Hz: Communication working!"
    else:
      print "   ❌ FREQUENCY $freq Hz: Failed"

test-frequency-quick bus freq -> bool:
  try:
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=0
    
    // Quick test: write and read back
    camera.write-reg 0x00 0x55
    sleep --ms=1
    readback := camera.read-reg 0x00
    
    return readback == 0x55
    
  finally: | is-exception exception |
    if is-exception:
      return false

test-modes bus -> none:
  print "   Testing SPI modes (CPOL/CPHA combinations)..."
  
  modes := [0, 1, 2, 3]
  
  modes.do: | mode |
    success := test-mode-quick bus mode
    if success:
      print "   ✅ MODE $mode: Communication working!"
    else:
      print "   ❌ MODE $mode: Failed"

test-mode-quick bus mode -> bool:
  try:
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=mode
    
    // Quick test
    camera.write-reg 0x00 0xAA
    sleep --ms=1
    readback := camera.read-reg 0x00
    
    return readback == 0xAA
    
  finally: | is-exception exception |
    if is-exception:
      return false

test-timing bus -> none:
  print "   Testing if delays help..."
  
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=0
  
  // Test with no delays
  camera.write-reg 0x00 0x33
  readback1 := camera.read-reg 0x00
  
  // Test with delays
  camera.write-reg 0x00 0x66
  sleep --ms=5
  readback2 := camera.read-reg 0x00
  
  if readback1 == 0x33:
    print "   ✅ TIMING: No delays needed - works immediately"
  else if readback2 == 0x66:
    print "   ✅ TIMING: Delays help - needs time between operations"
  else:
    print "   ❌ TIMING: Neither approach works"

test-formats bus -> none:
  print "   Testing transaction format variations..."
  
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  camera.camera = bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=0
  
  // Test current format
  camera.write-reg 0x00 0x99
  readback1 := camera.read-reg 0x00
  
  if readback1 == 0x99:
    print "   ✅ FORMAT: Current transaction format works"
  else:
    print "   ❌ FORMAT: Current transaction format failed"
    
    # Test alternative format
    try:
      cs-pin := gpio.Pin 22
      cs-pin.set 0
      camera.camera.write #[0x00, 0x77]  // Alternative write format
      cs-pin.set 1
      sleep --ms=1
      
      alt-readback := camera.read-reg 0x00
      if alt-readback == 0x77:
        print "   ✅ FORMAT: Alternative format works!"
      else:
        print "   ❌ FORMAT: Alternative format also failed"
        
    finally: | is-exception exception |
      if is-exception:
        print "   ❌ FORMAT: Exception testing alternative: $exception"
