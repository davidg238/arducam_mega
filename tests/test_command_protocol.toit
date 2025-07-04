import gpio
import spi
import system

class ArducamCamera:
  cs  /gpio.Pin
  spi-bus / spi.Bus
  camera /spi.Device

  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin:
    camera = spi-bus.device --cs=cs --frequency=1_000_000 --mode=0

  // High-level command protocol: 0x55 [CMD] [PARAM] 0xAA
  send-command cmd/int param/int -> none:
    command := #[0x55, cmd, param, 0xAA]
    print "Sending command: $command"
    camera.write command
    sleep --ms=10

  // Test the sensor reset command
  reset-sensor -> none:
    // Based on C code: writeReg(camera, CAM_REG_SENSOR_RESET, CAM_SENSOR_RESET_ENABLE)
    // CAM_REG_SENSOR_RESET = 0x07, CAM_SENSOR_RESET_ENABLE = 0x40
    command := #[0x07 | 0x80, 0x40]  // Write 0x40 to register 0x07
    print "Sending sensor reset: $command"
    camera.write command
    sleep --ms=100  // Wait for reset

  // Basic register read
  read-register addr/int -> int:
    command := #[addr & 0x7F, 0x00, 0x00]
    camera.write command
    responses := camera.read 3
    sleep --ms=1
    return responses[2]

main:
  print "=== High-Level Command Protocol Test ==="
  
  // Initialize SPI and camera
  spi-bus := spi.Bus --mosi=(gpio.Pin 23) --miso=(gpio.Pin 19) --clock=(gpio.Pin 18)
  cs := gpio.Pin 22
  camera := ArducamCamera --spi-bus=spi-bus --cs=cs
  
  print "\n1. Testing sensor reset..."
  camera.reset-sensor
  
  print "\n2. Testing basic register read..."
  value := camera.read-register 0x00
  print "Register 0x00: 0x$(%02x value)"
  
  print "\n3. Testing high-level commands..."
  
  // Test format command (JPEG + VGA resolution)
  // From protocol: 0x55 0x01 [format+resolution] 0xAA
  // format: 1 (JPEG) -> bit[6:4] = 1 -> 0x10
  // resolution: 2 (VGA 640x480) -> bit[3:0] = 2 -> 0x02
  // combined: 0x10 | 0x02 = 0x12
  camera.send-command 0x01 0x12
  
  // Test capture command
  // From protocol: 0x55 0x10 0xAA (no specific parameter mentioned)
  camera.send-command 0x10 0x00
  
  print "\n4. Testing register reads after commands..."
  value = camera.read-register 0x00
  print "Register 0x00 after commands: 0x$(%02x value)"
  
  // Try to read some version registers
  version-regs := [0x41, 0x42, 0x43, 0x49]
  version-regs.do: | reg |
    value = camera.read-register reg
    print "Register 0x$(%02x reg): 0x$(%02x value)"
  
  print "\n=== Test Complete ==="
