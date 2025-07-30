----------------------------------------------------------------------
-- UART Receiver with FIFO Buffer
-- Includes RX FIFO for buffering received data
-- Based on nandland.com UART RX implementation
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        g_CLKS_PER_BIT : integer := 217;   -- Clock cycles per bit (25MHz/115200)
        FIFO_DEPTH     : integer := 16     -- RX FIFO depth
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_rx_serial : in  std_logic;
        
        -- FIFO read interface
        i_rd_en     : in  std_logic;
        o_rx_data   : out std_logic_vector(7 downto 0);
        o_rx_empty  : out std_logic;
        o_rx_full   : out std_logic;
        o_rx_count  : out std_logic_vector(4 downto 0);
        
        -- Status
        o_rx_error  : out std_logic
    );
end uart_rx;

architecture behavioral of uart_rx is
    
    -- UART RX State Machine
    type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                       s_RX_Stop_Bit, s_Cleanup);
    signal r_SM_Main : t_SM_Main := s_Idle;
    
    -- UART RX signals
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal r_RX_DV     : std_logic := '0';
    
    -- FIFO signals
    signal fifo_wr_en   : std_logic;
    signal fifo_full    : std_logic;
    signal rx_overflow  : std_logic := '0';  
    
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
    
    -- UART RX State Machine Process
    p_UART_RX : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_SM_Main   <= s_Idle;
                r_RX_DV     <= '0';
                r_Clk_Count <= 0;
                r_Bit_Index <= 0;
                r_RX_Byte   <= (others => '0');
            else
                case r_SM_Main is
                    when s_Idle =>
                        r_RX_DV     <= '0';
                        r_Clk_Count <= 0;
                        r_Bit_Index <= 0;
                        if i_rx_serial = '0' then       -- Start bit detected
                            r_SM_Main <= s_RX_Start_Bit;
                        else
                            r_SM_Main <= s_Idle;
                        end if;
                        
                    -- Check middle of start bit to make sure it's still low
                    when s_RX_Start_Bit =>
                        if r_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
                            if i_rx_serial = '0' then
                                r_Clk_Count <= 0;  -- reset counter since we found the middle
                                r_SM_Main   <= s_RX_Data_Bits;
                            else
                                r_SM_Main   <= s_Idle;
                            end if;
                        else
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= s_RX_Start_Bit;
                        end if;
                        
                    -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
                    when s_RX_Data_Bits =>
                        if r_Clk_Count < g_CLKS_PER_BIT-1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= s_RX_Data_Bits;
                        else
                            r_Clk_Count            <= 0;
                            r_RX_Byte(r_Bit_Index) <= i_rx_serial;
                            
                            -- Check if we have received all bits
                            if r_Bit_Index < 7 then
                                r_Bit_Index <= r_Bit_Index + 1;
                                r_SM_Main   <= s_RX_Data_Bits;
                            else
                                r_Bit_Index <= 0;
                                r_SM_Main   <= s_RX_Stop_Bit;
                            end if;
                        end if;
                        
                    -- Receive Stop bit. Stop bit = 1
                    when s_RX_Stop_Bit =>
                        -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                        if r_Clk_Count < g_CLKS_PER_BIT-1 then
                            r_Clk_Count <= r_Clk_Count + 1;
                            r_SM_Main   <= s_RX_Stop_Bit;
                        else
                            r_RX_DV     <= '1';
                            r_Clk_Count <= 0;
                            r_SM_Main   <= s_Cleanup;
                        end if;
                                
                    -- Stay here 1 clock
                    when s_Cleanup =>
                        r_SM_Main <= s_Idle;
                        r_RX_DV   <= '0';
                        
                    when others =>
                        r_SM_Main <= s_Idle;
                        
                end case;
            end if;
        end if;
    end process p_UART_RX;
    
    -- RX FIFO instance
    rx_fifo_inst : fifo
        generic map (
            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => 8
        )
        port map (
            clk        => i_clk,
            rst        => i_rst,
            wr_en      => fifo_wr_en,
            wr_data    => r_RX_Byte,
            rd_en      => i_rd_en,
            rd_data    => o_rx_data,
            full       => fifo_full,
            empty      => o_rx_empty,
            count      => o_rx_count
        );
    
    -- FIFO write control - only write when byte is received and FIFO not full
    fifo_wr_en <= r_RX_DV and not fifo_full;
    
    -- Overflow detection
    overflow_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            rx_overflow <= '0';
        elsif rising_edge(i_clk) then
            if r_RX_DV = '1' and fifo_full = '1' then
                rx_overflow <= '1';
            end if;
        end if;
    end process;
    
    -- Output assignments
    o_rx_full <= fifo_full;
    o_rx_error <= rx_overflow;
    
end behavioral;