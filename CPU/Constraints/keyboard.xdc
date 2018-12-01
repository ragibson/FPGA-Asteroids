##USB (PS/2)

set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33  PULLUP true} [get_ports { ps2_clk }];
set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33  PULLUP true} [get_ports { ps2_data }];
