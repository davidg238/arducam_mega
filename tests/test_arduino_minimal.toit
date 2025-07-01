// Minimal test to replicate what Arduino does in setup()
// Arduino: myCAM.begin() and it just works

import arducam_mega show *
import spi
import gpio

main:
  print "=== ARDUINO MINIMAL REPLICATION TEST ==="
  print "Goal: Replicate myCAM.begin() success"
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  print "\nStep 1: Create camera (like Arduino constructor)"
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  print "Camera object created"
  
  print "\nStep 2: Test BEFORE calling begin/on"
  print "(Arduino might work even before begin)"
  test-basic-registers camera "BEFORE begin"
  
  print "\nStep 3: Call camera.on() (like Arduino begin)"
  try:
    // This is where it was hanging before
    camera.on
    print "camera.on() completed successfully!"
    
  finally: | is-exception exception |
    if is-exception:
      print "camera.on() failed: $exception"
      print "(This is where we were hanging before)"
  
  print "\nStep 4: Test AFTER calling begin/on"
  test-basic-registers camera "AFTER begin"
  
  print "\nStep 5: Test version info (the failing part)"
  test-version-info camera
  
  print "\n=== ARDUINO MINIMAL TEST COMPLETE ==="

test-basic-registers camera phase -> none:
  print "  Testing basic registers ($phase):"
  
  try:
    // Test 1: Simple read
    test-reg := camera.read-reg 0x00
    print "    Test register 0x00: 0x$(%02x test-reg)"
    
    // Test 2: Write/read cycle
    camera.write-reg 0x00 0x55
    sleep --ms=2
    readback := camera.read-reg 0x00
    print "    Wrote 0x55, read: 0x$(%02x readback)"
    
    if readback == 0x55:
      print "    ✅ Basic register R/W works $phase"
    else:
      print "    ❌ Basic register R/W failed $phase"
    
    // Test 3: Power control register (used in init)
    power-reg := camera.read-reg 0x02
    print "    Power control reg: 0x$(%02x power-reg)"
    
    // Test 4: Reset register (where it hangs)
    reset-reg := camera.read-reg 0x07
    print "    Reset register: 0x$(%02x reset-reg)"
    
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ Exception testing basic registers $phase: $exception"

test-version-info camera -> none:
  print "  Testing version registers (were returning 0x00):"
  
  version-regs := [
    [0x40, "SENSOR_ID"],
    [0x41, "YEAR_ID"], 
    [0x42, "MONTH_ID"],
    [0x43, "DAY_ID"],
    [0x44, "SENSOR_STATE"],
    [0x49, "VERSION_NUM"]
  ]
  
  working-count := 0
  
  version-regs.do: | reg-info |
    reg := reg-info[0]
    name := reg-info[1]
    
    try:
      value := camera.read-reg reg
      print "    0x$(%02x reg) ($name): 0x$(%02x value)"
      
      if value != 0x00:
        working-count++
        print "      ✅ Non-zero value!"
        
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ Error reading 0x$(%02x reg) ($name): $exception"
  
  if working-count > 0:
    print "  ✅ SUCCESS: $working-count version registers responding!"
  else:
    print "  ❌ All version registers still return 0x00"
    print "  (This indicates I2C tunnel not working)"
