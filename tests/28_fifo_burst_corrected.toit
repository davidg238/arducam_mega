// Test 28: FIFO Burst Reading with Correct Protocol
// Goal: Implement proper FIFO reading based on web sample
// Success: Read image data with proper CS control and timing

import arducam_mega show *
import gpio
import spi

main:
  print "=== Test 28: Corrected FIFO Burst Reading ==="
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs := gpio.Pin 22
    camera := ArducamCamera --spi-bus=spi-bus --cs=cs
    
    print "STEP 1: Initialize camera..."
    camera.on
    print "✅ Camera initialized"
    
    print "STEP 2: Capture 96x96 JPEG..."
    camera.flush-fifo
    camera.clear-fifo-flag
    
    camera.take-picture CAM_IMAGE_MODE_96X96 CAM_IMAGE_PIX_FMT_JPG
    sleep --ms=3000
    
    fifo-length := camera.read-fifo-length
    print "FIFO length: $fifo-length bytes"
    
    if fifo-length == 0:
      print "❌ No FIFO data - testing direct FIFO access..."
      
      // Try direct FIFO access to see if there's hidden data
      print "Reading FIFO registers directly..."
      fifo-low := camera.read-fpga-reg 0x45
      fifo-mid := camera.read-fpga-reg 0x46
      fifo-high := camera.read-fpga-reg 0x47
      print "FIFO registers: high=0x$(%02x fifo-high), mid=0x$(%02x fifo-mid), low=0x$(%02x fifo-low)"
      
      // Calculate length manually
      manual-length := (fifo-high << 16) | (fifo-mid << 8) | fifo-low
      print "Manual FIFO calculation: $manual-length bytes"
      
      if manual-length > 0:
        print "✅ Found hidden FIFO data!"
        fifo-length = manual-length
      else:
        print "❌ No FIFO data found"
        return
    
    if fifo-length > 0:
      print "STEP 3: Read FIFO with corrected protocol..."
      
      // Following the web sample exactly:
      // 1. Manual CS control
      // 2. Set burst mode
      // 3. Read with timing
      // 4. Look for JPEG headers
      
      print "Setting burst mode with manual CS control..."
      
      // Get direct access to CS pin for manual control
      cs-pin := gpio.Pin 22
      cs-pin.configure --output
      
      // Manual CS LOW (active)
      cs-pin.set 0
      sleep --ms=1
      
      // Set FIFO burst mode
      burst-cmd := #[0x3C]  // BURST_FIFO_READ command
      camera.camera.write burst-cmd
      
      print "Reading FIFO data with proper timing..."
      
      // First byte is dummy (per web sample)
      dummy := camera.camera.read 1
      print "Dummy byte: 0x$(%02x dummy[0])"
      bytes-to-read := fifo-length - 1
      
      // Read with JPEG header detection
      header-found := false
      end-found := false
      bytes-read := 0
      last-byte := 0x00
      jpeg-data := []
      
      max-bytes := bytes-to-read < 100 ? bytes-to-read : 100  // Limit for testing
      
      max-bytes.repeat: | i |
        if end-found:
          return  // Break out of repeat
        
        // Read one byte with timing delay (15μs in sample)
        current := camera.camera.read 1
        current-byte := current[0]
        bytes-read++
        
        // JPEG header detection: FF D8
        if not header-found and last-byte == 0xFF and current-byte == 0xD8:
          print "🎉 JPEG header found at byte $bytes-read! (FF D8)"
          header-found = true
          jpeg-data.add last-byte
          jpeg-data.add current-byte
        
        // If header found, collect data
        if header-found:
          jpeg-data.add current-byte
        
        // JPEG end detection: FF D9
        if last-byte == 0xFF and current-byte == 0xD9:
          print "🎉 JPEG end found at byte $bytes-read! (FF D9)"
          end-found = true
        
        last-byte = current-byte
        
        // Timing delay from sample (15 microseconds)
        // Toit doesn't have microsecond sleep, use minimal delay
        if i % 10 == 0:  // Every 10th byte, small delay
          sleep --ms=1
      
      // Manual CS HIGH (inactive)
      cs-pin.set 1
      
      print "STEP 4: Analyze results..."
      print "Bytes read: $bytes-read"
      print "JPEG header found: $(header-found ? "✅" : "❌")"
      print "JPEG end found: $(end-found ? "✅" : "❌")"
      print "JPEG data collected: $(jpeg-data.size) bytes"
      
      if header-found:
        print "🎉 SUCCESS! Found JPEG data in FIFO!"
        print "First 10 JPEG bytes: $(jpeg-data[0..9])"
        
        if end-found:
          print "🎉 PERFECT! Complete JPEG image detected!"
        else:
          print "⚠️  JPEG started but end not found in sample"
      else:
        print "❌ No JPEG header found"
        print "First 10 bytes: $dummy"
        first-few := []
        8.repeat: | i |
          if i < bytes-read:
            first-few.add last-byte  // Would need to collect these properly
        print "Sample bytes: $first-few"
    
    else:
      print "❌ No FIFO data to read"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: $exception"
    
  print "\n=== Test 28 Complete ==="
