// Debug SPI protocol to understand what's happening

import spi
import gpio

main:
  print "=== SPI PROTOCOL DEBUG ==="
  
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  // Test direct SPI communication
  device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
  
  print "\n1. Testing direct SPI patterns:"
  test-direct-patterns device
  
  print "\n2. Testing different read protocols:"
  test-read-protocols device
  
  print "\n3. Testing register access patterns:"
  test-register-patterns device
  
  print "\n=== DEBUG COMPLETE ==="

test-direct-patterns device -> none:
  test-cases := [
    [#[0x00], "Send 0x00 (test register)"],
    [#[0x40], "Send 0x40 (sensor ID register)"],
    [#[0x44], "Send 0x44 (sensor state register)"],
    [#[0xFF], "Send 0xFF (high register)"],
    [#[0x80], "Send 0x80 (write bit set)"],
  ]
  
  test-cases.do: | test-case |
    command := test-case[0]
    description := test-case[1]
    
    try:
      device.write command
      result := device.read 3  // Read 3 bytes to see pattern
      print "  $description -> [$(%02x result[0]) $(%02x result[1]) $(%02x result[2])]"
    finally: | is-exception exception |
      if is-exception:
        print "  $description -> ERROR: $exception"
        
test-read-protocols device -> none:
  // Test different read approaches for register 0x40 (sensor ID)
  protocols := [
    "Current Toit (3 separate transfers)",
    "Single transfer with 3 bytes",
    "Address then read 1 byte",
    "Address then read 2 bytes",
  ]
  
  print "  Testing register 0x40 (sensor ID) with different protocols:"
  
  // Protocol 1: Current Toit approach (3 separate transfers)
  try:
    device.write #[0x40 & 0x7F]  // Send address
    dummy1 := device.read 1
    device.write #[0x00]         // Send first dummy
    dummy2 := device.read 1
    device.write #[0x00]         // Send second dummy
    result := device.read 1
    print "    Protocol 1: $(%02x result[0]) (current Toit)"
  finally: | is-exception exception |
    if is-exception:
      print "    Protocol 1: ERROR - $exception"
  
  // Protocol 2: Single transfer with 3 bytes
  try:
    device.write #[0x40, 0x00, 0x00]
    result := device.read 3
    print "    Protocol 2: [$(%02x result[0]) $(%02x result[1]) $(%02x result[2])] -> use byte 2: $(%02x result[2])"
  finally: | is-exception exception |
    if is-exception:
      print "    Protocol 2: ERROR - $exception"
  
  // Protocol 3: Address then read 1 byte
  try:
    device.write #[0x40]
    result := device.read 1
    print "    Protocol 3: $(%02x result[0]) (simple read)"
  finally: | is-exception exception |
    if is-exception:
      print "    Protocol 3: ERROR - $exception"
  
  // Protocol 4: Address then read 2 bytes
  try:
    device.write #[0x40]
    result := device.read 2
    print "    Protocol 4: [$(%02x result[0]) $(%02x result[1])] -> use byte 1: $(%02x result[1])"
  finally: | is-exception exception |
    if is-exception:
      print "    Protocol 4: ERROR - $exception"
      
test-register-patterns device -> none:
  // Test multiple important registers
  important-regs := [
    [0x00, "Test register"],
    [0x01, "Frames captured"],
    [0x02, "Power mode"],
    [0x40, "Sensor ID"],
    [0x41, "Sensor ID alt 1"],
    [0x42, "Sensor ID alt 2"],
    [0x44, "Sensor state"],
  ]
  
  print "  Testing multiple registers with current protocol:"
  
  important-regs.do: | reg-info |
    reg-addr := reg-info[0]
    reg-name := reg-info[1]
    
    try:
      // Use current Toit protocol
      device.write #[reg-addr & 0x7F]
      dummy1 := device.read 1
      device.write #[0x00]
      dummy2 := device.read 1
      device.write #[0x00]
      result := device.read 1
      
      print "    Reg 0x$(%02x reg-addr) ($reg-name): 0x$(%02x result[0])"
      
    finally: | is-exception exception |
      if is-exception:
        print "    Reg 0x$(%02x reg-addr) ($reg-name): ERROR - $exception"
