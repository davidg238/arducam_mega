// Copyright 2024 Ekorau LLC
// Modified ArduCam test using capture.toit initialization technique

import arducam_mega show *
import spi
import gpio

main:
  print "Starting ArduCam hardware test (using capture.toit technique)..."
  
  // ESP32 SPI pins - same as capture.toit
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Try CS pins like capture.toit does
  camera-cs-pins := [gpio.Pin 22, gpio.Pin 2, gpio.Pin 4, gpio.Pin 16]
  
  camera := null
  successful-pin := null
  
  // Use capture.toit initialization approach
  camera-cs-pins.do: | pin |
    if camera == null:
      try:
        print "Trying camera CS pin $pin.num"
        test-camera := ArducamCamera --spi-bus=bus --cs=pin
        test-camera.on  // Direct initialization like capture.toit
        // If we get here without exception, camera initialized successfully
        camera = test-camera
        successful-pin = pin
        print "Camera successfully initialized on CS pin $pin.num"
      finally: | is-exception exception |
        if is-exception:
          print "Failed on CS pin $pin.num: $exception"
  
  if camera == null:
    print "Could not initialize camera on any CS pin"
    return

  print "\n🎉 ArduCam detected and initialized using capture.toit technique!"
  print "Using CS pin: $successful-pin.num"
  
  // Test basic camera functionality
  print "\n--- Camera Information ---"
  try:
    if camera.camera-info:
      print "Camera type: $(camera.camera-info.camera-id)"
      print "Device address: 0x$(camera.camera-info.device-address.stringify 16)"
      print "Supports focus: $(camera.camera-info.support-focus)"
      print "Supports sharpness: $(camera.camera-info.support-sharpness)"
    
    print "Version info: $(camera.ver-date-and-number[0])/$(camera.ver-date-and-number[1])/$(camera.ver-date-and-number[2]) v$(camera.ver-date-and-number[3])"
  finally: | is-exception exception |
    if is-exception:
      print "Error getting camera info: $exception"
  
  // Test heart beat (communication check)
  print "\n--- Communication Test ---"
  try:
    heart-beat := camera.heart-beat
    print "Heart beat: $(heart-beat ? "✓ OK" : "✗ Failed")"
  finally: | is-exception exception |
    if is-exception:
      print "Heart beat test failed: $exception"
  
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
        print "  [$i]: 0x$(%02x sample-data[i])"  // Show first 20 bytes
      
      // Check if it looks like JPEG data (should start with 0xFF 0xD8)
      if sample-data.size >= 2 and sample-data[0] == 0xFF and sample-data[1] == 0xD8:
        print "✓ Data appears to be valid JPEG format"
      else:
        print "⚠ Data doesn't look like JPEG (expected to start with FF D8)"
        print "  First two bytes: 0x$(%02x sample-data[0]) 0x$(%02x sample-data[1])"
    else:
      print "✗ No image data captured"
      
  finally: | is-exception exception |
    if is-exception:
      print "✗ Capture test failed: $exception"
  
  print "\n--- Test Complete ---"
  print "ArduCam test finished using capture.toit initialization technique."
