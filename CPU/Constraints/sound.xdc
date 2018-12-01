## Clock signal
#  Use an XDC file for the clock signal

##PWM Audio Amplifier
set_property PACKAGE_PIN A11 [get_ports audPWM]
set_property IOSTANDARD LVCMOS33 [get_ports audPWM]

# audEn = 1 means enable audio; 0 means disable
set_property PACKAGE_PIN D12 [get_ports audEn]
set_property IOSTANDARD LVCMOS33 [get_ports audEn]
