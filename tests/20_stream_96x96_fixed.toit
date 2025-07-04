// Test 20: Stream 96x96 Image Test
// Goal: Stream image data to avoid memory constraints and check JPEG headers
// Success: Stream image data and verify JPEG format

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 20: Stream 96x96 Image Test ==="
  print "Goal: Stream image data to avoid memory constraints"
  
  streaming-started := false
  total-bytes-read := 0
  jpeg-header-found := false
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "\n=== Phase 1: Initialize Camera ==="
    camera.on
    print "✅ Camera initialized"
    
    print "\n=== Phase 2: Start Streaming Mode ==="
    
    // Clear FIFO first
    camera.flush-fifo
    camera.clear-fifo-flag
    
    print "Starting streaming mode for 96x96..."
    
    // Use start-preview for streaming (if available)
    try:
      camera.start-preview CAM_IMAGE_MODE_96X96
      print "✅ Streaming mode started"
      streaming-started = true
    finally: | is-exception exception |
      if is-exception:
        print "⚠️  start-preview failed: $exception"
        print "Trying alternative streaming approach..."
        streaming-started = false
    
    if not streaming-started:
      print "\n=== Alternative: Direct Streaming Commands ==="
      
      // Try direct ArduCam streaming commands
      // Command 0x02 is for streaming mode according to protocol
      stream-cmd := #[0x55, 0x02, 0x0A, 0xAA]  // Stream mode + 96x96
      print "Sending direct stream command: $stream-cmd"
      camera.camera.write stream-cmd
      sleep --ms=500
      
      streaming-started = true
    
    if streaming-started:
      print "\n=== Phase 3: Read Streaming Data ==="
      
      // Read data in small chunks to examine headers
      print "Reading streaming data in chunks..."
      
      chunk-count := 0
      
      10.repeat: | chunk-num |
        print "\n--- Chunk $(chunk-num + 1) ---"
        
        // Check FIFO status
        fifo-length := camera.read-fifo-length
        print "FIFO length: $fifo-length bytes"
        
        if fifo-length > 0:
          // Set burst mode for efficient reading
          camera.set-fifo-burst
          
          // Read a small chunk (16 bytes)
          chunk-data := []
          bytes-to-read := fifo-length < 16 ? fifo-length : 16
          
          bytes-to-read.repeat: | i |
            try:
              byte := camera.read-byte
              chunk-data.add byte
              total-bytes-read++
            finally: | is-exception exception |
              if is-exception:
                print "  Error reading byte $i: $exception"
                return  // Exit the repeat loop
          
          if chunk-data.size > 0:
            print "  Read $(chunk-data.size) bytes: $chunk-data"
            
            // Check for JPEG header at start of chunk
            if chunk-data.size >= 2 and chunk-data[0] == 0xFF and chunk-data[1] == 0xD8:
              print "  🎉 JPEG header found! (FF D8)"
              jpeg-header-found = true
            
            // Check for JPEG end marker
            if chunk-data.size >= 2:
              (chunk-data.size - 1).repeat: | i |
                if chunk-data[i] == 0xFF and chunk-data[i + 1] == 0xD9:
                  print "  🎉 JPEG end marker found! (FF D9)"
            
            // Look for other JPEG markers
            chunk-data.size.repeat: | i |
              byte := chunk-data[i]
              if byte == 0xFF and i + 1 < chunk-data.size:
                next-byte := chunk-data[i + 1]
                if next-byte != 0x00 and next-byte != 0xFF:
                  print "  📷 JPEG marker: FF $(%02x next-byte)"
          else:
            print "  No data read from FIFO"
        else:
          print "  FIFO empty"
          
          if chunk-num == 0:
            print "  Waiting for data generation..."
            sleep --ms=1000
          else:
            // No more data after first chunk
            return  // Exit the repeat loop
        
        sleep --ms=200  // Small delay between chunks
      
      print "\n=== Phase 4: Streaming Results ==="
      print "Total bytes read: $total-bytes-read"
      print "JPEG header found: $(jpeg-header-found ? "✅" : "❌")"
      
      if total-bytes-read > 0:
        print "✅ Streaming is working!"
        
        if jpeg-header-found:
          print "🎉 SUCCESS! Camera is producing JPEG data!"
          print "   Image capture mechanism is working correctly"
        else:
          print "⚠️  Data captured but no JPEG header"
          print "   May be different format or need format configuration"
      else:
        print "❌ No streaming data captured"
    
    print "\n=== Phase 5: Try Single Shot with Immediate Read ==="
    
    // Alternative: capture single image and read immediately in small chunks
    print "Trying single shot with immediate streaming read..."
    
    camera.flush-fifo
    camera.clear-fifo-flag
    
    print "Capturing 96x96 JPEG..."
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    
    // Read immediately without waiting for completion
    print "Reading data immediately as it's generated..."
    
    immediate-total := 0
    immediate-jpeg-found := false
    
    5.repeat: | read-attempt |
      sleep --ms=500  // Short wait
      
      fifo-now := camera.read-fifo-length
      print "  Attempt $(read-attempt + 1): FIFO = $fifo-now bytes"
      
      if fifo-now > 0:
        camera.set-fifo-burst
        
        // Read available data (max 32 bytes per attempt)
        bytes-available := fifo-now < 32 ? fifo-now : 32
        attempt-data := []
        
        bytes-available.repeat: | i |
          try:
            byte := camera.read-byte
            attempt-data.add byte
            immediate-total++
          finally: | is-exception exception |
            if is-exception:
              return  // Exit repeat loop
        
        if attempt-data.size > 0:
          print "    Read $(attempt-data.size) bytes: first few: $(attempt-data[0]) $(attempt-data[1]) $(attempt-data[2]) $(attempt-data[3])"
          
          // Check for JPEG header
          if attempt-data.size >= 2 and attempt-data[0] == 0xFF and attempt-data[1] == 0xD8:
            print "    🎉 JPEG header found in immediate read!"
            immediate-jpeg-found = true
        
        if fifo-now <= 32:
          return  // Exit repeat - read all available data
    
    print "\n=== Final Summary ==="
    print "Streaming total: $total-bytes-read bytes, JPEG header: $(jpeg-header-found ? "✅" : "❌")"
    print "Immediate total: $immediate-total bytes, JPEG header: $(immediate-jpeg-found ? "✅" : "❌")"
    
    overall-success := total-bytes-read > 0 or immediate-total > 0
    jpeg-success := jpeg-header-found or immediate-jpeg-found
    
    if overall-success:
      print "🎉 SUCCESS! Image data capture is working!"
      
      if jpeg-success:
        print "   JPEG format confirmed - camera fully functional!"
      else:
        print "   Data format needs investigation"
    else:
      print "❌ No image data captured in any mode"
      print "   Need to investigate capture trigger mechanism"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Stream test failed: $exception"
    
  print "\n=== Test 20 Complete ==="
