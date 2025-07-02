// Test the EXACT protocol from commit 61e0c08 that achieved "full SPI communication"

import spi
import gpio

main:
  print "=== TESTING EXACT BREAKTHROUGH PROTOCOL ==="
  print "Using the exact protocol from commit 61e0c08"
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  camera := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
  
  print "\n1. Testing the exact breakthrough read-reg protocol:"
  test-breakthrough-protocol camera
  
  print "\n2. Testing sensor ID (register 0x40):"
  sensor-id := read-reg-breakthrough camera 0x40
  print "  Sensor ID: 0x$(%02x sensor-id)"
  if sensor-id != 0x55 and sensor-id != 0xFF:
    print "  ⭐ SUCCESS: Got non-standard value! Possible real hardware response."
  
  print "\n3. Testing multiple important registers:"
  important-regs := [
    [0x00, "Test register"],
    [0x40, "Sensor ID"],
    [0x41, "Year ID"],
    [0x42, "Month ID"], 
    [0x43, "Day ID"],
    [0x44, "Sensor state"],
  ]
  
  important-regs.do: | reg-info |
    addr := reg-info[0]
    name := reg-info[1]
    value := read-reg-breakthrough camera addr
    print "  Reg 0x$(%02x addr) ($name): 0x$(%02x value)"
  
  print "\n=== BREAKTHROUGH PROTOCOL TEST COMPLETE ==="

// Exact replication of the breakthrough protocol from commit 61e0c08
read-reg-breakthrough device addr/int -> int:
  // Try exactly what C code does: separate transfers for each byte
  sleep --ms=1
  
  // Step 1: Send address
  device.write #[addr & 0x7F]  // Ensure read bit clear
  dummy1 := device.read 1
  
  // Step 2: Send first dummy, get first response
  device.write #[0x00]
  dummy2 := device.read 1
  
  // Step 3: Send second dummy, get real data
  device.write #[0x00]
  result := device.read 1
  
  sleep --ms=1
  
  return result[0]  // This should be the real data

test-breakthrough-protocol device -> none:
  print "  Testing breakthrough protocol step by step:"
  
  // Test with register 0x40 (sensor ID)
  addr := 0x40
  
  print "    Step 1: Send address 0x$(%02x addr & 0x7F)"
  device.write #[addr & 0x7F]
  dummy1 := device.read 1
  print "      Dummy1 response: 0x$(%02x dummy1[0])"
  
  sleep --ms=1
  
  print "    Step 2: Send first dummy (0x00)"
  device.write #[0x00]
  dummy2 := device.read 1
  print "      Dummy2 response: 0x$(%02x dummy2[0])"
  
  sleep --ms=1
  
  print "    Step 3: Send second dummy (0x00)"
  device.write #[0x00]
  result := device.read 1
  print "      FINAL result: 0x$(%02x result[0]) ← This should be sensor ID"
  
  sleep --ms=1
  
  // Expected sensor ID for ArduCam MEGA-5MP is around 0x81
  if result[0] == 0x81:
    print "    ⭐ PERFECT! Got expected MEGA-5MP sensor ID!"
  else if result[0] != 0x55 and result[0] != 0xFF and result[0] != 0x00:
    print "    ⭐ INTERESTING: Got unexpected but valid value 0x$(%02x result[0])"
  else:
    print "    ❌ Still getting standard no-device response"
