# max1000-fig-forth #

An implementation of FIG-FORTH 1802 on the MAX1000 development board from trenz Electronics.

https://www.trenz-electronic.de
https://www.arrow.com/en/campaigns/max1000

### Features ###

This version includes these features:

    * CDP1802 VHDL core
    * 32K RAM
    * UART connected to the onboard USB serial port
    * 22 GPIO pins
    * 8 onboard LEDS

### Building ###

Build using Quartus, follow these steps:
  
  * Create an empty project
  * Name the top level module 'maxforth'
  * Add the files in the list to the project
  * Open the TCL Scripts window (Tools=>TCL Scripts...)
  * Select and run the 'MAX1000-IOs.tcl' script
  * Select Processing=>Start Compilation
  * Wait for the compilation to complete

```
maxforth.vhd
mx1802.vhd
ram.vhd
uart.vhd
gpio.vhd
max1000-fig-forth.sdc
MAX1000-IOs.tcl
``` 

### Programming ###

Program the FPGA configuration to flash using the 'maxforth.pof' file.

### Testing ###

After programming, connect a terminal program to the USB serial port on the MAX1000, the serial port settings
are 115200, 8-n-1. Pressing either button on the MAX1000 should display the FIG-FORTH signon message.

### FIG-FORTH Image ###

The '.hex' file containing the FIG-FORTH program image was sourced from here:

http://www.retrotechnology.com/memship/figforth_1802.html

This program is held in the first 8K of memory, it is RAM, intialized when the FPGA configuration is loaded and
can be over written by accident. To recover from memory corruption either power cycle or press the button on the
opposite side to the LEDS. The button on the same side as the LEDS, resets the CPU and the GPIO registers.

### MAX1000 Pinout ###

![pinout](/pictures/pinout.png)

### GPIO ####

The GPIO interface consists of 4 ports A,B,C and D. Ports A and B are both 8 bits wide and bi-directional,
port C is 6 bits wide and is also bi-directional. Ports A,B and C are connected to the pins shown. Port D
is output only and connects to the 8 onboard LEDS.

The bi-directional ports each have two memory mapped 8-bit registers, one for data and the other for
data direction (DDR). A '1' in the DDR means the coresponding port bit is an output.

The GPIO data register sets the state of the outputs and reads the state of the inputs. The reset
state of all GPIO registers is 0. A '1' in the port D register turns the coresponding LED on.
All GPIO registers are read/write. The registers are summarized in the table below.

```

   +---------+--------------------+-------+
   | Address | Register           | Width |
   +---------+--------------------+-------+
   | 0xFFF8  | Port A Data        | 8 Bit |
   | 0xFFF9  | Port B Data        | 8 Bit |
   | 0xFFFA  | Port C Data        | 6 Bit |
   | 0xFFFB  | Port D Data (LEDS) | 8 Bit |
   | 0xFFFC  | Port A DDR         | 8 Bit |
   | 0xFFFD  | Port B DDR         | 8 Bit |
   | 0xFFFE  | PORT C DDR         | 6 Bit |
   +---------+--------------------+-------+

```


### Forth Test Program ###

This simple program will sequence the LEDS back and forth. The program defines 4 new Forth words. To enter the
program, first reset the board and enter the word 'HEX', this will set the radix to hexadecimal. Then enter
the folowing colon definitions:

```
    : DELAY 500 0 DO LOOP ;
    : LEFT 7 0 DO FFFB C@ 2 * FFFB C! DELAY LOOP ;
    : RIGHT 7 0 DO FFFB C@ 2 / FFFB C! DELAY LOOP ;
    : RUN 1 FFFB C! BEGIN LEFT RIGHT 0 UNTIL ;

```

After each line is entered the compiler should respond with OK.

Finally type the word 'RUN' to start the program.

![term](/pictures/term.png)
