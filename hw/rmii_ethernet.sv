`timescale 1ns / 1ps



module rmii_ethernet (
    input  logic       PHY_CLK           ,
    output logic [1:0] PHY_TXD           ,
    output logic       PHY_TXEN          ,
    input  logic [1:0] PHY_RXD           ,
    input  logic       PHY_RXER          ,
    output logic       PHY_RST           ,
    input  logic       PHY_CRS_DV        ,
    input  logic       ETH_RX_AXIS_CLK   ,
    input  logic       ETH_RX_AXIS_RESET ,
    output logic [7:0] ETH_RX_AXIS_TDATA ,
    output logic       ETH_RX_AXIS_TVALID,
    output logic       ETH_RX_AXIS_TLAST ,
    input  logic       ETH_RX_AXIS_TREADY,
    input  logic       ETH_TX_AXIS_CLK   ,
    input  logic       ETH_TX_AXIS_RESET ,
    input  logic [7:0] ETH_TX_AXIS_TDATA ,
    input  logic       ETH_TX_AXIS_TVALID,
    input  logic       ETH_TX_AXIS_TLAST ,
    output logic       ETH_TX_AXIS_TREADY,
    output logic       CRC_BAD           ,
    output logic       CRC_GOOD
);


    logic [7:0] rx_data   = '{default:0};
    logic       rx_valid  = 1'b0        ;
    logic       rx_last   = 1'b0        ;
    logic       d_rx_last = 1'b0        ;


    logic [ 1:0] byte_counter      = '{default:0};
    logic [63:0] preamble_register = '{default:0};

    logic has_preamble_found = 1'b0;

    logic d_phy_crs_dv = 1'b0;

    logic [31:0] crc_calc                ;
    logic [31:0] crc_calc_r              ;

    logic [31:0] crc_calc_tx             ;
    logic [31:0] crc_calc_tx_r           ;

    logic [31:0] crc_ext                 ;
    logic        has_last_assigned = 1'b0;

    logic [16:0][7:0] rx_data_vector  = '{default:'{default:0}};
    logic [16:0]      rx_valid_vector = '{default:0}           ;

    logic [7:0] out_din_data;
    logic       out_din_last;
    logic       out_wren    ;
    logic       out_full    ;
    logic       out_awfull  ;

    logic phy_reset_sync;

    logic [7:0] in_dout_data       ;
    logic       in_dout_last       ;
    logic       in_rden      = 1'b0;
    logic       in_empty           ;

    logic       saved_in_dout_last       ;

    logic cmd_rden  = 1'b0;
    logic cmd_empty       ;

    typedef enum {
        IDLE_ST         ,
        TX_PREAMBLE_ST  ,
        TX_SFD_ST       ,
        TX_DATA_ST      ,
        TX_CRC_ST         
    } fsm;

    fsm current_state = IDLE_ST;


    logic [7:0] serializer_data ;
    logic       serializer_valid;
    logic       serializer_ready;


    xpm_cdc_async_rst #(
        .DEST_SYNC_FF   (4), // DECIMAL; range: 2-10
        .INIT_SYNC_FF   (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .RST_ACTIVE_HIGH(0)  // DECIMAL; 0=active low reset, 1=active high reset
    ) xpm_cdc_async_rst_inst (
        .dest_arst(phy_reset_sync   ), // 1-bit output: src_arst asynchronous reset signal synchronized to destination
        .dest_clk (PHY_CLK          ), // 1-bit input: Destination clock.
        .src_arst (ETH_TX_AXIS_RESET)  // 1-bit input: Source asynchronous reset signal.
    );

    always_ff @(posedge PHY_CLK) begin 

        d_phy_crs_dv <= PHY_CRS_DV;
    end 

    always_comb begin 

        rx_last = ~PHY_CRS_DV & d_phy_crs_dv;
    end 

    always_ff @(posedge PHY_CLK) begin  
        if (phy_reset_sync)
            PHY_RST <= 1'b0;
        else 
            PHY_RST <= 1'b1;
    end 

    always_ff @(posedge PHY_CLK) begin : preamble_register_proc

        preamble_register <= {PHY_RXD, preamble_register[63:2]};
    end 

    always_ff @(posedge PHY_CLK) begin : has_preamble_found_proc
        if (PHY_CRS_DV)
            if (preamble_register == 64'hd555555555555555) 
                has_preamble_found <= 1'b1;
            else 
                has_preamble_found <= has_preamble_found;
        else 
            has_preamble_found <= 1'b0;
    end 

    always_ff @(posedge PHY_CLK) begin 
        if (has_preamble_found)
            byte_counter <= byte_counter + 1;
    end 

    always_ff @(posedge PHY_CLK) begin

        rx_data <= {PHY_RXD, rx_data[7:2]};
    end

    always_comb begin 
        if (byte_counter == 3)
            rx_valid = 1'b1;
        else 
            rx_valid = 1'b0;
    end 

    always_ff @(posedge PHY_CLK) begin 
        if (rx_valid)
            crc_ext <= {rx_data, crc_ext[31:8]};
    end 

    generate 
        for (genvar i = 0; i < 32; i++) begin 
            always_comb begin 
                crc_calc_r[i] = crc_calc[31-i];
            end 
        end 
    endgenerate

    eth_crc_calc eth_crc_calc_rx_inst (
        .CLK    (PHY_CLK                            ),
        .RESET  (phy_reset_sync | CRC_GOOD | CRC_BAD),
        .DATA_IN({rx_data_vector[15][0],            
                    rx_data_vector[15][1],
                    rx_data_vector[15][2],
                    rx_data_vector[15][3],
                    rx_data_vector[15][4],
                    rx_data_vector[15][5],
                    rx_data_vector[15][6],
                    rx_data_vector[15][7]}),
        .CRC_EN (rx_valid_vector[15]                ),
        .CRC_OUT(crc_calc                           )
    );

    always_ff @(posedge PHY_CLK) begin 

        rx_data_vector <= {rx_data_vector[15:0], rx_data};
    end 

    always_ff @(posedge PHY_CLK) begin 
        if (has_last_assigned)
            rx_valid_vector <= '{default:0};
        else 
            if (rx_valid)
                rx_valid_vector <= {rx_valid_vector[15:0], 1'b1};
            else 
                rx_valid_vector <= {rx_valid_vector[15:0], 1'b0};
    end 

    always_ff @(posedge PHY_CLK) begin : d_rx_last_proc

        d_rx_last <= rx_last;
    end 

    always_ff @(posedge PHY_CLK) begin : has_last_assigned_proc
        if (rx_valid_vector[16])
            if (d_rx_last)
                has_last_assigned <= 1'b1;
            else 
                has_last_assigned <= 1'b0;
        else 
            has_last_assigned <= 1'b0;
    end 

    always_comb begin
        out_din_data = rx_data_vector[16];
        out_wren     = rx_valid_vector[16];
        out_din_last = d_rx_last;
    end 

    always_ff @(posedge PHY_CLK) begin 
        if (rx_valid_vector[16] & d_rx_last) 
            if (crc_calc_r == crc_ext) 
                CRC_GOOD <= 1'b1;
            else 
                CRC_GOOD <= 1'b0;
        else 
            CRC_GOOD <= 1'b0;
    end 

    always_ff @(posedge PHY_CLK) begin 
        if (rx_valid_vector[16] & d_rx_last) 
            if (crc_calc_r != crc_ext) 
                CRC_BAD <= 1'b1;
            else 
                CRC_BAD <= 1'b0;
        else 
            CRC_BAD <= 1'b0;
    end

    fifo_out_async_xpm #(
        .DATA_WIDTH(8      ),
        .CDC_SYNC  (4      ),
        .MEMTYPE   ("block"),
        .DEPTH     (16     )
    ) fifo_out_async_xpm_inst (
        .CLK          (PHY_CLK           ),
        .RESET        (phy_reset_sync    ),
        .OUT_DIN_DATA (out_din_data      ),
        .OUT_DIN_KEEP ('b1               ),
        .OUT_DIN_LAST (out_din_last      ),
        .OUT_WREN     (out_wren          ),
        .OUT_FULL     (out_full          ),
        .OUT_AWFULL   (out_awfull        ),
        .M_AXIS_CLK   (ETH_RX_AXIS_CLK   ),
        .M_AXIS_TDATA (ETH_RX_AXIS_TDATA ),
        .M_AXIS_TKEEP (                  ),
        .M_AXIS_TVALID(ETH_RX_AXIS_TVALID),
        .M_AXIS_TLAST (ETH_RX_AXIS_TLAST ),
        .M_AXIS_TREADY(ETH_RX_AXIS_TREADY)
    );

    fifo_in_async_xpm #(
        .DATA_WIDTH(8      ),
        .CDC_SYNC  (4      ),
        .MEMTYPE   ("block"),
        .DEPTH     (16384  )
    ) fifo_in_async_xpm_inst (
        .S_AXIS_CLK   (ETH_TX_AXIS_CLK   ),
        .S_AXIS_RESET (ETH_TX_AXIS_RESET ),
        .M_AXIS_CLK   (PHY_CLK           ),
        
        .S_AXIS_TDATA (ETH_TX_AXIS_TDATA ),
        .S_AXIS_TKEEP (1'b1              ),
        .S_AXIS_TVALID(ETH_TX_AXIS_TVALID),
        .S_AXIS_TLAST (ETH_TX_AXIS_TLAST ),
        .S_AXIS_TREADY(ETH_TX_AXIS_TREADY),
        
        .IN_DOUT_DATA (in_dout_data      ),
        .IN_DOUT_KEEP (                  ),
        .IN_DOUT_LAST (in_dout_last      ),
        .IN_RDEN      (in_rden           ),
        .IN_EMPTY     (in_empty          )
    );

    fifo_cmd_async_xpm #(
        .DATA_WIDTH(1      ),
        .CDC_SYNC  (4      ),
        .MEMTYPE   ("block"),
        .DEPTH     (16     )
    ) fifo_cmd_async_xpm_inst (
        .CLK_WR  (ETH_TX_AXIS_CLK                                            ),
        .RESET_WR(ETH_TX_AXIS_RESET                                          ),
        .CLK_RD  (PHY_CLK                                                    ),
        .DIN     (1'b1                                                       ),
        .WREN    (ETH_TX_AXIS_TVALID & ETH_TX_AXIS_TREADY & ETH_TX_AXIS_TLAST),
        .FULL    (                                                           ),
        .DOUT    (                                                           ),
        .RDEN    (cmd_rden                                                   ),
        .EMPTY   (cmd_empty                                                  )
    );

    logic [2:0] word_cnt = '{default:0};

    always_ff @(posedge PHY_CLK) begin 
        if (phy_reset_sync)
            current_state <= IDLE_ST;
        else 
            case (current_state)
                IDLE_ST: 
                    if (!in_empty) 
                        current_state <= TX_PREAMBLE_ST;
                    else
                        current_state <= current_state;

                TX_PREAMBLE_ST :
                    if (serializer_ready)
                        if (word_cnt == 6)
                            current_state <= TX_SFD_ST;

                TX_SFD_ST : 
                    if (serializer_ready)
                        current_state <= TX_DATA_ST;
                    else 
                        current_state <= current_state;

                TX_DATA_ST : 
                    if (serializer_ready)
                        if (saved_in_dout_last) 
                            current_state <= TX_CRC_ST;
                        else 
                            current_state <= current_state;
                    else 
                        current_state <= current_state;

                TX_CRC_ST: 
                    if (serializer_ready)
                        if (word_cnt == 3)
                            current_state <= IDLE_ST;
                        else 
                            current_state <= current_state;
                    else 
                        current_state <= current_state; 
            endcase // current_state
    end 

    always_ff @(posedge PHY_CLK) begin 
        case (current_state)
            TX_PREAMBLE_ST : 
                if (serializer_ready)
                    word_cnt <= word_cnt + 1;

            TX_CRC_ST : 
                if (serializer_ready)
                    word_cnt <= word_cnt + 1;

            default : 
                word_cnt <= '{default:0};

        endcase // current_state;
    end 

    rmii_serializer rmii_serializer_inst (
        .CLK          (PHY_CLK         ),
        .RESET        (phy_reset_sync  ),
        .S_AXIS_TDATA (serializer_data ),
        .S_AXIS_TVALID(serializer_valid),
        .S_AXIS_TREADY(serializer_ready),
        .TXD          (PHY_TXD         ),
        .TXEN         (PHY_TXEN        )
    );

    always_ff @(posedge PHY_CLK) begin 
        case (current_state)
            TX_PREAMBLE_ST : 
                if (serializer_ready)
                    if (word_cnt == 6)
                        serializer_data <= 8'hD5;
                    else 
                        serializer_data <= 8'h55;
                else 
                    serializer_data <= 8'h55;


            TX_SFD_ST : 
                if (serializer_ready)
                    serializer_data <= in_dout_data;    
                else
                    serializer_data <= 8'hd5;


            TX_DATA_ST :
                if (serializer_ready)
                    if (saved_in_dout_last) 
                        serializer_data <= crc_calc_tx_r[7:0];
                    else 
                        serializer_data <= in_dout_data;
                else 
                    serializer_data <= serializer_data;

            TX_CRC_ST :
                if (serializer_ready)
                    case (word_cnt)
                        0 : serializer_data <= crc_calc_tx_r[15: 8];
                        1 : serializer_data <= crc_calc_tx_r[23:16];
                        2 : serializer_data <= crc_calc_tx_r[31:24];
                    endcase // word_cnt

            default : 
                serializer_data <= serializer_data;
        endcase // current_state
    end 

    always_ff @(posedge PHY_CLK) begin 
        case (current_state)
            TX_DATA_ST :
                if (in_rden)
                    if (in_dout_last) 
                        saved_in_dout_last <= 1'b1;
                    else 
                        saved_in_dout_last <= 1'b0;
                else 
                    saved_in_dout_last <= saved_in_dout_last;

            default : 
                saved_in_dout_last <= 1'b0;

        endcase // current_state
    end 


    always_ff @(posedge PHY_CLK) begin 
        case (current_state)

            TX_PREAMBLE_ST : 
                serializer_valid <= 1'b1;

            TX_SFD_ST : 
                serializer_valid <= 1'b1;

            TX_DATA_ST : 
                serializer_valid <= 1'b1;

            TX_CRC_ST: 
                if (serializer_ready)
                    if (word_cnt == 3)
                        serializer_valid <= 1'b0;
                    else 
                        serializer_valid <= 1'b1;
                else 
                    serializer_valid <= 1'b1;

            default 
                serializer_valid <= 1'b0;

        endcase // current_state
    end 

    always_comb begin 
        case (current_state)
            TX_SFD_ST : 
                if (serializer_ready)
                    in_rden = 1'b1;
                else 
                    in_rden = 1'b0;
           
           TX_DATA_ST : 
                if (serializer_ready)
                    in_rden = ~saved_in_dout_last;
                else 
                    in_rden = 1'b0;

            default : 
                in_rden = 1'b0;
        endcase // current_state
    end 

    logic reset_crc_tx;

    always_ff @(posedge PHY_CLK) begin 
        case (current_state)
            IDLE_ST : 
                reset_crc_tx <= 1'b1;

            default: 
                reset_crc_tx <= 1'b0;
        endcase // current_state
    end 

    eth_crc_calc eth_crc_calc_tx_inst (
        .CLK    (PHY_CLK     ),
        .RESET  (reset_crc_tx),
        .DATA_IN({in_dout_data[0], 
            in_dout_data[1], 
            in_dout_data[2], 
            in_dout_data[3], 
            in_dout_data[4], 
            in_dout_data[5], 
            in_dout_data[6], 
            in_dout_data[7]}),
        .CRC_EN (in_rden     ),
        .CRC_OUT(crc_calc_tx )
    );

    generate 
        for (genvar i = 0; i < 32; i++) begin 
            always_comb begin 
                crc_calc_tx_r[i] = crc_calc_tx[31-i];
            end 
        end 
    endgenerate




endmodule