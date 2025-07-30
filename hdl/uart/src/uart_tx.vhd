----------------------------------------------------------------------
-- UART Transmitter with FIFO Buffer
-- Includes TX FIFO for buffering transmit data
-- Based on nandland.com UART TX implementation
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        g_CLKS_PER_BIT : integer := 217;   -- Clock cycles per bit (25MHz/115200)
        FIFO_DEPTH     : integer := 16     -- TX FIFO depth
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        
        -- FIFO write interface
        i_wr_en     : in  std_logic;
        i_tx_data   : in  std_logic_vector(7 downto 0);
        o_tx_full   : out std_logic;
        o_tx_empty  : out std_logic;
        o_tx_count  : out std_logic_vector(4 downto 0);
        
        -- UART output
        o_tx_serial : out std_logic;
        o_tx_active : out std_logic;
        o_tx_done   : out std_logic
    );
end uart_tx;

architecture behavioral of uart_tx is
    
    -- UART TX State Machine
    type t_SM_Main is (IDLE, TX_START_BIT, TX_DATA_BITS,
                       TX_STOP_BIT, CLEANUP);
    signal r_SM_Main : t_SM_Main := IDLE;
    
    -- UART TX signals
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
    signal r_TX_Done   : std_logic := '0';
    signal r_TX_Active : std_logic := '0';
    signal r_TX_Serial : std_logic := '1';
    
    -- FIFO signals
    signal fifo_rd_en    : std_logic;
    signal fifo_empty    : std_logic;
    signal fifo_rd_data  : std_logic_vector(7 downto 0);
    
    -- TX control signals
    signal tx_start_internal : std_logic := '0';
    signal start_tx_flag     : std_logic := '0';
    
    component fifo is
        generic (
            FIFO_DEPTH : integer := 16;
            DATA_WIDTH : integer := 8
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            wr_en      : in  std_logic;
            wr_data    : in  std_logic_vector(7 downto 0);
            rd_en      : in  std_logic;
            rd_data    : out std_logic_vector(7 downto 0);
            full       : out std_logic;
            empty      : out std_logic;
            count      : out std_logic_vector(4 downto 0)
        );
    end component;
    
begin
    
    -- TX FIFO instance
    tx_fifo_inst : fifo
        generic map (
            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => 8
        )
        port map (
            clk        => i_clk,
            rst        => i_rst,
            wr_en      => i_wr_en,
            wr_data    => i_tx_data,
            rd_en      => fifo_rd_en,
            rd_data    => fifo_rd_data,
            full       => o_tx_full,
            empty      => fifo_empty,
            count      => o_tx_count
        );
    
    -- TX control process - handles FIFO read and TX start
    tx_control_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            start_tx_flag <= '0';
            fifo_rd_en <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- Default assignments
            fifo_rd_en <= '0';
            start_tx_flag <= '0';
            
            -- Start transmission when FIFO has data and TX is idle
            if fifo_empty = '0' and r_SM_Main = IDLE and r_TX_Active = '0' then
                fifo_rd_en <= '1';      -- Read from FIFO
                start_tx_flag <= '1';   -- Flag to start TX next cycle
            end if;
            
        end if;
    end process;
    
    -- UART TX State Machine Process (based on nandland implementation)
    p_UART_TX : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_SM_Main   <= IDLE;
                r_TX_Done   <= '0';
                r_TX_Active <= '0';
                r_TX_Serial <= '1';
                r_Clk_Count <= 0;
                r_Bit_Index <= 0;
                r_TX_Data   <= (others => '0');
            else
                r_TX_Done <= '0';  -- Default assignment
                
                case r_SM_Main is
                    when IDLE =>
                        r_TX_Active <= '0';
                        r_TX_Serial <= '1';         -- Drive Line High for Idle
                        r_Clk_Count <= 0;
                        r_Bit_Index <= 0;
                        
                        if start_tx_flag = '1' then
                            r_TX_Data <= fifo_rd_data;  -- Load data from FIFO
                            r_SM_Main <= TX_START_BIT;
                        else
                            r_SM_Main <= IDLE;
                        end if;
                        
                    -- Send out Start Bit. Start bit = 0
                    when TX_START_BIT =>
                        r_TX_Active <= '1';
                        r_TX_Serial <= '0';
                        -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
                        if r_Clk_Count < g_CLKS_PER_BIT-1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= TX_START_BIT;
                        else
                            r_Clk_Count <= 0;
                            r_SM_Main   <= TX_DATA_BITS;
                        end if;
                        
                    -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish          
                    when TX_DATA_BITS =>
                        r_TX_Serial <= r_TX_Data(r_Bit_Index);
                        
                        if r_Clk_Count < g_CLKS_PER_BIT-1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= TX_DATA_BITS;
                        else
                            r_Clk_Count <= 0;
                            
                            -- Check if we have sent out all bits
                            if r_Bit_Index < 7 then
                                r_Bit_Index <= r_Bit_Index + 1;
                                r_SM_Main   <= TX_DATA_BITS;
                            else
                                r_Bit_Index <= 0;
                                r_SM_Main   <= TX_STOP_BIT;
                            end if;
                        end if;
                        
                    -- Send out Stop bit. Stop bit = 1
                    when TX_STOP_BIT =>
                        r_TX_Serial <= '1';
                        -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                        if r_Clk_Count < g_CLKS_PER_BIT-1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= TX_STOP_BIT;
                        else
                            r_TX_Done   <= '1';
                            r_Clk_Count <= 0;
                            r_SM_Main   <= CLEANUP;
                        end if;
                                
                    -- Stay here 1 clock
                    when CLEANUP =>
                        r_TX_Active <= '0';
                        r_SM_Main   <= IDLE;
                        
                    when others =>
                        r_SM_Main <= IDLE;
                        
                end case;
            end if;
        end if;
    end process p_UART_TX;
    
    -- Output assignments
    o_tx_serial <= r_TX_Serial;
    o_tx_active <= r_TX_Active;
    o_tx_done   <= r_TX_Done;
    o_tx_empty  <= fifo_empty;
    
end behavioral;