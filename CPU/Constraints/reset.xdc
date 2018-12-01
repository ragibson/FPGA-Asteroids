## NOTE:  If you use the CPU RESET button on the board, remember that
## it is 1 when not pressed, and 0 when pressed.
##
## This XDC file instead wires the "reset" input in your project
## to the center push button (BTNC).
## 1 means pressed, 0 means released

set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { reset }];
