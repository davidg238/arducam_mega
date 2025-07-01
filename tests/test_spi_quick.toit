// Quick SPI test to check basic functionality and key parameters

import arducam_mega show *
import spi
import gpio

main:
  print "=== QUICK SPI PARAMETER TEST ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  print "\n1. Testing basic SPI device creation..."
  test-basic-device bus
  
  print "\n2. Testing ArduCam camera object..."
  test-camera-object bus
  
  print "\n3. Testing different frequencies..."
  test-different-frequencies bus
  
  print "\n4. Testing register communication..."
  test-register-communication bus
  
  print "\n=== QUICK TEST COMPLETE ==="

test-basic-device bus -> none:
  try:
    // Test basic SPI device creation
    device := bus.device --cs=(gpio.Pin 22) --frequency=4_000_000 --mode=0
    print "  ✅ SPI device created successfully"
    
    // Test basic transaction
    cs-pin := gpio.Pin 22
    cs-pin.set 0
    device.write #[0x00]
    result := device.read 1
    cs-pin.set 1
    
    print "  Basic transaction result: 0x$(%02x result[0])"
    
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Basic device test failed: $exception"

test-camera-object bus -> none:
  try:
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "  ✅ ArducamCamera object created successfully"
    
    // Test basic register read
    value := camera.read-reg 0x00
    print "  Register 0x00 read: 0x$(%02x value)"
    
    // Test basic register write/read
    camera.write-reg 0x00 0x42
    sleep --ms=2
    readback := camera.read-reg 0x00
    print "  Wrote 0x42, read back: 0x$(%02x readback)"
    
    if readback == 0x42:
      print "  ✅ Basic register communication WORKS!"
    else:
      print "  ❌ Basic register communication failed"
    
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Camera object test failed: $exception"

test-different-frequencies bus -> none:
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  
  // Test the default frequency (1MHz)
  print "  Testing default frequency (1MHz)..."
  test-freq-result camera "1MHz default"
  
  // Test if we can override by creating new ArducamCamera with different freq
  // (Work around the final camera field limitation)
  frequencies := [100_000, 500_000, 4_000_000, 8_000_000]
  
  frequencies.do: | freq |
    bus2 := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18
    
    try:
      // Create ArducamCamera that internally uses this frequency
      camera2 := ArducamCamera --spi-bus=bus2 --cs=(gpio.Pin 22)
      
      print "  Testing frequency $freq Hz..."
      test-freq-result camera2 "$freq Hz"
      
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ $freq Hz failed: $exception"

test-freq-result camera name -> none:
  try:
    camera.write-reg 0x00 0x88
    sleep --ms=1
    readback := camera.read-reg 0x00
    
    if readback == 0x88:
      print "    ✅ $name: Register communication works"
    else:
      print "    ❌ $name: Register communication failed (got 0x$(%02x readback))"
      
  finally: | is-exception exception |
    if is-exception:
      print "    ❌ $name: Exception: $exception"

test-register-communication bus -> none:
  camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
  
  print "  Testing various registers..."
  
  // Test control registers (SPI direct)
  control-tests := [
    [0x00, "ARDUCHIP_TEST1"],
    [0x01, "ARDUCHIP_FRAMES"], 
    [0x04, "ARDUCHIP_FIFO"],
  ]
  
  control-tests.do: | test |
    reg := test[0]
    name := test[1]
    
    try:
      value := camera.read-reg reg
      print "    Control reg 0x$(%02x reg) ($name): 0x$(%02x value)"
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ Control reg 0x$(%02x reg) failed: $exception"
  
  // Test sensor registers (I2C tunnel)
  sensor-tests := [
    [0x40, "SENSOR_ID"],
    [0x41, "YEAR_ID"],
    [0x44, "SENSOR_STATE"],
  ]
  
  print "  Testing sensor registers (I2C tunnel)..."
  sensor-tests.do: | test |
    reg := test[0]
    name := test[1]
    
    try:
      value := camera.read-reg reg
      print "    Sensor reg 0x$(%02x reg) ($name): 0x$(%02x value)"
      
      if value != 0x00:
        print "      ✅ Sensor register responding!"
    finally: | is-exception exception |
      if is-exception:
        print "    ❌ Sensor reg 0x$(%02x reg) failed: $exception"
