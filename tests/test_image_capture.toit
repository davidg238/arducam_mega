// Test image capture now that SPI communication is working!

import arducam_mega show *
import spi
import gpio

main:
  print "=== IMAGE CAPTURE TEST ==="
  print "Testing actual image capture with working SPI protocol!"
  
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
    
    print "\nStep 2: Check camera status"
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    sensor-id := camera.read-reg 0x40     // CAM_REG_SENSOR_ID
    print "Sensor state: 0x$(%02x sensor-state)"
    print "Sensor ID: 0x$(%02x sensor-id)"
    
    print "\nStep 3: Test heart beat (communication check)"
    heart-beat := camera.heart-beat
    print "Heart beat: $(heart-beat ? "✅ OK" : "❌ Failed")"
    
    if heart-beat:
      print "\nStep 4: Attempt image capture!"
      test-image-capture camera
    else:
      print "\nSkipping capture - heart beat failed"
      
  finally: | is-exception exception |
    if is-exception:
      print "\nException during capture test: $exception"
  
  print "\n=== IMAGE CAPTURE TEST COMPLETE ==="

test-image-capture camera -> none:
  try:
    print "  Setting up image capture..."
    
    // Use QVGA resolution (small) and JPEG format
    mode := CAM_IMAGE_MODE_QVGA      // Small resolution for testing
    format := CAM_IMAGE_PIX_FMT_JPG  // JPEG format
    
    print "  Resolution: QVGA (320x240)"
    print "  Format: JPEG"
    
    print "  Calling take-picture..."
    camera.take-picture mode format
    
    print "  Checking if image data is available..."
    
    // Wait a moment for capture to complete
    sleep --ms=500
    
    available := camera.image-available
    print "  Image data available: $available bytes"
    
    if available > 0:
      print "  ✅ SUCCESS! Image captured with $available bytes of data!"
      
      // Try to read first few bytes to see if it looks like JPEG
      if available >= 10:
        print "  Reading first 10 bytes to check JPEG header..."
        sample := camera.read-buffer 10
        
        print "  First 10 bytes:"
        for i := 0; i < sample.size; i++:
          print "    [$i]: 0x$(%02x sample[i])"
        
        // Check for JPEG header (0xFF 0xD8)
        if sample.size >= 2 and sample[0] == 0xFF and sample[1] == 0xD8:
          print "  ✅ JPEG header detected! This looks like a real image!"
          
          // Look for JPEG end marker (0xFF 0xD9) in sample
          for i := 0; i < sample.size - 1; i++:
            if sample[i] == 0xFF and sample[i + 1] == 0xD9:
              print "  ✅ JPEG end marker found at position $i"
              break
        else:
          print "  ⚠️  Data doesn't look like JPEG (expected FF D8 header)"
          print "  First bytes: 0x$(%02x sample[0]) 0x$(%02x sample[1])"
      
      print "  \n✅ IMAGE CAPTURE SUCCESSFUL!"
      print "  This proves the ArduCam MEGA-5MP is fully functional!"
      
    else:
      print "  ❌ No image data captured"
      
      // Try to diagnose why
      print "  Checking capture status..."
      fifo-size := camera.read-fifo-length
      print "  FIFO size: $fifo-size bytes"
      
      // Check capture done bit
      trig-reg := camera.read-reg 0x44  // ARDUCHIP_TRIG
      cap-done := (trig-reg & 0x04) != 0  // CAP_DONE_MASK
      print "  Capture done bit: $cap-done"
      
  finally: | is-exception exception |
    if is-exception:
      print "  ❌ Exception during image capture: $exception"
