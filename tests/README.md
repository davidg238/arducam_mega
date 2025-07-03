# ArduCam Mega-5MP Test Suite

## Organized Test Structure

Tests are organized in logical progression order:

### Core Tests (Run in Order)

1. **01_spi_protocol_basic.toit** - Basic SPI communication validation
2. **01_spi_connectivity.toit** - SPI hardware connectivity check  
3. **02_init_simple.toit** - Camera initialization test
4. **03_command_protocol.toit** - ArduCam command protocol (Session 2 fix)
5. **04_capture_basic.toit** - Basic image capture functionality
6. **05_format_jpeg.toit** - JPEG format verification
7. **06_integration_full.toit** - Multiple formats and resolutions

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
- **02_init_*** - Initialization and hardware detection
- **03_command_*** - ArduCam command protocol tests
- **04_capture_*** - Image capture functionality  
- **05_format_*** - Image format verification
- **06_integration_*** - Full integration tests

### Legacy Tests

The `test_*.toit` files are legacy tests from development. The organized `0X_*.toit` tests replace them with better structure.

## Expected Results

With working hardware:
- Tests 01-02: Should pass (basic SPI and init)
- Test 03: Should show command protocol working
- Test 04: Should capture image data
- Test 05: Should find JPEG headers (if Session 2 fix is complete)
- Test 06: Should work with multiple formats

If getting consistent 0x55 responses, this indicates hardware communication issues rather than software problems.
