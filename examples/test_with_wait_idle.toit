// Test camera initialization with proper wait-idle calls like the C code

import arducam_mega show *
import spi
import gpio

main:
  print "Testing with proper wait-idle calls (like C code)..."
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  try:
    print "Creating camera..."
    camera := ArducamCamera --spi-bus=bus --cs=(gpio.Pin 22)
    
    print "\n=== CUSTOM INITIALIZATION WITH WAIT-IDLE ==="
    
    // Custom initialization sequence with proper wait-idle calls
    print "Step 1: Power control"
    camera.write-reg 0x02 0x07  // CAM_REG_POWER_CONTROL
    sleep --ms=50
    camera.wait-idle
    print "  Power set, idle wait complete"
    
    print "Step 2: Reset camera"
    camera.write-reg 0x07 0x40  // CAM_REG_SENSOR_RESET with CAM_SENSOR_RESET_ENABLE
    camera.wait-idle  // This is the missing piece!
    print "  Reset sent, idle wait complete"
    
    print "Step 3: Test basic communication"
    test-reg-before := camera.read-reg 0x00
    print "  Test reg before: 0x$(%02x test-reg-before)"
    
    camera.write-reg 0x00 0x55
    camera.wait-idle
    test-reg-after := camera.read-reg 0x00
    camera.wait-idle
    print "  Wrote 0x55, read back: 0x$(%02x test-reg-after)"
    
    if test-reg-after == 0x55:
      print "  ✓ BASIC COMMUNICATION WORKING!"
    else:
      print "  ❌ Basic communication still failed"
    
    print "Step 4: Read sensor ID with wait-idle"
    sensor-id := camera.read-reg 0x40  // CAM_REG_SENSOR_ID
    camera.wait-idle
    print "  Sensor ID: 0x$(%02x sensor-id)"
    
    print "Step 5: Read version registers with wait-idle (the failing ones!)"
    
    year-reg := camera.read-reg 0x41  // CAM_REG_YEAR_ID
    camera.wait-idle
    year := year-reg & 0x3F
    print "  Year reg: 0x$(%02x year-reg) -> year: $year"
    
    month-reg := camera.read-reg 0x42  // CAM_REG_MONTH_ID
    camera.wait-idle
    month := month-reg & 0x0F
    print "  Month reg: 0x$(%02x month-reg) -> month: $month"
    
    day-reg := camera.read-reg 0x43  // CAM_REG_DAY_ID
    camera.wait-idle
    day := day-reg & 0x1F
    print "  Day reg: 0x$(%02x day-reg) -> day: $day"
    
    version-reg := camera.read-reg 0x49  // CAM_REG_FPGA_VERSION_NUMBER
    camera.wait-idle
    version := version-reg & 0xFF
    print "  Version reg: 0x$(%02x version-reg) -> version: $version"
    
    print "\n=== RESULTS ==="
    
    if year == 0 and month == 0 and day == 0 and version == 0:
      print "❌ Version registers still all zero - wait-idle didn't fix it"
    else:
      print "✓ SUCCESS! Version registers have real values: $year/$month/$day v$version"
      
    print "\n=== HEART BEAT TEST WITH WAIT-IDLE ==="
    
    sensor-state := camera.read-reg 0x44  // CAM_REG_SENSOR_STATE
    camera.wait-idle
    heart-beat-ok := (sensor-state & 0x03) == 0x02  // CAM_REG_SENSOR_STATE_IDLE
    print "  Sensor state: 0x$(%02x sensor-state)"
    print "  Heart beat: $(heart-beat-ok ? "✓ OK" : "❌ Failed")"
    
    print "\n=== COMPARISON WITH STANDARD INIT ==="
    
    print "Now calling standard camera.on() for comparison..."
    camera.on
    
    print "After standard init, version info from camera object:"
    ver-info := camera.ver-date-and-number
    print "  Standard init result: $ver-info[0]/$ver-info[1]/$ver-info[2] v$ver-info[3]"
    
  finally: | is-exception exception |
    if is-exception:
      print "❌ Test failed: $exception"

  print "\nWait-idle test complete!"
