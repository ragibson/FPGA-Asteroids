## Clock signal
#  Use an XDC file for the clock signal

## Sound
#  Use an XDC file for the sound generator

##7 segment display
#  Use an XDC file for the segmented display


##Accelerometer
set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { aclMISO }]
set_property -dict { PACKAGE_PIN B14   IOSTANDARD LVCMOS33 } [get_ports { aclMOSI }]
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { aclSCK }]
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { aclSS }]
