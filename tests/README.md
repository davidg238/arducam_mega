# ArduCam Mega-5MP Test Suite

## Organized Test Structure

Tests are organized in logical progression order:

### Core Tests (Run in Order)

1. **01_spi_protocol_basic.toit** - Basic SPI communication validation
2. **01_spi_connectivity.toit** - SPI hardware connectivity check  
3. **02_i2c_tunnel.toit** - **CRITICAL** I2C tunnel initialization test
4. **02_init_simple.toit** - Camera initialization test
5. **03_command_protocol.toit** - ArduCam command protocol testing
6. **04_capture_basic.toit** - Basic image capture functionality
7. **05_format_jpeg.toit** - JPEG format verification
8. **06_c_style_capture.toit** - C-style register-based capture
9. **06_integration_full.toit** - Multiple formats and resolutions

### Test Runner

**run_all.toit** - Executes all tests in dependency order
- Stops on critical test failures
- Generates comprehensive reports
- Tracks timing and success rates

### Usage

```bash
# Run individual test
jag run -d camera 01_spi_protocol_basic.toit

# Run full test suite
jag run -d camera run_all.toit

# Quick connectivity check
jag run -d camera 01_spi_connectivity.toit
```

### Test Categories

- **01_spi_*** - Low-level SPI communication tests
- **02_i2c_*** - I2C tunnel initialization (CRITICAL)
- **02_init_*** - Camera initialization and hardware detection
- **03_command_*** - ArduCam command protocol tests
- **04_capture_*** - Image capture functionality  
- **05_format_*** - Image format verification
- **06_c_style_*** - C-code style register-based approach
- **06_integration_*** - Full integration tests

### Legacy Tests

The `test_*.toit` files are legacy tests from development. The organized `0X_*.toit` tests replace them with better structure.

## Expected Results

With working hardware:
- Tests 01: Should pass (basic SPI communication)
- **Test 02_i2c_tunnel: CRITICAL** - Must pass for anything else to work
- Test 02_init: Should pass (camera initialization)
- Test 03: Should show command protocol working
- Test 04-06: Should capture image data and find JPEG headers

**Key Diagnostic:**
- If 02_i2c_tunnel fails (all registers return 0x55), this indicates the I2C tunnel to the image sensor is not working
- Without working I2C tunnel, register writes don't reach the sensor
- This explains why C-style register-based capture fails
- All capture tests will fail until I2C tunnel is fixed
