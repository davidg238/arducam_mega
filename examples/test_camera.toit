// Copyright 2024 Ekorau LLC
// Simple ArduCam test for ESP32 hardware

import arducam_mega show *
import spi
import gpio

main:
  print "Starting ArduCam hardware test..."
  
  // ESP32 SPI pins - adjust these based on your wiring
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Common ArduCam CS pins to try
  camera-cs-pins := [
    gpio.Pin 22,  // Common choice
    // gpio.Pin 5,   // Alternative
    // gpio.Pin 2,   // Alternative
    // gpio.Pin 4,   // Alternative
    // gpio.Pin 16   // Alternative
  ]
  
  camera := null
  successful-pin := null
  
  // Try each CS pin until we find one that works
  camera-cs-pins.do: | pin |
    if camera == null:
      try:
        print "\nTrying ArduCam on CS pin $pin.num..."
        test-camera := ArducamCamera --spi-bus=bus --cs=pin
        
        // Test basic SPI first before full initialization
        if test-camera.test-spi-basic:
          print "  ✓ Basic SPI test passed - attempting full initialization..."
          test-camera.on
          
          // If we get here, the camera initialized successfully
          camera = test-camera
          successful-pin = pin
          print "  ✓ ArduCam successfully initialized on CS pin $pin.num"
        else:
          print "  ✗ Basic SPI test failed - no device on this pin"
      finally: | is-exception exception |
        if is-exception:
          print "  ✗ Failed on CS pin $pin.num: $exception"
  
  if camera == null:
    print "\n❌ Could not initialize ArduCam on any CS pin"
    print "Please check your wiring and pin connections"
    return

  print "\n🎉 ArduCam detected and initialized!"
  print "Using CS pin: $successful-pin.num"
  
  // Test basic camera functionality
  print "\n--- Camera Information ---"
  if camera.camera-info:
    print "Camera type: $(camera.camera-info.camera-id)"
    print "Device address: 0x$(camera.camera-info.device-address.stringify 16)"
    print "Supports focus: $(camera.camera-info.support-focus)"
    print "Supports sharpness: $(camera.camera-info.support-sharpness)"
  
  print "Version info: $(camera.ver-date-and-number[0])/$(camera.ver-date-and-number[1])/$(camera.ver-date-and-number[2]) v$(camera.ver-date-and-number[3])"
  
  // Test heart beat (communication check)
  print "\n--- Communication Test ---"
  heart-beat := camera.heart-beat
  print "Heart beat: $(heart-beat ? "✓ OK" : "✗ Failed")"
  
  // Test taking a small picture
  print "\n--- Capture Test ---"
  try:
    print "Setting up for JPEG capture at QVGA resolution..."
    camera.take-picture CAM_IMAGE_MODE_QVGA CAM_IMAGE_PIX_FMT_JPG
    
    available := camera.image-available
    print "Image data available: $available bytes"
    
    if available > 0:
      // Read a small sample of the image data
      sample-size := min available 100
      sample-data := camera.read-buffer sample-size
      print "First $sample-size bytes of image data:"
      for i:=0; i < 20; i++:
        print "  [$i]: 0x$(%x sample-data[i])"  // Show first 20 bytes
      
      // Check if it looks like JPEG data (should start with 0xFF 0xD8)
      if sample-data.size >= 2 and sample-data[0] == 0xFF and sample-data[1] == 0xD8:
        print "✓ Data appears to be valid JPEG format"
      else:
        print "⚠ Data doesn't look like JPEG (expected to start with FF D8)"
    else:
      print "✗ No image data captured"
      
  finally: | is-exception exception |
    if is-exception:
      print "✗ Capture test failed: $exception"
  
  print "\n--- Test Complete ---"
  print "ArduCam test finished. Check output above for any issues."
  
  if camera and (camera.ver-date-and-number[0] == 255 or camera.ver-date-and-number[0] == 0):
    print "\n⚠️  Note: Device found on CS pin 22 but not responding like a standard ArduCam."
    print "Possible issues:"
    print "  1. Different ArduCam model requiring different protocol"
    print "  2. Wrong device type (not an ArduCam)"
    print "  3. ArduCam in wrong mode or not fully initialized"
    print "  4. Check ArduCam model number and compare with supported types"
    print "\nTry checking physical device markings for model identification."
