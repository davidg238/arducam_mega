import gpio
import spi
import system

// Copy the relevant camera code locally to avoid import issues
class ArducamCamera:
  cs  /gpio.Pin
  spi-bus / spi.Bus
  camera /spi.Device

  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin:
    camera = spi-bus.device --cs=cs --frequency=1_000_000 --mode=0

  write-fpga-reg addr/int val/int -> none:
    sleep --ms=1
    print "    Writing FPGA register 0x$(%02x addr): 0x$(%02x val)"
    camera.write #[addr | 0x80, val]
    sleep --ms=1

  read-fpga-reg addr/int -> int:
    sleep --ms=1
    command := #[addr & 0x7F, 0x00, 0x00]
    camera.write command
    responses := camera.read 3
    sleep --ms=1
    result := responses[2]
    print "    Read FPGA register 0x$(%02x addr): 0x$(%02x result) (raw: $responses)"
    return result

main:
  print "=== FPGA Register Write/Read Debug Test ==="
  
  // Initialize SPI and camera
  spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
  cs := gpio.Pin 22  // Correct CS pin based on other tests
  camera := ArducamCamera --spi-bus=spi-bus --cs=cs
  
  print "\n1. Testing register write/read cycle..."
  
  // Test 1: Try to write to a simple register first
  print "\n   Testing register 0x00 (should be safe):"
  camera.write-fpga-reg 0x00 0x55
  value := camera.read-fpga-reg 0x00
  print "   Expected: 0x55, Got: 0x$(%02x value)"
  
  // Test 2: Test the critical I2C address register
  print "\n   Testing I2C address register 0x0A:"
  camera.write-fpga-reg 0x0A 0x78
  value = camera.read-fpga-reg 0x0A
  print "   Expected: 0x78, Got: 0x$(%02x value)"
  
  // Test 3: Try different values
  print "\n   Testing different values on 0x0A:"
  test-values := [0x12, 0x34, 0x56, 0x78, 0xAB, 0xCD, 0xEF]
  test-values.do: | test-val |
    camera.write-fpga-reg 0x0A test-val
    sleep --ms=10  // Extra delay
    readback := camera.read-fpga-reg 0x0A
    status := (readback == test-val) ? "✅" : "❌"
    print "   Write 0x$(%02x test-val) -> Read 0x$(%02x readback) $status"
  
  // Test 4: Test other registers to see if it's register-specific
  print "\n   Testing other registers:"
  test-registers := [0x00, 0x01, 0x02, 0x07, 0x0A, 0x0B, 0x0C, 0x0D]
  test-registers.do: | reg |
    camera.write-fpga-reg reg 0x42
    readback := camera.read-fpga-reg reg
    status := (readback == 0x42) ? "✅" : "❌"
    print "   Reg 0x$(%02x reg): Write 0x42 -> Read 0x$(%02x readback) $status"
  
  print "\n=== Test Complete ==="
