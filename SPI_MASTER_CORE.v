
// SPI_MASTER_CORE

/*
**Parameters**
SPI_MODE    |    CPOL       |   CPHA    |
    0       |     0         |     0     |
    1       |     0         |     1     |
    2       |     1         |     0     |
    3       |     1         |     1     |
CPOL - clock polarity
CPHA - clock phase

SPI_CLK_DIV_HALF - clock divider for SPI_CLOCK sourced by input CLK
min. value 2 - 25MHz SPI_CLK for 100MHz system CLK
real divider is 2*SPI_CLK_DIV_HALF

======================================================================

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

======================================================================


*/

module SPI_MASTER_CORE #(
    parameter SPI_MODE = 0,
    parameter SPI_CLK_DIV_HALF = 2
) (
    input CLK,
    input RSTN,
    output DATA_IN_RDY,
    input DATA_IN_VD,
    input [7:0] DATA_IN,
    output [7:0] DATA_OUT,
    output DATA_OUT_VD,
    output MOSI,
    input MISO,
    output reg SPI_CLK = 1'bz
);
//Output signal REG
reg r_DATA_OUT_VD = 1'b0;
reg r_MOSI = 1'bz; 
reg r_DATA_IN_RDY = 1'b0;

//SPI_CLK generation variables
wire SPI_CLK_EN = rm_State == COMMUNICATION;
reg [$clog2(SPI_CLK_DIV_HALF):0] CLK_DIV_COUNTER_HALF = 1;

// CPOL and CPHA selection acording to selected SPI_MODE
wire CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);
wire CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);


// Transmit-Receive State Machine
localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam COMMUNICATION = 2'b10;
localparam DATA_VALID = 2'b11;
reg [1:0] rm_State = IDLE;

// DATA_OUT register block
reg [7:0] r_DATA_RX = 7'b0;

// DATA_IN register block
reg [7:0] r_DATA_TX = 7'b0;

always @(posedge CLK) begin
    if(DATA_IN_RDY & DATA_IN_VD) begin
        r_DATA_TX <= DATA_IN;
    end
end

// SPI main logic
reg [$clog2(8):0] BIT_COUNTER = 7;

always @(posedge CLK) begin
    case (rm_State)
        IDLE : begin
            BIT_COUNTER <= 7;
            r_DATA_IN_RDY <= 1'b1;
            r_DATA_OUT_VD <= 1'b0;
            CLK_DIV_COUNTER_HALF <= 1'b1;
            r_MOSI <= 1'bz;
            if(DATA_IN_VD) begin
                rm_State <= START;
                r_DATA_IN_RDY <= 1'b0;
            end else begin
                rm_State <= IDLE;
            end
        end    
        START : begin
            if(!CPHA) begin
                r_MOSI <= r_DATA_TX[BIT_COUNTER];
            end else begin
                r_MOSI <= 1'bz;
                BIT_COUNTER <= 8;
            end
            rm_State <= COMMUNICATION;
        end
        COMMUNICATION : begin
            if(CPHA) begin
                casez ({CPOL, CLK_DIV_COUNTER_HALF == 0, CLK_DIV_COUNTER_HALF >= SPI_CLK_DIV_HALF - 1, SPI_CLK})
                    4'b0?10 : begin
                        BIT_COUNTER <= BIT_COUNTER - 1;
                        if(BIT_COUNTER <= 0) begin
                            rm_State <= DATA_VALID;
                        end
                    end
                    4'b01?0 : begin
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    4'b11?1 : begin
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    4'b01?1 : begin
                        r_DATA_RX[BIT_COUNTER] <= MISO;
                    end
                    4'b11?0 : begin
                        r_DATA_RX[BIT_COUNTER] <= MISO;
                    end
                    4'b1?11 : begin
                        BIT_COUNTER <= BIT_COUNTER - 1;
                        if(BIT_COUNTER <= 0) begin
                            rm_State <= DATA_VALID;
                        end
                    end
                endcase
            
            end else begin
                casez ({CPOL, CLK_DIV_COUNTER_HALF == 0, CLK_DIV_COUNTER_HALF >= SPI_CLK_DIV_HALF - 1, SPI_CLK})
                    4'b01?0 : begin
                        r_DATA_RX[BIT_COUNTER] <= MISO;
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    4'b11?1 : begin
                        r_DATA_RX[BIT_COUNTER] <= MISO;
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    4'b0?11 : begin
                        BIT_COUNTER <= BIT_COUNTER - 1;
                        if(BIT_COUNTER == 0) begin
                            rm_State <= DATA_VALID;
                        end
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    4'b1?10 : begin
                        BIT_COUNTER <= BIT_COUNTER - 1;
                        if(BIT_COUNTER == 0) begin
                            rm_State <= DATA_VALID;
                        end
                        r_MOSI <= r_DATA_TX[BIT_COUNTER];
                    end
                    default: r_MOSI <= r_DATA_TX[BIT_COUNTER];
                endcase
            end
                

        end
        DATA_VALID : begin
            r_DATA_OUT_VD <= 1'b1;
            rm_State <= IDLE;
            r_MOSI <= 1'bz;
        end
    endcase
        

end


//SPI_CLK generation block
always @(posedge CLK) begin
    if(SPI_CLK_EN) begin
        if(CLK_DIV_COUNTER_HALF >= SPI_CLK_DIV_HALF - 1) begin
            CLK_DIV_COUNTER_HALF <= 0;
        end else begin
            CLK_DIV_COUNTER_HALF <= CLK_DIV_COUNTER_HALF + 1;
        end
        if(CLK_DIV_COUNTER_HALF == 0) begin
           SPI_CLK <= ~SPI_CLK; 
        end
    end else begin
        CLK_DIV_COUNTER_HALF <= 1;
        SPI_CLK = CPOL;
    end
end

assign DATA_OUT = r_DATA_RX;
assign DATA_OUT_VD = r_DATA_OUT_VD;
assign MOSI = r_MOSI;
assign DATA_IN_RDY = r_DATA_IN_RDY;
    
endmodule