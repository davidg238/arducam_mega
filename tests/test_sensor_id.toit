import gpio
import spi
import system

class ArducamCamera:
  cs  /gpio.Pin
  spi-bus / spi.Bus
  camera /spi.Device

  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin:
    camera = spi-bus.device --cs=cs --frequency=1_000_000 --mode=0

  // Basic register read - exact copy of C code behavior
  read-register addr/int -> int:
    sleep --ms=1
    // C code: arducamSpiCsPinLow -> transfer(address) -> transfer(0x00) -> transfer(0x00) -> arducamSpiCsPinHigh
    command := #[addr & 0x7F, 0x00, 0x00]
    camera.write command
    responses := camera.read 3
    sleep --ms=1
    result := responses[2]  // C code takes 3rd byte
    return result

  // Basic register write - exact copy of C code behavior
  write-register addr/int val/int -> none:
    sleep --ms=1
    // C code: arducamSpiCsPinLow -> transfer(address | 0x80) -> transfer(value) -> arducamSpiCsPinHigh
    command := #[addr | 0x80, val]
    camera.write command
    sleep --ms=1

  // Wait for I2C idle - simplified version
  wait-i2c-idle -> none:
    sleep --ms=10

main:
  print "=== Sensor ID Test ==="
  print "Testing if ArduCam MEGA-5MP is connected and responding"
  
  // Initialize SPI and camera
  spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
  cs := gpio.Pin 22
  camera := ArducamCamera --spi-bus=spi-bus --cs=cs
  
  print "\n1. Basic register read test..."
  
  // Try to read a few different registers to see what we get
  test-registers := [0x00, 0x01, 0x07, 0x40, 0x41, 0x42, 0x43, 0x44, 0x49]
  
  test-registers.do: | reg |
    value := camera.read-register reg
    print "Register 0x$(%02x reg): 0x$(%02x value)"
  
  print "\n2. Following C code initialization sequence..."
  
  // Step 1: Reset sensor (first thing in cameraBegin)
  print "  Resetting sensor (write 0x40 to register 0x07)..."
  camera.write-register 0x07 0x40
  camera.wait-i2c-idle
  
  // Step 2: Try to read sensor ID (this is what cameraGetSensorConfig does)
  print "  Reading sensor ID from register 0x40..."
  sensor-id := camera.read-register 0x40
  print "  Sensor ID: 0x$(%02x sensor-id)"
  
  // Check if we got the expected sensor ID
  if sensor-id == 0x56:
    print "  ✅ SUCCESS: Got expected MEGA-5MP sensor ID (0x56)!"
  else if sensor-id == 0x00:
    print "  ⚠️  Got 0x00 - device responding but not communicating properly"
  else:
    print "  ⚠️  Got unexpected sensor ID: 0x$(%02x sensor-id)"
  
  print "\n3. Testing register write persistence..."
  
  // Try to write and read back to see if writes work
  print "  Testing register 0x0A (I2C address register)..."
  camera.write-register 0x0A 0x78
  camera.wait-i2c-idle
  readback := camera.read-register 0x0A
  
  if readback == 0x78:
    print "  ✅ SUCCESS: Register write persisted! 0x78 -> 0x$(%02x readback)"
  else:
    print "  ❌ FAIL: Register write did not persist! 0x78 -> 0x$(%02x readback)"
  
  print "\n4. Reading version registers..."
  
  // Try to read version information
  year := camera.read-register 0x41
  month := camera.read-register 0x42
  day := camera.read-register 0x43
  fpga-version := camera.read-register 0x49
  
  print "  Year: 0x$(%02x year) (expected: non-zero)"
  print "  Month: 0x$(%02x month) (expected: non-zero)"
  print "  Day: 0x$(%02x day) (expected: non-zero)"
  print "  FPGA Version: 0x$(%02x fpga-version) (expected: non-zero)"
  
  print "\n=== Test Complete ==="
  
  // Summary
  if sensor-id == 0x56:
    print "✅ Camera appears to be connected and responding correctly!"
  else:
    print "❌ Camera not responding with expected sensor ID"
    print "   This suggests either:"
    print "   - ArduCam not connected properly"
    print "   - ArduCam not powered"
    print "   - SPI communication issue"
    print "   - Wrong camera model connected"
