# VHDL Development

A collection of VHDL projects demonstrating FPGA design fundamentals.

## Projects

### 1. LED Cycler with Reset Synchronization
- 8-bit LED pattern cycling using shift registers
- Asynchronous reset with synchronous deassertion  
- Multi-vendor FPGA support (Xilinx, Altera, Gowin)
- Comprehensive testbench suite

### 2. UART Echo with FIFO Buffers
- Full-duplex generic UART communication (115200 baud)
- RX/TX FIFO buffers for improved performance
- Seven-segment display for character visualization
- 16 status LEDs for system monitoring
- ASCII character support with real-time echo

### 3. VGA Display System with UART Terminal
- Complete VGA 640x480@60Hz display controller
- Dual-mode operation: Pattern generator + UART text terminal
- Real-time character display with scrolling and cursor
- 8 test patterns including color bars, gradients, and checkerboard
- Switch-controlled mode selection and configuration

## Files

**LED Cycler Project:**
- `led_cycler.vhd` - LED cycling logic with shift register
- `reset_sync.vhd` - Generic reset synchronizer module
- `top.vhd` - Top-level integration (LED project)
- `*_tb.vhd` - Testbenches for simulation

**UART Echo Project:**
- `uart_rx.vhd` - UART receiver with FIFO buffer
- `uart_tx.vhd` - UART transmitter with FIFO buffer
- `fifo.vhd` - Generic FIFO buffer module
- `seven_segment_controller.vhd` - ASCII to 7-segment decoder
- `top.vhd` - UART echo top-level module

**VGA Display System:**
- `vga_top.vhd` - Complete VGA system integration
- `vga_timing.vhd` - VGA sync signal generator (640x480@60Hz)
- `vga_clock.vhd` - Clock divider for 25MHz pixel clock
- `vga_pattern.vhd` - Test pattern generator (8 patterns)
- `vga_pattern_txt.vhd` - UART text terminal with 80x30 display

## Target Platforms

- **Sipeed Tang Primer 20k Dock-Ext** (Gowin EDA)
- **BASYS3 FPGA Board** (Xilinx Vivado) - Full VGA and UART support

## Usage

### LED Cycler Project
1. Load LED cycler files in VHDL simulator or synthesis tool
2. Run testbenches for verification
3. Configure vendor settings in `reset_sync.vhd`
4. Synthesize for target FPGA platform

### UART Echo Project
1. Load UART project files into Vivado
2. Use `master.xdc` constraints for Basys3 board
3. Connect USB-UART interface (115200 baud, 8N1)
4. Characters typed in terminal will echo back and display on 7-segment

### VGA Display System
1. Load VGA project files into Vivado
2. Use `Basys-3-Master.xdc` constraints for complete pin mapping
3. Connect VGA monitor to Basys3 VGA port
4. Use switches to control display modes:
   - SW0: Toggle between pattern (0) and text terminal (1) modes
   - SW1: Enable/disable UART echo
   - SW2: Enable/disable cursor blinking
   - SW[5:3]: Select test pattern (0-7)
   - SW8: Text color (white/green)
   - SW9: Background color (black/dark blue)

## Key Features

**LED Cycler:**
- Clock Domain Crossing (CDC)
- Reset synchronization best practices
- FPGA vendor-specific attributes

**UART Echo:**
- Buffered UART communication with FIFOs
- Real-time character display on 7-segment
- Status monitoring via 16 LEDs
- Configurable FIFO depths (32 words default)

**VGA Display System:**
- Professional VGA timing generation (640x480@60Hz)
- Dual-mode display: 8 test patterns + 80x30 text terminal
- Real-time UART terminal with scrolling and cursor
- Switch-controlled configuration
- Full ASCII character support with simple bitmap font