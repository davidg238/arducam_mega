// Simple heart beat test to isolate the bug

import arducam_mega show *
import spi
import gpio

main:
  print "=== SIMPLE HEART BEAT TEST ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    
    print "\nTesting heart beat function step by step:"
    
    // Step 1: Read the register directly
    sensor-state := camera.read-reg 0x44
    print "1. Raw sensor state: 0x$(%02x sensor-state)"
    
    // Step 2: Apply the mask
    masked := sensor-state & 0x03
    print "2. Masked (& 0x03): 0x$(%02x masked)"
    
    // Step 3: Check the constant
    idle-value := 0x02  // CAM_REG_SENSOR_STATE_IDLE
    print "3. Expected idle value: 0x$(%02x idle-value)"
    
    // Step 4: Compare
    is-equal := masked == idle-value
    print "4. Are they equal? $is-equal"
    
    // Step 5: Call the actual heart beat function
    heart-beat-result := camera.heart-beat
    print "5. Heart beat function result: $heart-beat-result"
    
    // Step 6: Manual calculation
    manual-calc := (sensor-state & 0x03) == 0x02
    print "6. Manual calculation: $manual-calc"
    
    print "\nDEBUG: If manual calc is true but heart-beat is false, there's a bug!"
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== SIMPLE HEART BEAT TEST COMPLETE ==="
