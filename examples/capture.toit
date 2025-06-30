// Copyright 2024 Ekorau LLC

import arducam_mega show *
import host.file
import .sdcard

import spi
import gpio


main:
  bus := spi.Bus
        --miso=gpio.Pin 19
        --mosi=gpio.Pin 23
        --clock=gpio.Pin 18

  sdcard := SDCard 
      --spi-bus=bus
      --cs=gpio.Pin 5

  // Try a few common CS pins for ArduCam
  camera-cs-pins := [gpio.Pin 15, gpio.Pin 2, gpio.Pin 4, gpio.Pin 16]
  
  camera := null
  
  camera-cs-pins.do: | pin |
    if camera == null:
      try:
        print "Trying camera CS pin $pin.num"
        test-camera := ArducamCamera --spi-bus=bus --cs=pin
        test-camera.on
        // If we get here without exception, camera initialized successfully
        camera = test-camera
        print "Camera successfully initialized on CS pin $pin.num"
      finally: | is-exception exception |
        if is-exception:
          print "Failed on CS pin $pin.num: $exception"
  
  if camera == null:
    print "Could not initialize camera on any CS pin"
    return

  // Test SD card functionality
  filename := "hello.txt"
  try:
    filer := sdcard.openr "/sd/$filename"
    content := filer.read
    filer.close
    print "/sd/$filename contents  ---------------------------------------------"
    print content.to-string
    print "-----------------------------------------------------------------"
  finally: | is-exception exception |
    if is-exception:
      print "Error reading file: $exception"
  
  // List SD card contents
  try:
    files := file.list-directory "/sd"
    files.do: print it
  finally: | is-exception exception |
    if is-exception:
      print "Error listing directory: $exception"