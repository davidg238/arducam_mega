// 03: ArduCam command protocol test

import arducam_mega show *
import spi
import gpio

main:
  print "=== 03: COMMAND PROTOCOL ==="
  print "Testing ArduCam high-level command protocol..."
  
  try:
    bus := spi.Bus
          --miso=gpio.Pin 19
          --mosi=gpio.Pin 23
          --clock=gpio.Pin 18

    device := bus.device --cs=(gpio.Pin 22) --frequency=1_000_000 --mode=0
    print "✅ SPI device created"
    
    print "\nTesting ArduCam command format: 0x55 [CMD] [PARAM] 0xAA"
    
    // Test JPEG format command
    print "  Sending JPEG format command..."
    jpeg-cmd := #[0x55, 0x01, 0x11, 0xAA]  // format=1 (JPEG), resolution=1 (QVGA)
    device.write jpeg-cmd
    sleep --ms=100
    print "    ✅ JPEG format command sent: $(%02x jpeg-cmd[0]) $(%02x jpeg-cmd[1]) $(%02x jpeg-cmd[2]) $(%02x jpeg-cmd[3])"
    
    // Test capture command  
    print "  Sending capture command..."
    capture-cmd := #[0x55, 0x10, 0xAA]
    device.write capture-cmd
    sleep --ms=1000
    print "    ✅ Capture command sent: $(%02x capture-cmd[0]) $(%02x capture-cmd[1]) $(%02x capture-cmd[2])"
    
    // Test FIFO status
    print "\nChecking FIFO after commands..."
    fifo-cmd := #[0x45 & 0x7F, 0x00, 0x00]  // FIFO size register
    device.write fifo-cmd
    fifo-resp := device.read 3
    fifo-val := fifo-resp[2]
    print "  FIFO size register: 0x$(%02x fifo-val)"
    
    if fifo-val != 0x55:
      print "  ✅ FIFO responding - command protocol may be working"
    else:
      print "  ⚠️  FIFO still returning 0x55"
    
    device.close
        
  finally: | is-exception exception |
    if is-exception:
      print "\n❌ Exception: $exception"
  
  print "\n=== 03: COMMAND PROTOCOL COMPLETE ==="
