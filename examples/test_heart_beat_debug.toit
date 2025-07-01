// Debug heart beat issue to enable image capture

import arducam_mega show *
import spi
import gpio

main:
  print "=== HEART BEAT DEBUG TEST ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "Camera created"
    
    print "\nStep 1: Initialize camera"
    camera.on
    print "Camera initialization complete!"
    
    print "\nStep 2: Debug heart beat in detail"
    debug-heart-beat camera
    
    print "\nStep 3: Try to fix sensor state"
    try-fix-sensor-state camera
    
    print "\nStep 4: Test heart beat after fix attempts"
    debug-heart-beat camera
    
  finally: | is-exception exception |
    if is-exception:
      print "\nException: $exception"
  
  print "\n=== HEART BEAT DEBUG COMPLETE ==="

debug-heart-beat camera -> none:
  print "  Reading sensor state register (0x44)..."
  
  // Read the sensor state multiple times
  for i := 0; i < 5; i++:
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    state-bits := sensor-state & 0x03
    idle-expected := 0x02  // CAM_REG_SENSOR_STATE_IDLE
    
    print "    Read $i: state=0x$(%02x sensor-state), bits=0x$(%02x state-bits), idle?=$(state-bits == idle-expected)"
    sleep --ms=10
  
  // Check heart beat function
  heart-beat := camera.heart-beat
  print "  Heart beat result: $(heart-beat ? "✅ OK" : "❌ Failed")"
  
  // Analyze the bits
  latest-state := camera.read-reg 0x44
  print "\n  Detailed analysis of state 0x$(%02x latest-state):"
  print "    Bit 0 (0x01): $((latest-state & 0x01) != 0 ? "SET" : "clear")"
  print "    Bit 1 (0x02): $((latest-state & 0x02) != 0 ? "SET" : "clear") <- This should be SET for idle"
  print "    Bit 2 (0x04): $((latest-state & 0x04) != 0 ? "SET" : "clear")"
  print "    Bit 3 (0x08): $((latest-state & 0x08) != 0 ? "SET" : "clear")"
  print "    Bits 0-1 (0x03 mask): 0x$(%02x (latest-state & 0x03)) (should be 0x02 for idle)"

try-fix-sensor-state camera -> none:
  print "  Attempting to fix sensor state..."
  
  // Try 1: Wait for sensor to settle
  print "    Try 1: Waiting for sensor to settle..."
  for i := 0; i < 10; i++:
    sleep --ms=100
    state := camera.read-reg 0x44
    if (state & 0x03) == 0x02:
      delay := (i+1)*100
      print "      ✅ Sensor became idle after $delay ms!"
      return
    print "      Waiting... state=0x$(%02x state)"
  
  // Try 2: Reset sensor
  print "    Try 2: Resetting sensor..."
  camera.write-reg 0x07 0x40  // CAM_REG_SENSOR_RESET with CAM_SENSOR_RESET_ENABLE
  camera.wait-idle
  sleep --ms=200
  
  // Try 3: Power cycle
  print "    Try 3: Power cycle..."
  camera.write-reg 0x02 0x05  // Power off
  sleep --ms=100
  camera.write-reg 0x02 0x07  // Power on
  sleep --ms=200
  
  // Try 4: Clear any pending operations
  print "    Try 4: Clear FIFO and reset..."
  camera.write-reg 0x04 0x80  // Clear FIFO
  sleep --ms=50
  camera.write-reg 0x04 0x00  // Normal FIFO mode
  sleep --ms=50
  
  print "    Fix attempts complete."
