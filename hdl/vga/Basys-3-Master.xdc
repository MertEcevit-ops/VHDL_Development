## Complete VGA UART System Constraints for Basys3
## Supports VGA Display, UART Communication, and Seven Segment Display
## BRAM Optimized Version

##############################################################################
## Clock and Reset
##############################################################################

## Clock signal (100MHz)
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset Button (Center Button)
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports btnC]

##############################################################################
## Switches for Configuration
##############################################################################

set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]  ;# VGA text mode
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]  ;# Echo enable
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]  ;# Cursor enable
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]  ;# Pattern select[0]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]  ;# Pattern select[1]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]  ;# Pattern select[2]
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]  ;# Reserved
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]  ;# Reserved
set_property -dict { PACKAGE_PIN V2    IOSTANDARD LVCMOS33 } [get_ports {sw[8]}]  ;# Text color
set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS33 } [get_ports {sw[9]}]  ;# Background color
set_property -dict { PACKAGE_PIN T2    IOSTANDARD LVCMOS33 } [get_ports {sw[10]}] ;# Reserved
set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports {sw[11]}] ;# Reserved
set_property -dict { PACKAGE_PIN W2    IOSTANDARD LVCMOS33 } [get_ports {sw[12]}] ;# Reserved
set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports {sw[13]}] ;# Reserved
set_property -dict { PACKAGE_PIN T1    IOSTANDARD LVCMOS33 } [get_ports {sw[14]}] ;# Reserved
set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports {sw[15]}] ;# Reserved

##############################################################################
## UART Interface (USB-RS232)
##############################################################################

set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports RsRx]
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports RsTx]

##############################################################################
## VGA Connector
##############################################################################

# Red channel (4 bits)
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[0]}]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[1]}]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[2]}]
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[3]}]

# Green channel (4 bits)
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[0]}]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[1]}]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[2]}]
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[3]}]

# Blue channel (4 bits)
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[0]}]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[1]}]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[2]}]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[3]}]

# Sync signals
set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports vga_hsync]
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports vga_vsync]

##############################################################################
## Seven Segment Display
##############################################################################

# Segment outputs (a,b,c,d,e,f,g)
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]  ;# Segment a
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]  ;# Segment b
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]  ;# Segment c
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]  ;# Segment d
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]  ;# Segment e
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]  ;# Segment f
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]  ;# Segment g

# Digit anodes (active low)
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]   ;# Digit 0 (rightmost)
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]   ;# Digit 1
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {an[2]}]   ;# Digit 2
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]   ;# Digit 3 (leftmost)

##############################################################################
## Status LEDs
##############################################################################

set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]  ;# RX FIFO has data
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]  ;# TX FIFO has data
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]  ;# RX FIFO full
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]  ;# TX FIFO full
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}]  ;# TX busy
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {led[5]}]  ;# RX overflow error
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[6]}]  ;# Character received
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[7]}]  ;# Heartbeat
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports {led[8]}]  ;# VGA text mode
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports {led[9]}]  ;# Echo enable
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports {led[10]}] ;# Cursor enable
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports {led[11]}] ;# Clock locked
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports {led[12]}] ;# Display enable
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports {led[13]}] ;# Pattern select[0]
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports {led[14]}] ;# Pattern select[1]
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports {led[15]}] ;# Pattern select[2]

##############################################################################
## Configuration Options
##############################################################################

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# SPI configuration mode options for QSPI boot
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

##############################################################################
## Timing Constraints
##############################################################################

# Create derived clocks for VGA
create_generated_clock -name pixel_clk -source [get_ports clk] -divide_by 4 [get_nets pixel_clk]

# Clock domain separation
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks pixel_clk]

# VGA Output delay constraints (referenced to pixel clock)
set_output_delay -clock [get_clocks pixel_clk] -max 3.0 [get_ports {vga_red[*]}]
set_output_delay -clock [get_clocks pixel_clk] -min -1.0 [get_ports {vga_red[*]}]
set_output_delay -clock [get_clocks pixel_clk] -max 3.0 [get_ports {vga_green[*]}]
set_output_delay -clock [get_clocks pixel_clk] -min -1.0 [get_ports {vga_green[*]}]
set_output_delay -clock [get_clocks pixel_clk] -max 3.0 [get_ports {vga_blue[*]}]
set_output_delay -clock [get_clocks pixel_clk] -min -1.0 [get_ports {vga_blue[*]}]
set_output_delay -clock [get_clocks pixel_clk] -max 3.0 [get_ports vga_hsync]
set_output_delay -clock [get_clocks pixel_clk] -min -1.0 [get_ports vga_hsync]
set_output_delay -clock [get_clocks pixel_clk] -max 3.0 [get_ports vga_vsync]
set_output_delay -clock [get_clocks pixel_clk] -min -1.0 [get_ports vga_vsync]

##############################################################################
## False Path Constraints
##############################################################################

# Asynchronous input signals
set_false_path -from [get_ports btnC]
set_false_path -from [get_ports {sw[*]}]
set_false_path -from [get_ports RsRx]

# Output-only signals
set_false_path -to [get_ports {led[*]}]
set_false_path -to [get_ports {seg[*]}]
set_false_path -to [get_ports {an[*]}]
set_false_path -to [get_ports RsTx]

# Cross-clock domain paths (handled by synchronizers)
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks pixel_clk]
set_false_path -from [get_clocks pixel_clk] -to [get_clocks sys_clk_pin]

##############################################################################
## BRAM and Resource Optimization
##############################################################################

# Force BRAM usage for FIFOs and large memories
set_property RAM_STYLE BLOCK [get_cells -hier -filter {NAME =~ "*fifo*bram_memory*"}]
set_property RAM_STYLE BLOCK [get_cells -hier -filter {NAME =~ "*char_buffer*"}]
set_property RAM_STYLE BLOCK [get_cells -hier -filter {NAME =~ "*font_rom*"}]

# Prevent unwanted optimization
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {NAME =~ "*fifo_inst*"}]

##############################################################################
## Input/Output Standards and Drive Strength
##############################################################################

# Set appropriate drive strength for VGA signals
set_property DRIVE 12 [get_ports {vga_red[*]}]
set_property DRIVE 12 [get_ports {vga_green[*]}]
set_property DRIVE 12 [get_ports {vga_blue[*]}]
set_property DRIVE 12 [get_ports vga_hsync]
set_property DRIVE 12 [get_ports vga_vsync]

# Set slew rate for high-speed signals
set_property SLEW FAST [get_ports {vga_red[*]}]
set_property SLEW FAST [get_ports {vga_green[*]}]
set_property SLEW FAST [get_ports {vga_blue[*]}]
set_property SLEW FAST [get_ports vga_hsync]
set_property SLEW FAST [get_ports vga_vsync]

##############################################################################
## Additional Timing Exceptions
##############################################################################

# Reset synchronizer timing
set_false_path -from [get_ports btnC] -to [get_cells -hier -filter {NAME =~ "*reset_sync*"}]

# Heartbeat counter (not timing critical)
set_false_path -from [get_cells -hier -filter {NAME =~ "*heartbeat_counter*"}] -to [get_ports {led[7]}]

# Pattern selection (quasi-static)
set_false_path -from [get_ports {sw[5:3]}] -to [get_cells -hier -filter {NAME =~ "*pattern_sel*"}]

##############################################################################
## Power Optimization
##############################################################################

# Enable clock gating where possible
set_property CLOCK_GATING on [current_design]

# Power optimization for unused BRAM ports
set_property IS_ENABLED FALSE [get_drc_checks REQP-1712]