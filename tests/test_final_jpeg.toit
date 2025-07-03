// Final test with write fix - check for JPEG headers

import arducam_mega show *
import spi
import gpio

main:
  print "=== FINAL JPEG TEST WITH WRITE FIX ==="
  print "Testing with corrected write protocol..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    // Initialize camera
    print "\nInitializing camera..."
    camera.on
    print "✅ Camera initialized"
    
    // Test direct register access first
    print "\nTesting register access..."
    state-reg := camera.read-reg 0x44
    format-reg := camera.read-reg 0x20
    sensor-id := camera.read-reg 0x40
    
    print "  Sensor state: 0x$(%02x state-reg)"
    print "  Format reg: 0x$(%02x format-reg)"
    print "  Sensor ID: 0x$(%02x sensor-id)"
    
    // If we're still getting 0x55, the issue persists
    if state-reg == 0x55 and format-reg == 0x55 and sensor-id == 0x55:
      print "  ⚠️  Still getting 0x55 pattern - write fix didn't resolve the issue"
      print "  ⚠️  This suggests a deeper SPI communication problem"
    else:
      print "  ✅ Getting varied register values - SPI communication improved!"
    
    // Try taking a picture anyway
    print "\nTaking JPEG picture..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Picture taken"
    
    // Check image size
    image-size := camera.image-available
    print "\nImage size: $image-size bytes"
    
    if image-size == 0:
      print "❌ No image data available"
      return
    
    // Read header
    print "\nReading image header..."
    header := camera.read-buffer 50
    print "\nFirst 20 bytes:"
    for i := 0; i < 20 and i < header.size; i++:
      print "  [$i]: 0x$(%02x header[i])"
    
    // Check for JPEG header
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "\n🎉 🎉 🎉 SUCCESS! JPEG HEADER FOUND! 🎉 🎉 🎉"
      print "✅ ArduCam MEGA JPEG format is WORKING!"
      print "✅ Write protocol fix was successful!"
    else:
      print "\n❌ No JPEG header found"
      print "  Expected: 0xFF 0xD8"
      print "  Got: 0x$(%02x header[0]) 0x$(%02x header[1])"
      
      if header[0] == 0x55:
        print "  ⚠️  Still 0x55 pattern - may need more fundamental fixes"
      else:
        print "  ⚠️  Different pattern - progress made but not JPEG yet"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== FINAL JPEG TEST COMPLETE ==="
