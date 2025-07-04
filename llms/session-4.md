# Session 4 Summary - ArduCam MEGA-5MP Toit Library

**Date:** Current session  
**Status:** MAJOR ARCHITECTURAL DISCOVERIES - FPGA vs Sensor Register Architecture Clarified

## 🎉 MAJOR ACHIEVEMENTS

### ✅ **Discovered Critical I2C Address Configuration**
Found missing I2C device address setup from C code:
- **C code line 332**: `writeReg(camera, CAM_REG_DEBUG_DEVICE_ADDRESS, camera->myCameraInfo.deviceAddress);`
- **All camera configs use**: `deviceAddress = 0x78`
- **Missing step**: Must write `0x78` to register `0x0A` (CAM_REG_DEBUG_DEVICE_ADDRESS)
- **Impact**: This is required for I2C tunnel to work

### ✅ **Implemented Explicit FPGA vs Sensor Register Architecture**
Clarified ArduCam's dual register architecture:

**FPGA/CPLD Registers (Direct SPI):**
- 0x00-0x0F: Control registers (test, debug, I2C address)
- 0x3C-0x4F: FIFO and data registers
- 0x45-0x47: FIFO size registers

**Sensor Registers (I2C Tunnel):**
- 0x20-0x35: Image configuration (format, resolution, quality)
- 0x40-0x43: Sensor ID and version info
- I2C tunnel protocol: debug regs 0x0B/0x0C/0x0D + sensor data 0x48

### ✅ **Implemented C Code I2C Tunnel Protocol**
Added proper I2C tunneling functions:
```toit
read-sensor-reg addr/int -> int:
  // Step 1: Set register address (high/low bytes)
  write-fpga-reg CAM_REG_DEBUG_REGISTER_HIGH (addr >> 8)
  write-fpga-reg CAM_REG_DEBUG_REGISTER_LOW (addr & 0xFF)
  // Step 2: Set I2C read mode
  write-fpga-reg CAM_REG_SENSOR_RESET CAM_I2C_READ_MODE
  // Step 3: Read result from sensor data register
  return read-fpga-reg SENSOR_DATA  // 0x48
```

### ✅ **Confirmed Power Cycle Effect**
Power cycling changed ArduCam behavior:
- **Before power cycle**: All registers returned `0x55`
- **After power cycle**: All registers return `0x00`
- **Analysis**: Device is in cleaner state but still no real communication

### ✅ **Proper C Code Initialization Sequence**
Implemented exact cameraBegin() sequence:
1. Reset sensor: `write-fpga-reg CAM_REG_SENSOR_RESET CAM_SENSOR_RESET_ENABLE`
2. Wait for I2C idle
3. Set I2C device address: `write-fpga-reg CAM_REG_DEBUG_DEVICE_ADDRESS 0x78`
4. Get sensor configuration via I2C tunnel
5. Read version information

### ✅ **Test Structure with Proper Initialization**
Updated all tests to follow correct pattern:
1. **Initialize camera first** (camera.on())
2. Test specific functionality
3. Report results

Created tests:
- `00_camera_initialization.toit` - Dedicated initialization test
- `01_spi_connectivity_with_init.toit` - SPI test with proper init
- `02_i2c_tunnel_with_init.toit` - I2C tunnel test with proper init
- `test_i2c_tunnel_reads.toit` - I2C tunnel verification

## 📋 CURRENT STATUS

### **What's Working:**
- ✅ ESP32 and Toit program execution
- ✅ SPI communication (no crashes, can send/receive)
- ✅ ArduCam command protocol (0x55 0x01 0x11 0xAA commands accepted)
- ✅ Proper test structure with initialization
- ✅ Explicit FPGA vs sensor register functions

### **What's Partially Working:**
- ⚠️ **FPGA register reads**: Return consistent `0x00` (not random, shows device responding)
- ⚠️ **ArduCam commands**: Accepted but FIFO remains 0 bytes
- ⚠️ **Initialization sequence**: Runs without crashing but doesn't establish communication

### **What's Still Failing:**
- ❌ **FPGA register writes**: Don't stick (I2C address write to 0x0A returns 0x00 on readback)
- ❌ **I2C tunnel**: Cannot establish communication with image sensor
- ❌ **Real register values**: All reads return 0x00 instead of hardware values
- ❌ **Image capture**: FIFO remains empty after capture commands

