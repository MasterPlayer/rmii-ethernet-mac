library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;
    use IEEE.math_real."ceil";
    use IEEE.math_real."log2";

library UNISIM;
    use UNISIM.VComponents.all;

Library xpm;
    use xpm.vcomponents.all;



entity fifo_out_async_xpm is
    generic(
        DATA_WIDTH      :           integer         :=  256                         ;
        CDC_SYNC        :           integer         :=  4                           ;
        MEMTYPE         :           String          :=  "block"                     ;
        DEPTH           :           integer         :=  16                           
    );
    port(
        CLK             :   in      std_logic                                       ;
        RESET           :   in      std_logic                                       ;        
        OUT_DIN_DATA    :   in      std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
        OUT_DIN_KEEP    :   in      std_logic_Vector ( ( DATA_WIDTH/8)-1 downto 0 ) ;
        OUT_DIN_LAST    :   in      std_logic                                       ;
        OUT_WREN        :   in      std_logic                                       ;
        OUT_FULL        :   out     std_logic                                       ;
        OUT_AWFULL      :   out     std_logic                                       ;

        M_AXIS_CLK      :   in      std_logic                                       ;
        M_AXIS_TDATA    :   out     std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
        M_AXIS_TKEEP    :   out     std_logic_Vector (( DATA_WIDTH/8)-1 downto 0 )  ;
        M_AXIS_TVALID   :   out     std_logic                                       ;
        M_AXIS_TLAST    :   out     std_logic                                       ;
        M_AXIS_TREADY   :   in      std_logic                                        

    );
end fifo_out_async_xpm;



architecture fifo_out_async_xpm_arch of fifo_out_async_xpm is

    constant FIFO_WIDTH :           integer := DATA_WIDTH + ((DATA_WIDTH/8) + 1);
    constant FIFO_DATA_COUNT_W  :   integer := integer(ceil(log2(real(DEPTH))));

    ATTRIBUTE X_INTERFACE_INFO  : STRING;
    ATTRIBUTE X_INTERFACE_INFO of RESET: SIGNAL is "xilinx.com:signal:reset:1.0 RESET RST";
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER of RESET: SIGNAL is "POLARITY ACTIVE_HIGH";
    
    signal  din         :           std_logic_vector ( FIFO_WIDTH-1 downto 0 ) := (others => '0')   ;
    signal  dout        :           std_logic_vector ( FIFO_WIDTH-1 downto 0 )                      ;
    signal  empty       :           std_logic                                                       ;
    signal  rden        :           std_logic                                  := '0'               ;

begin

    din     <= OUT_DIN_LAST & OUT_DIN_KEEP & OUT_DIN_DATA;
    rden    <= '1' when empty = '0' and M_AXIS_TREADY = '1' else '0';
   
    M_AXIS_TDATA <= dout( DATA_WIDTH-1 downto 0 ) ;
    M_AXIS_TKEEP <= dout( ((DATA_WIDTH + (DATA_WIDTH/8))-1) downto DATA_WIDTH );
    M_AXIS_TLAST <= dout( DATA_WIDTH + (DATA_WIDTH/8));
    M_AXIS_TVALID <= not (empty)    ;

    

    fifo_out_async_xpm_inst : xpm_fifo_async
        generic map (
            CDC_SYNC_STAGES         =>  CDC_SYNC                    ,   -- DECIMAL
            DOUT_RESET_VALUE        =>  "0"                         ,   -- String
            ECC_MODE                =>  "no_ecc"                    ,   -- String
            FIFO_MEMORY_TYPE        =>  MEMTYPE                     ,   -- String
            FIFO_READ_LATENCY       =>  0                           ,   -- DECIMAL
            FIFO_WRITE_DEPTH        =>  DEPTH                       ,   -- DECIMAL
            FULL_RESET_VALUE        =>  1                           ,   -- DECIMAL
            PROG_EMPTY_THRESH       =>  10                          ,   -- DECIMAL
            PROG_FULL_THRESH        =>  10                          ,   -- DECIMAL
            RD_DATA_COUNT_WIDTH     =>  FIFO_DATA_COUNT_W           ,   -- DECIMAL
            READ_DATA_WIDTH         =>  FIFO_WIDTH                  ,   -- DECIMAL
            READ_MODE               =>  "fwft"                      ,   -- String
            RELATED_CLOCKS          =>  0                           ,   -- DECIMAL
            USE_ADV_FEATURES        =>  "0008"                      ,   -- String
            WAKEUP_TIME             =>  0                           ,   -- DECIMAL
            WRITE_DATA_WIDTH        =>  FIFO_WIDTH                  ,   -- DECIMAL
            WR_DATA_COUNT_WIDTH     =>  FIFO_DATA_COUNT_W               -- DECIMAL
        )
        port map (
            almost_empty            =>  open                        ,
            almost_full             =>  OUT_AWFULL                  ,
            data_valid              =>  open                        ,
            dbiterr                 =>  open                        ,
            dout                    =>  DOUT                        ,
            empty                   =>  empty                       ,
            full                    =>  OUT_FULL                    ,
            overflow                =>  open                        ,
            prog_empty              =>  open                        ,
            prog_full               =>  open                        ,
            rd_data_count           =>  open                        ,
            rd_rst_busy             =>  open                        ,
            sbiterr                 =>  open                        ,
            underflow               =>  open                        ,
            wr_ack                  =>  open                        ,
            wr_data_count           =>  open                        ,
            wr_rst_busy             =>  open                        ,
            din                     =>  din                         ,
            injectdbiterr           =>  '0'                         ,
            injectsbiterr           =>  '0'                         ,
            rd_clk                  =>  M_AXIS_CLK                  ,
            rd_en                   =>  rden                        ,
            rst                     =>  RESET                       ,
            sleep                   =>  '0'                         ,
            wr_clk                  =>  CLK                         ,
            wr_en                   =>  OUT_WREN                     
        );



end fifo_out_async_xpm_arch;
