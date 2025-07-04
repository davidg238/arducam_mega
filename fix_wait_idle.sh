#!/bin/bash

# Fix missing wait-idle calls for sensor registers (0x20-0x35)
# These registers go through I2C tunnel and need wait-idle

file="src/arducam_camera.toit"

echo "Adding wait-idle calls for sensor registers..."

# Fix CAM_REG_FORMAT (0x20) writes
sed -i '/write-fpga-reg CAM_REG_FORMAT/a\    wait-idle' "$file"

# Fix CAM_REG_CAPTURE_RESOLUTION (0x21) writes  
sed -i '/write-fpga-reg CAM_REG_CAPTURE_RESOLUTION/a\    wait-idle' "$file"

# Fix CAM_REG_AUTO_FOCUS_CONTROL (0x29) writes
sed -i '/write-fpga-reg CAM_REG_AUTO_FOCUS_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_IMAGE_QUALITY (0x2A) writes
sed -i '/write-fpga-reg CAM_REG_IMAGE_QUALITY/a\    wait-idle' "$file"

# Fix CAM_REG_BRIGHTNESS_CONTROL writes
sed -i '/write-fpga-reg CAM_REG_BRIGHTNESS_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_SATURATION_CONTROL writes
sed -i '/write-fpga-reg CAM_REG_SATURATION_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_EV_CONTROL writes  
sed -i '/write-fpga-reg CAM_REG_EV_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_CONTRAST_CONTROL writes
sed -i '/write-fpga-reg CAM_REG_CONTRAST_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_SHARPNESS_CONTROL writes
sed -i '/write-fpga-reg CAM_REG_SHARPNESS_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_WHITEBALANCE_MODE_CONTROL writes
sed -i '/write-fpga-reg CAM_REG_WHITEBALANCE_MODE_CONTROL/a\    wait-idle' "$file"

# Fix CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL writes  
sed -i '/write-fpga-reg CAM_REG_EXPOSURE_GAIN_WHITEBALANCE_CONTROL/a\    wait-idle' "$file"

# Fix manual gain/exposure register writes (0x31-0x35)
sed -i '/write-fpga-reg CAM_REG_MANUAL_GAIN_BIT_9_8/a\    wait-idle' "$file"
sed -i '/write-fpga-reg CAM_REG_MANUAL_GAIN_BIT_7_0/a\    wait-idle' "$file"
sed -i '/write-fpga-reg CAM_REG_MANUAL_EXPOSURE_BIT_19_16/a\    wait-idle' "$file"
sed -i '/write-fpga-reg CAM_REG_MANUAL_EXPOSURE_BIT_15_8/a\    wait-idle' "$file"
sed -i '/write-fpga-reg CAM_REG_MANUAL_EXPOSURE_BIT_7_0/a\    wait-idle' "$file"

echo "Fixed missing wait-idle calls for sensor registers"
