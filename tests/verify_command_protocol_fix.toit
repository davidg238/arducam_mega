// CRITICAL TEST: Verify Session 2 Command Protocol Fix

import arducam_mega show *
import spi
import gpio

main:
  print "=== VERIFYING COMMAND PROTOCOL FIX ==="
  print "Testing Session 2 breakthrough implementation..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    print "✅ Camera object created"
    
    // Test new simplified initialization
    print "\nTesting new initialization (no I2C tunnel dependency)..."
    camera.on
    print "✅ Initialization complete"
    
    // Test new command protocol for JPEG
    print "\nTesting ArduCam command protocol..."
    print "Taking JPEG picture with command protocol..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    print "✅ Command protocol picture taken"
    
    // Check image data
    image-size := camera.image-available
    print "\nImage size: $image-size bytes"
    
    if image-size == 0:
      print "❌ No image data - command protocol may need adjustment"
      return
    
    // Read header to check for JPEG
    print "\nReading image header..."
    header := camera.read-buffer 50
    print "First 10 bytes:"
    for i := 0; i < 10 and i < header.size; i++:
      print "  [$i]: 0x$(%02x header[i])"
    
    // Check for JPEG header
    if header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8:
      print "\n🎉 🎉 🎉 SUCCESS! JPEG HEADER FOUND! 🎉 🎉 🎉"
      print "\n✅ SESSION 2 COMMAND PROTOCOL FIX SUCCESSFUL!"
      print "✅ ArduCam MEGA JPEG format is now working!"
      print "✅ Critical fix has been applied correctly!"
    else:
      print "\n⚠️  No JPEG header yet - may need parameter adjustment"
      print "  Expected: 0xFF 0xD8"
      print "  Got: 0x$(%02x header[0]) 0x$(%02x header[1])"
      
      if header[0] != 0x55:
        print "  ✅ PROGRESS: No longer getting 0x55 pattern!"
        print "  ✅ Command protocol is having effect!"
      else:
        print "  ❌ Still getting 0x55 - need further investigation"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== COMMAND PROTOCOL FIX VERIFICATION COMPLETE ==="
