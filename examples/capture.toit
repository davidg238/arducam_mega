// Copyright 2024 Ekorau LLC

import arducam_mega show *
import encoding.json
import encoding.tison
import writer
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

  camera := ArducamCamera
      --spi-bus=bus
      --cs=gpio.Pin 99  //TODO: find the correct pin

  camera.on

  filename := "macbeth.txt"
  filer := sdcard.openw "/sd/$filename"

  print "read $filename from server"
  count := client.read filename --to-writer=(writer.Writer filer)
  filer.close
  print "Read $count bytes"

  client.close