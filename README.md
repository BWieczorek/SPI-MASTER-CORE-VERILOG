# SPI-MASTER-CORE-VERILOG
SPI Master core module - CPOL and CPHA customization - SPI clock based on System Clock

Parameters

CPOL - clock polarity
CPHA - clock phase
SPI_CLK_DIV_HALF - clock divider for SPI_CLOCK sourced by input CLK
min. value 2 - 25MHz SPI_CLK for 100MHz system CLK
real divider is 2*SPI_CLK_DIV_HALF


PORTS
CLK - system CLOCK
RSTN - NEG Reset - not used (todo)
DATA_IN_RDY - output high state if module ready for send
DATA_IN_VD - data input vaild - 1 clk pulse to start transmition
DATA_IN - 8bit data to send (locked on DATA_IN_VD pulse)
DATA_OUT - 8bit data recieved valid on DATA_OUT_VD pulse
DATA_OUT_VD - data output valid 1 clk pulse
MOSI - MASTER OUTPUT SLAVE INPUT - SPI wiring
MISO - MASTER INPUT SLAVE OUTPUT - SPI wiring
SPI_CLK - SPI clock (work only on transmition)

