// Test 7: Arduino SPI Exact Replication
// Goal: Replicate exact Arduino SPI behavior including timing and CS control
// Success: Match Arduino library behavior exactly

import gpio
import spi

main:
  print "=== Test 7: Arduino SPI Exact Replication ==="
  print "Goal: Replicate exact Arduino SPI.transfer() behavior"
  
  try:
    spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
    cs-pin := gpio.Pin 22
    
    // Test different SPI configurations that Arduino might use
    configs := [
      [1_000_000, 0],  // Arduino default: 1MHz, Mode 0
      [4_000_000, 0],  // Arduino common: 4MHz, Mode 0  
      [8_000_000, 0],  // Arduino fast: 8MHz, Mode 0
      [1_000_000, 1],  // Try Mode 1
      [1_000_000, 2],  // Try Mode 2
      [1_000_000, 3],  // Try Mode 3
    ]
    
    configs.do: | config |
      freq := config[0]
      mode := config[1]
      
      print "\nTesting config: $(freq/1000)kHz, Mode $mode"
      device := spi-bus.device --cs=cs-pin --frequency=freq --mode=mode
      
      // Arduino cameraBusRead exact replication:
      // arducamSpiCsPinLow(csPin);
      // arducamSpiTransfer(address);
      // value = arducamSpiTransfer(0x00);
      // value = arducamSpiTransfer(0x00);
      // arducamSpiCsPinHigh(csPin);
      
      // Test sensor ID read with exact Arduino timing
      device.write #[0x40]  // First transfer: address
      response1 := device.read 1
      
      device.write #[0x00]  // Second transfer: dummy
      response2 := device.read 1
      
      device.write #[0x00]  // Third transfer: dummy
      response3 := device.read 1
      
      print "  Separate transfers: $response1, $response2, $response3"
      
      // Try the combined approach too
      device.write #[0x40, 0x00, 0x00]
      combined := device.read 3
      print "  Combined transfer: $combined"
      
      // Check if we got the expected sensor ID
      sensor-id := response3[0]  // Arduino takes the third transfer result
      if sensor-id == 0x56:
        print "  🎉 SUCCESS! Sensor ID 0x56 found with $(freq/1000)kHz, Mode $mode"
        return
      else:
        print "  Sensor ID: 0x$(%02x sensor-id) (expected 0x56)"
    
    // Try with explicit microsecond delays like Arduino
    print "\nTrying with Arduino-style microsecond delays..."
    device := spi-bus.device --cs=cs-pin --frequency=1_000_000 --mode=0
    
    // Arduino often has small delays between transfers
    device.write #[0x40]
    sleep --ms=1  // Small delay
    response1 := device.read 1
    
    sleep --ms=1
    device.write #[0x00]
    response2 := device.read 1
    
    sleep --ms=1  
    device.write #[0x00]
    response3 := device.read 1
    
    print "  With μs delays: $response1, $response2, $response3"
    sensor-id := response3[0]
    print "  Sensor ID with delays: 0x$(%02x sensor-id)"
    
    // Try the power cycling approach
    print "\nTrying power cycle simulation..."
    
    // Rapid CS pin toggling might reset the device state
    10.repeat:
      device.write #[0x00]  // Dummy transaction
      sleep --ms=1
    
    // Now try reading
    device.write #[0x40, 0x00, 0x00]
    response := device.read 3
    sensor-id = response[2]
    print "  After CS cycling: 0x$(%02x sensor-id)"
    
    // Try different register addresses to see if pattern changes
    print "\nTesting different registers after CS cycling..."
    test-regs := [0x00, 0x01, 0x40, 0x41, 0x42, 0x43, 0x49]
    
    test-regs.do: | reg |
      device.write #[reg, 0x00, 0x00]
      response = device.read 3
      value := response[2]
      print "  Register 0x$(%02x reg): 0x$(%02x value) (full: $response)"
    
    print "\nAnalysis:"
    print "- Arduino SPI.transfer() does individual byte transfers with CS held low"
    print "- Our combined transfers might not match Arduino behavior exactly"
    print "- Different SPI modes/frequencies might be needed"
    print "- Device might need specific timing between transfers"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ FAILED: Arduino SPI test failed: $exception"
    
  print "\n=== Test 7 Complete ==="
