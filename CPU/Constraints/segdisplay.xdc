##7 segment display

set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports { segments[7] }]; #IO_L24N_T3_A00_D16_14 Sch=ca
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports { segments[6] }]; #IO_25_14 Sch=cb
set_property -dict { PACKAGE_PIN L5   IOSTANDARD LVCMOS33 } [get_ports { segments[5] }]; #IO_25_15 Sch=cc
set_property -dict { PACKAGE_PIN L4   IOSTANDARD LVCMOS33 } [get_ports { segments[4] }]; #IO_L17P_T2_A26_15 Sch=cd
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports { segments[3] }]; #IO_L13P_T2_MRCC_14 Sch=ce
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports { segments[2] }]; #IO_L19P_T3_A10_D26_14 Sch=cf
set_property -dict { PACKAGE_PIN L6   IOSTANDARD LVCMOS33 } [get_ports { segments[1] }]; #IO_L4P_T0_D04_14 Sch=cg
set_property -dict { PACKAGE_PIN M4   IOSTANDARD LVCMOS33 } [get_ports { segments[0] }]; #IO_L19N_T3_A21_VREF_15 Sch=dp

set_property -dict { PACKAGE_PIN N6   IOSTANDARD LVCMOS33 } [get_ports { digitselect[0] }]; #IO_L23P_T3_FOE_B_15 Sch=an[0]
set_property -dict { PACKAGE_PIN M6   IOSTANDARD LVCMOS33 } [get_ports { digitselect[1] }]; #IO_L23N_T3_FWE_B_15 Sch=an[1]
set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports { digitselect[2] }]; #IO_L24P_T3_A01_D17_14 Sch=an[2]
set_property -dict { PACKAGE_PIN N5   IOSTANDARD LVCMOS33 } [get_ports { digitselect[3] }]; #IO_L19P_T3_A22_15 Sch=an[3]
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports { digitselect[4] }]; #IO_L8N_T1_D12_14 Sch=an[4]
set_property -dict { PACKAGE_PIN N4   IOSTANDARD LVCMOS33 } [get_ports { digitselect[5] }]; #IO_L14P_T2_SRCC_14 Sch=an[5]
set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports { digitselect[6] }]; #IO_L23P_T3_35 Sch=an[6]
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports { digitselect[7] }]; #IO_L23N_T3_A02_D18_14 Sch=an[7]