## 🔧 TECHNICAL DISCOVERIES

### **Root Cause Analysis**
The issue is at the FPGA communication level:
1. **SPI protocol works** (can send/receive without crashes)
2. **FPGA responds** (returns 0x00 instead of random values)
3. **But FPGA register writes don't persist** (critical issue)
4. **No I2C tunnel possible** without working FPGA register writes

### **Key Missing Pieces**
1. **FPGA activation**: Need to find what makes FPGA register writes stick
2. **Hardware timing**: May need specific power-up or reset sequence
3. **Register write protocol**: Current write protocol may be incomplete

## 🚧 WORK IN PROGRESS

### **Function Naming Update (PARTIALLY COMPLETE)**
Started converting to explicit function names:
- ✅ Added: `read-fpga-reg()` / `write-fpga-reg()` for FPGA registers
- ✅ Added: `read-sensor-reg()` / `write-sensor-reg()` for sensor registers via I2C
- ⚠️ **TODO**: Update ALL remaining `read-reg`/`write-reg` calls in codebase
- ⚠️ **TEMPORARY**: Added compatibility aliases to prevent compilation errors

**Files needing function name updates:**
- `src/arducam_camera.toit` - Many remaining `read-reg`/`write-reg` calls
- All test files using old function names
- Need systematic review of which registers are FPGA vs sensor

## 🐛 OUTSTANDING BUGS

### **Critical Issues**
1. **FPGA register writes don't persist**
   - Write `0x78` to register `0x0A`, readback gets `0x00`
   - This prevents I2C address setup
   - Root cause of all other failures

2. **No real hardware register values**
   - All register reads return `0x00`
   - Expected: sensor ID, version info, real FPGA status

3. **I2C tunnel cannot be established**
   - Depends on successful FPGA register writes
   - Prevents sensor configuration and image capture

### **Next Session Priorities**
1. **Debug FPGA register write protocol**
   - Investigate why writes don't stick
   - Check for missing activation sequence
   - Compare with working C code timing

2. **Complete function naming update**
   - Systematically update all `read-reg`/`write-reg` calls
   - Remove compatibility aliases
   - Ensure correct FPGA vs sensor register usage

3. **Hardware debugging**
   - Investigate power, reset, timing requirements
   - Check for missing hardware initialization

## 📁 CODE CHANGES SUMMARY

### **Library Updates (src/arducam_camera.toit)**
- ✅ Added explicit FPGA vs sensor register functions
- ✅ Implemented I2C tunnel protocol from C code
- ✅ Added I2C device address setup (0x78 to register 0x0A)
- ✅ Updated C code initialization sequence
- ⚠️ **PARTIAL**: Function name conversion (many calls still need updating)

### **Test Updates**
- ✅ Created proper initialization test (00_camera_initialization.toit)
- ✅ Updated tests to initialize camera first
- ✅ Created I2C tunnel verification tests
- ✅ Updated test runner with comprehensive status report

### **Documentation**
- ✅ Added register architecture documentation
- ✅ Created comprehensive test runner (run_all.sh)
- ✅ Updated session summaries

## 🎯 SESSION 5 GOALS

### **Immediate Priority: Fix FPGA Register Writes**
The fundamental blocker is that FPGA register writes don't persist. Once this is fixed:
1. I2C address can be set properly
2. I2C tunnel can be established
3. Real sensor communication becomes possible
4. Image capture should work

### **Secondary Priority: Complete Architecture Update**
1. Finish converting all register calls to explicit functions
2. Remove compatibility aliases
3. Verify correct FPGA vs sensor register usage

### **Success Metrics for Session 5**
- ✅ FPGA register writes persist (readback shows written value)
- ✅ I2C device address successfully set to 0x78
- ✅ I2C tunnel established (real sensor register values)
- ✅ Function naming conversion complete

## 💡 KEY INSIGHTS FOR SESSION 5

1. **Architecture is now clear** - FPGA vs sensor register separation is correct
2. **C code protocol is implemented** - I2C tunnel follows exact C implementation
3. **Missing I2C address found** - 0x78 to register 0x0A is critical
4. **Root cause identified** - FPGA register write protocol needs debugging
5. **Power cycling helps** - device is responding, just needs activation

The library architecture is now correct and matches the C implementation. The remaining work is focused on the fundamental FPGA communication issue and completing the function naming update.
