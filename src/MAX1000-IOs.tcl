#========================================================================
# MAX1000 Board project setup file
# FOR 10M08SAU169C8G
# Sets device, pinout and I/O standards suitable for the MAX1000 board.
#
# Source this file from your project's menu; Tools => Tcl Scripts...
#
#========================================================================

set_global_assignment -name NUM_PARALLEL_PROCESSORS 6

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M08SAU169C8G
set_global_assignment -name LAST_QUARTUS_VERSION 14.0.0
set_global_assignment -name DEVICE_FILTER_PACKAGE UFBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 169
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 8

#============================================================
# CLOCK
#============================================================
set_location_assignment PIN_H6 -to clk12m
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk12m

#============================================================
# KEY (RESET and USER BUTTON)
#============================================================
set_location_assignment PIN_E6 -to user_btn
# set_location_assignment PIN_E7 -to reset_n
set_instance_assignment -name IO_STANDARD "3.3 V Schmitt Trigger" -to user_btn
# set_instance_assignment -name IO_STANDARD "3.3 V Schmitt Trigger" -to reset_n

#============================================================
# LED
#============================================================
set_location_assignment PIN_A8  -to led[0]
set_location_assignment PIN_A9  -to led[1]
set_location_assignment PIN_A11 -to led[2]
set_location_assignment PIN_A10 -to led[3]
set_location_assignment PIN_B10 -to led[4]
set_location_assignment PIN_C9  -to led[5]
set_location_assignment PIN_C10 -to led[6]
set_location_assignment PIN_D8  -to led[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[7]

#============================================================
# UART
#============================================================
# TXD of FTDI Chip : BDBUS0
set_location_assignment PIN_A4 -to BDBUS[0]
# RXD of FTDI Chip : BDBUS1
set_location_assignment PIN_B4 -to BDBUS[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BDBUS[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BDBUS[1]

#============================================================
# Arduino Header
#============================================================
set_location_assignment PIN_H8  -to d[0]
set_location_assignment PIN_K10 -to d[1]
set_location_assignment PIN_H5  -to d[2]
set_location_assignment PIN_H4  -to d[3]
set_location_assignment PIN_J1  -to d[4]
set_location_assignment PIN_J2  -to d[5]
set_location_assignment PIN_L12 -to d[6]
set_location_assignment PIN_J12 -to d[7]
set_location_assignment PIN_J13 -to d[8]
set_location_assignment PIN_K11 -to d[9]
set_location_assignment PIN_K12 -to d[10]

# Select with or without pull-up resistors connection for D11 & D12
# without pull-up resistors
set_location_assignment PIN_J10 -to d[11]
set_location_assignment PIN_H10 -to d[12]

#with pull-up resistors
#set_location_assignment PIN_B11 -to d[11]  
#set_location_assignment PIN_G13 -to d[12]

set_location_assignment PIN_H13 -to d[13]
set_location_assignment PIN_G12 -to d[14]

set_location_assignment PIN_E1 -to ain[0]
set_location_assignment PIN_C2 -to ain[1]
set_location_assignment PIN_C1 -to ain[2]
set_location_assignment PIN_D1 -to ain[3]
set_location_assignment PIN_E3 -to ain[4]
set_location_assignment PIN_F1 -to ain[5]
set_location_assignment PIN_E4 -to ain[6]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d[14]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ain[6]

#============================================================
# End of pin and io_standard assignments
#============================================================

# set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
# set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
# set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top

# set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

#============================================================
# Set device configuration mode
#============================================================

set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE COMP IMAGE WITH ERAM"

