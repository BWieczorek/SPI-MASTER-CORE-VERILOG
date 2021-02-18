`timescale 10ns/1ps
`include "SPI_MASTER_CORE.v"

module SPI_MASTER_TB ();

    reg CLK = 0;
    reg RSTN = 1;
    wire DATA_IN_RDY;
    reg DATA_IN_VD = 0;
    reg [7:0] DATA_IN = 0;
    wire [7:0] DATA_OUT;
    wire DATA_OUT_VD;
    wire MOSI;
    reg MISO = 1'b1;
    wire SPI_CLK;

SPI_MASTER_CORE #(1, 2)  SPI_MASTER (
    CLK, RSTN, 
    DATA_IN_RDY, 
    DATA_IN_VD, DATA_IN, 
    DATA_OUT, DATA_OUT_VD,
    MOSI, MISO, SPI_CLK
    );

    always #1 CLK = ~CLK;

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, SPI_MASTER_TB);
        #5
        DATA_IN = 8'b10101010;
        #1
        DATA_IN_VD = 1;
        #2 DATA_IN_VD = 0;
        #1000
        $finish;

    end




endmodule