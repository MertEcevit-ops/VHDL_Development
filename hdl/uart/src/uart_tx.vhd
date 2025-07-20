----------------------------------------------------------------------
-- UART Transmitter with FIFO Buffer
-- Includes TX FIFO for buffering transmit data
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        g_CLKS_PER_BIT : integer := 868;   -- Clock cycles per bit
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
        o_tx_line   : out std_logic;
        o_tx_busy   : out std_logic
    );
end uart_tx;

architecture behavioral of uart_tx is
    
    -- UART TX signals
    signal uart_tx_start : std_logic;
    signal uart_tx_data  : std_logic_vector(7 downto 0);
    signal uart_tx_busy  : std_logic;
    signal uart_tx_done  : std_logic;
    
    -- FIFO signals
    signal fifo_rd_en    : std_logic;
    signal fifo_empty    : std_logic;
    
    -- TX control state machine
    type tx_state_t is (IDLE, TRANSMITTING);
    signal tx_state : tx_state_t := IDLE;
    
    -- Components
    component uart_tx is
        generic (
            g_CLKS_PER_BIT : integer := 217
        );
        port (
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_tx_start  : in  std_logic;
            i_tx_data   : in  std_logic_vector(7 downto 0);
            o_tx_line   : out std_logic;
            o_tx_busy   : out std_logic;
            o_tx_done   : out std_logic
        );
    end component;
    
    component fifo_buffer is
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
    
    -- UART TX instance
    uart_tx_inst : uart_tx
        generic map (
            g_CLKS_PER_BIT => g_CLKS_PER_BIT
        )
        port map (
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_tx_start => uart_tx_start,
            i_tx_data  => uart_tx_data,
            o_tx_line  => o_tx_line,
            o_tx_busy  => uart_tx_busy,
            o_tx_done  => uart_tx_done
        );
    
    -- TX FIFO instance
    tx_fifo_inst : fifo_buffer
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
            rd_data    => uart_tx_data,
            full       => o_tx_full,
            empty      => fifo_empty,
            count      => o_tx_count
        );
    
    -- TX control state machine
    tx_control_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            tx_state <= IDLE;
            uart_tx_start <= '0';
            fifo_rd_en <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- Default assignments
            uart_tx_start <= '0';
            fifo_rd_en <= '0';
            
            case tx_state is
                
                when IDLE =>
                    if fifo_empty = '0' then
                        fifo_rd_en <= '1';
                        tx_state <= TRANSMITTING;
                    end if;
                    
                when TRANSMITTING =>
                    uart_tx_start <= '1';
                    if uart_tx_done = '1' then
                        tx_state <= IDLE;
                    end if;
                    
                when others =>
                    tx_state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- Output assignments
    o_tx_empty <= fifo_empty;
    o_tx_busy <= uart_tx_busy or (not fifo_empty);
    
end behavioral;