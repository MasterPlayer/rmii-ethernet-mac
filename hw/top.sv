`timescale 1ns / 1ps


module top (
    input  logic       GCLK_100MHz,
    output logic [1:0] PHY_TXD    ,
    output logic       PHY_TXEN   ,
    input  logic [1:0] PHY_RXD    ,
    input  logic       PHY_RXER   ,
    output logic       PHY_RST    ,
    input  logic       PHY_INT    ,
    input  logic       PHY_CRS_DV
);


    localparam integer TIMER_LIMIT = 5000000;

    logic clk100  ;
    logic reset100;

    logic [$clog2(TIMER_LIMIT)-1:0] timer        = '{default:0};
    logic [                    7:0] led_register = '{default:0};

    logic       crc_bad          ;
    logic       crc_good         ;

    logic [7:0] eth_m_axis_tdata ;
    logic       eth_m_axis_tvalid;
    logic       eth_m_axis_tlast ;
    logic       eth_m_axis_tready;

    logic [7:0] eth_s_axis_tdata ;
    logic       eth_s_axis_tvalid;
    logic       eth_s_axis_tlast ;
    logic       eth_s_axis_tready;

    clk_wiz_100 clk_wiz_100_inst (
        .clk_in1 (GCLK_100MHz),
        .clk_out1(clk100     ), // output clk_out1
        .clk_out2(clk50      )  // output clk_out1
    );


    always_ff @(posedge clk100) begin 
        if (timer < TIMER_LIMIT) 
            timer <= timer + 1;
        else 
            timer <= '{default:0};
    end 

    rmii_ethernet rmii_ethernet_inst (
        .PHY_CLK           (PHY_INT          ),
        .PHY_TXD           (PHY_TXD          ),
        .PHY_TXEN          (PHY_TXEN         ),
        .PHY_RXD           (PHY_RXD          ),
        .PHY_RXER          (PHY_RXER         ),
        .PHY_RST           (PHY_RST          ),
        .PHY_CRS_DV        (PHY_CRS_DV       ),
        
        .ETH_RX_AXIS_CLK   (clk100           ),
        .ETH_RX_AXIS_RESET (reset100         ),
        .ETH_RX_AXIS_TDATA (eth_m_axis_tdata ),
        .ETH_RX_AXIS_TVALID(eth_m_axis_tvalid),
        .ETH_RX_AXIS_TLAST (eth_m_axis_tlast ),
        .ETH_RX_AXIS_TREADY(1'b1             ),
        
        .ETH_TX_AXIS_CLK   (clk100           ),
        .ETH_TX_AXIS_RESET (reset100         ),
        .ETH_TX_AXIS_TDATA (eth_s_axis_tdata ),
        .ETH_TX_AXIS_TVALID(eth_s_axis_tvalid),
        .ETH_TX_AXIS_TLAST (eth_s_axis_tlast ),
        .ETH_TX_AXIS_TREADY(eth_s_axis_tready),
        .CRC_BAD           (crc_bad          ),
        .CRC_GOOD          (crc_good         )
    );

endmodule
