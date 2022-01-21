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



entity fifo_in_async_xpm is
    generic(
        DATA_WIDTH      :           integer         :=  16                          ;
        CDC_SYNC        :           integer         :=  4                           ;
        MEMTYPE         :           String          :=  "block"                     ;
        DEPTH           :           integer         :=  16                           
    );
    port(
        S_AXIS_CLK      :   in      std_logic                                       ;
        S_AXIS_RESET    :   in      std_logic                                       ;
        M_AXIS_CLK      :   in      std_logic                                       ;
        
        S_AXIS_TDATA    :   in      std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
        S_AXIS_TKEEP    :   in      std_logic_Vector (( DATA_WIDTH/8)-1 downto 0 )  ;
        S_AXIS_TVALID   :   in      std_logic                                       ;
        S_AXIS_TLAST    :   in      std_logic                                       ;
        S_AXIS_TREADY   :   out     std_logic                                       ;

        IN_DOUT_DATA    :   out     std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
        IN_DOUT_KEEP    :   out     std_logic_Vector ( ( DATA_WIDTH/8)-1 downto 0 ) ;
        IN_DOUT_LAST    :   out     std_logic                                       ;
        IN_RDEN         :   in      std_logic                                       ;
        IN_EMPTY        :   out     std_logic                                   
    );
end fifo_in_async_xpm;



architecture fifo_in_async_xpm_arch of fifo_in_async_xpm is
    
    constant FIFO_WIDTH :           integer := DATA_WIDTH + ((DATA_WIDTH/8) + 1)    ;
    constant FIFO_DATA_COUNT_W  :   integer := integer(ceil(log2(real(DEPTH))));

    signal  full        :           std_logic                                       ;
    signal  din         :           std_logic_vector ( FIFO_WIDTH-1 downto 0 ) ;
    signal  dout        :           std_logic_vector ( FIFO_WIDTH-1 downto 0 ) ;
    
    signal  wren        :           std_logic ;

begin


    S_AXIS_TREADY <= not (full);
    wren <= '1' when full = '0' and S_AXIS_TVALID = '1' else '0' ;

    
    din <= S_AXIS_TLAST & S_AXIS_TKEEP & S_AXIS_TDATA;
    
    IN_DOUT_DATA <= dout( DATA_WIDTH-1 downto 0 ) ;
    IN_DOUT_KEEP <= dout( ((DATA_WIDTH + (DATA_WIDTH/8))-1) downto DATA_WIDTH );
    IN_DOUT_LAST <= dout( DATA_WIDTH + (DATA_WIDTH/8));


    xpm_fifo_async_inst : xpm_fifo_async
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
            USE_ADV_FEATURES        =>  "0000"                      ,   -- String
            WAKEUP_TIME             =>  0                           ,   -- DECIMAL
            WRITE_DATA_WIDTH        =>  FIFO_WIDTH                  ,   -- DECIMAL
            WR_DATA_COUNT_WIDTH     =>  FIFO_DATA_COUNT_W               -- DECIMAL
        )
        port map (
            almost_empty        =>  open                    ,
            almost_full         =>  open                    ,
            data_valid          =>  open                    ,
            dbiterr             =>  open                    ,
            dout                =>  DOUT                    ,                   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
            empty               =>  IN_EMPTY                ,                 -- 1-bit output: Empty Flag: When asserted, this signal indicates that
            full                =>  full                    ,                   -- 1-bit output: Full Flag: When asserted, this signal indicates that the
            overflow            =>  open                    ,
            prog_empty          =>  open                    ,
            prog_full           =>  open                    ,
            rd_data_count       =>  open                    ,
            rd_rst_busy         =>  open                    ,
            sbiterr             =>  open                    ,
            underflow           =>  open                    ,
            wr_ack              =>  open                    ,
            wr_data_count       =>  open                    ,
            wr_rst_busy         =>  open                    ,
            din                 =>  din                     ,
            injectdbiterr       =>  '0'                     ,
            injectsbiterr       =>  '0'                     ,
            rd_clk              =>  M_AXIS_CLK              ,
            rd_en               =>  IN_RDEN                 ,
            rst                 =>  S_AXIS_RESET            ,
            sleep               =>  '0'                     ,
            wr_clk              =>  S_AXIS_CLK              ,
            wr_en               =>  wren                  
        );


end fifo_in_async_xpm_arch;
