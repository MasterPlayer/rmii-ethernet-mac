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



entity fifo_cmd_async_xpm is
    generic(
        DATA_WIDTH      :           integer         :=  64                          ;
        CDC_SYNC        :           integer         :=  4                           ;
        MEMTYPE         :           String          :=  "block"                     ;
        DEPTH           :           integer         :=  16                           
    );
    port(
        CLK_WR          :   in      std_logic                                       ;
        RESET_WR        :   in      std_logic                                       ;
        CLK_RD          :   in      std_logic                                       ;
        
        DIN             :   in      std_logic_vector ( DATA_WIDTH-1 downto 0 )      ;
        WREN            :   in      std_logic                                       ;
        FULL            :   out     std_logic                                       ;
        DOUT            :   out     std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
        RDEN            :   IN      std_logic                                       ;
        EMPTY           :   out     std_logic                                        

    );
end fifo_cmd_async_xpm;



architecture fifo_cmd_async_xpm_arch of fifo_cmd_async_xpm is
    
    constant FIFO_DATA_COUNT_W  :   integer := integer(ceil(log2(real(DEPTH))));

begin


    xpm_cmd_fifo_async_inst : xpm_fifo_async
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
            READ_DATA_WIDTH         =>  DATA_WIDTH                  ,   -- DECIMAL
            READ_MODE               =>  "fwft"                      ,   -- String
            RELATED_CLOCKS          =>  0                           ,   -- DECIMAL
            USE_ADV_FEATURES        =>  "0000"                      ,   -- String
            WAKEUP_TIME             =>  0                           ,   -- DECIMAL
            WRITE_DATA_WIDTH        =>  DATA_WIDTH                  ,   -- DECIMAL
            WR_DATA_COUNT_WIDTH     =>  FIFO_DATA_COUNT_W               -- DECIMAL
        )
        port map (
            almost_empty        =>  open                    ,
            almost_full         =>  open                    ,
            data_valid          =>  open                    ,
            dbiterr             =>  open                    ,
            dout                =>  DOUT                    ,                   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
            empty               =>  EMPTY                   ,                 -- 1-bit output: Empty Flag: When asserted, this signal indicates that
            full                =>  FULL                    ,                   -- 1-bit output: Full Flag: When asserted, this signal indicates that the
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
            din                 =>  DIN                     ,
            injectdbiterr       =>  '0'                     ,
            injectsbiterr       =>  '0'                     ,
            rd_clk              =>  CLK_RD                  ,
            rd_en               =>  RDEN                    ,
            rst                 =>  RESET_WR                ,
            sleep               =>  '0'                     ,
            wr_clk              =>  CLK_WR                  ,
            wr_en               =>  WREN                    
        );

end fifo_cmd_async_xpm_arch;
