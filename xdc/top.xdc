
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports GCLK_100MHz]
create_clock -period 10.000 [get_ports GCLK_100MHz]

set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports PHY_TXD[0]]
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS33} [get_ports PHY_TXD[1]]

set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports PHY_TXEN  ]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports PHY_RXD[0]]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports PHY_RXD[1]]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports PHY_RXER  ]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports PHY_RST   ]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports PHY_INT   ]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports PHY_CRS_DV]
    


create_clock -period 20.000 [get_ports PHY_INT]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PHY_INT_IBUF]


