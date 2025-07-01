// Test and fix the heart beat function

import arducam_mega show *
import spi
import gpio

main:
  print "=== HEART BEAT FIX TEST ==="
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    
    print "\nStep 1: Test current heart beat function"
    current-result := camera.heart-beat
    print "Current heart beat: $current-result"
    
    print "\nStep 2: Test manual heart beat with embedded constants"
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    manual-result := (sensor-state & 0x03) == 0x02  // Direct constant
    print "Manual heart beat: $manual-result"
    print "Sensor state: 0x$(%02x sensor-state)"
    
    if manual-result and not current-result:
      print "\n✅ CONFIRMED: Heart beat function has a bug!"
      print "\nStep 3: Test image capture with bypassed heart beat"
      test-image-capture-bypass camera
    else:
      print "\n❌ Heart beat function seems correct, different issue"
    
  finally: | is-exception exception |
    if is-exception:
      print "Exception: $exception"
  
  print "\n=== HEART BEAT FIX TEST COMPLETE ==="

test-image-capture-bypass camera -> none:
  print "  Bypassing heart beat check and testing image capture..."
  
  try:
    print "  Setting up QVGA JPEG capture..."
    mode := 0x01  // CAM_IMAGE_MODE_QVGA
    format := 0x01  // CAM_IMAGE_PIX_FMT_JPG
    
    print "  Calling take-picture..."
    camera.take-picture mode format
    
    print "  Waiting for capture..."
    sleep --ms=1000  // Wait for capture
    
    available := camera.image-available
    print "  Image data available: $available bytes"
    
    if available > 0:
      print "  ✅ SUCCESS! Image captured with $available bytes!"
      
      if available >= 4:
        sample := camera.read-buffer 4
        print "  First 4 bytes: 0x$(%02x sample[0]) 0x$(%02x sample[1]) 0x$(%02x sample[2]) 0x$(%02x sample[3])"
        
        if sample[0] == 0xFF and sample[1] == 0xD8:
          print "  ✅ JPEG header detected! Real image data!"
        else:
          print "  ⚠️  Not JPEG format"
    else:
      print "  ❌ No image data captured"
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Image capture failed: $exception"
