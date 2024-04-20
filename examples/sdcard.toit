// Copyright 2024 Ekorau LLC

import flash
import gpio 
import spi
import host.file

class SDCard:
  spi-bus /spi.Bus
  cs /gpio.Pin


  constructor --.spi-bus/spi.Bus --.cs/gpio.Pin --mount_point/string="/sd":

    sdcard := flash.Mount.sdcard
        --mount_point=mount_point
        --spi_bus=spi-bus
        --cs=cs

  openw filename -> file.Stream:
    return file.Stream.for_write filename

  openr filename -> file.Stream: 
    return file.Stream.for_read filename