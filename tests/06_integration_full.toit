// 06: Full integration test with multiple formats

import arducam_mega show *
import spi
import gpio

main:
  print "=== 06: INTEGRATION FULL ==="
  print "Testing multiple image formats and resolutions..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    camera.on
    print "✅ Camera initialized"
    
    // Test different format/resolution combinations
    test-configs := [
      [CAM_IMAGE_MODE_QVGA, CAM_IMAGE_PIX_FMT_JPG, "QVGA JPEG"],
      [CAM_IMAGE_MODE_VGA, CAM_IMAGE_PIX_FMT_JPG, "VGA JPEG"],
      [CAM_IMAGE_MODE_QVGA, CAM_IMAGE_PIX_FMT_RGB565, "QVGA RGB565"]
    ]
    
    results := []
    
    test-configs.do: | config |
      mode := config[0]
      format := config[1]
      name := config[2]
      
      print "\nTesting $name..."
      
      try:
        camera.take-picture mode format
        image-size := camera.image-available
        
        if image-size > 0:
          header := camera.read-buffer 10
          is-jpeg := header.size >= 2 and header[0] == 0xFF and header[1] == 0xD8
          
          result := {
            "name": name,
            "size": image-size,
            "jpeg": is-jpeg,
            "success": true
          }
          results.add result
          
          status := is-jpeg ? "✅ JPEG" : "⚠️  Non-JPEG"
          print "  Result: $image-size bytes $status"
        else:
          results.add {"name": name, "success": false}
          print "  ❌ No image data"
          
      finally: | is-exception exception |
        if is-exception:
          print "  ❌ Exception: $exception"
          results.add {"name": name, "success": false, "error": "$exception"}
    
    // Summary
    print "\n=== INTEGRATION SUMMARY ==="
    successful := results.filter: it.get "success" == true
    jpeg-working := successful.filter: it.get "jpeg" == true
    
    print "  Total tests: $results.size"
    print "  Successful captures: $successful.size"
    print "  JPEG format working: $jpeg-working.size"
    
    if jpeg-working.size > 0:
      print "  🎉 JPEG functionality confirmed!"
    else if successful.size > 0:
      print "  ✅ Image capture working, format needs adjustment"
    else:
      print "  ❌ No successful captures"
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 06: INTEGRATION FULL COMPLETE ==="
