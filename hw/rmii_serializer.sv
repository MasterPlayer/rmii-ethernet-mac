`timescale 1ns / 1ps


module rmii_serializer (
    input  logic       CLK          ,
    input  logic       RESET        ,
    input  logic [7:0] S_AXIS_TDATA ,
    input  logic       S_AXIS_TVALID,
    output logic       S_AXIS_TREADY,
    output logic [1:0] TXD          ,
    output logic       TXEN
);

    logic [1:0] word_counter = '{default:0}; 

    always_ff @(posedge CLK) begin 
        if (RESET)
            word_counter <= '{default:0};
        else 
            if (S_AXIS_TVALID)
                word_counter <= word_counter + 1;
            else
                word_counter <= word_counter;
    end 

    always_ff @(posedge CLK) begin 
        if (S_AXIS_TVALID)
            case (word_counter)
                2'b00 : TXD <= S_AXIS_TDATA[1:0];
                2'b01 : TXD <= S_AXIS_TDATA[3:2];
                2'b10 : TXD <= S_AXIS_TDATA[5:4];
                2'b11 : TXD <= S_AXIS_TDATA[7:6];
            endcase // word_counter
        else 
            TXD <= '{default:0};
    end 

    always_ff @(posedge CLK) begin 
        case (word_counter)
            2'b10: S_AXIS_TREADY <= 1'b1;
            default: S_AXIS_TREADY <= 1'b0;
        endcase // word_counter
    end 

    always_ff @(posedge CLK) begin 
        TXEN <= S_AXIS_TVALID;
    end 

endmodule
