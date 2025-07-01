// Test different initialization sequences

import arducam_mega show *
import spi
import gpio

main:
  print "Testing different initialization sequences..."
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Test different SPI modes and frequencies
  frequencies := [100_000, 1_000_000, 4_000_000]  // 100kHz, 1MHz, 4MHz
  modes := [0, 1, 2, 3]
  
  frequencies.do: | freq |
    modes.do: | mode |
      print "\n--- Testing SPI: $freq Hz, mode $mode ---"
      
      try:
        camera := bus.device --cs=(gpio.Pin 22) --frequency=freq --mode=mode
        
        // Test 1: Basic register test before any initialization
        print "Pre-init test:"
        test-basic-registers camera
        
        // Test 2: Try minimal initialization 
        print "Trying minimal init..."
        init-minimal camera
        test-basic-registers camera
        
        // Test 3: Try extended initialization
        print "Trying extended init..."
        init-extended camera
        test-basic-registers camera
        
        // Test 4: Try alternative initialization
        print "Trying alternative init..."
        init-alternative camera
        test-basic-registers camera
        
      finally: | is-exception exception |
        if is-exception:
          print "Error with SPI $freq Hz, mode $mode: $exception"

test-basic-registers camera -> none:
  // Test the most basic registers
  reg-00 := read-reg-safe camera 0x00  // ARDUCHIP_TEST1
  reg-01 := read-reg-safe camera 0x01  // ARDUCHIP_FRAMES
  reg-02 := read-reg-safe camera 0x02  // CAM_REG_POWER_CONTROL
  reg-07 := read-reg-safe camera 0x07  // CAM_REG_SENSOR_RESET
  
  print "  Regs: 0x00=$reg-00, 0x01=$reg-01, 0x02=$reg-02, 0x07=$reg-07"
  
  // Test write/read cycle on test register
  write-reg-safe camera 0x00 0x55
  sleep --ms=10
  readback := read-reg-safe camera 0x00
  print "  Test reg: wrote 0x55, read 0x$(%02x readback)"
  
  if readback == 0x55:
    print "  ✓ Basic SPI communication WORKING"
  else:
    print "  ❌ Basic SPI communication FAILED"

init-minimal camera -> none:
  // Minimal initialization - just power and reset
  write-reg-safe camera 0x02 0x07  // Power on
  sleep --ms=100
  write-reg-safe camera 0x07 0x40  // Reset (CAM_SENSOR_RESET_ENABLE)
  sleep --ms=200
  
init-extended camera -> none:
  // Extended initialization with longer delays
  write-reg-safe camera 0x02 0x07  // Power on
  sleep --ms=200
  write-reg-safe camera 0x07 0x40  // Reset
  sleep --ms=500  // Much longer reset delay
  write-reg-safe camera 0x07 0x00  // Release reset
  sleep --ms=200
  
init-alternative camera -> none:
  // Alternative initialization sequence
  // Try different reset patterns
  write-reg-safe camera 0x02 0x05  // Different power value
  sleep --ms=100
  write-reg-safe camera 0x02 0x07  // Power on
  sleep --ms=100
  
  // Multiple reset attempts
  write-reg-safe camera 0x07 0x80  // Different reset value
  sleep --ms=100
  write-reg-safe camera 0x07 0x00  // Release
  sleep --ms=100
  write-reg-safe camera 0x07 0x40  // Standard reset
  sleep --ms=300
  write-reg-safe camera 0x07 0x00  // Release
  sleep --ms=100

write-reg-safe camera/spi.Device reg/int val/int -> none:
  try:
    data := #[0x80 | reg, val]  // Write command: 0x80 | register, value
    camera.write data
  finally: | is-exception exception |
    if is-exception:
      print "    Write error reg 0x$(%02x reg) = 0x$(%02x val): $exception"

read-reg-safe camera/spi.Device reg/int -> int:
  try:
    cmd := #[reg & 0x7F]  // Read command: register & 0x7F
    camera.write cmd
    result := camera.read 1
    return result[0]
  finally: | is-exception exception |
    if is-exception:
      print "    Read error reg 0x$(%02x reg): $exception"
      return 0xFF
