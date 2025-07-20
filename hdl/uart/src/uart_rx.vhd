----------------------------------------------------------------------
-- UART Receiver with FIFO Buffer
-- Includes RX FIFO for buffering received data
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        g_CLKS_PER_BIT : integer := 868;   -- Clock cycles per bit
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
    
    -- UART RX signals
    signal uart_rx_dv   : std_logic;
    signal uart_rx_byte : std_logic_vector(7 downto 0);
    
    -- FIFO signals
    signal fifo_wr_en   : std_logic;
    signal fifo_full    : std_logic;
    signal rx_overflow  : std_logic := '0';
    
    -- Components
    component uart_rx is
        generic (
            g_CLKS_PER_BIT : integer := 217
        );
        port (
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_rx_serial : in  std_logic;
            o_rx_dv     : out std_logic;
            o_rx_byte   : out std_logic_vector(7 downto 0)
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
    
    -- UART RX instance
    uart_rx_inst : uart_rx
        generic map (
            g_CLKS_PER_BIT => g_CLKS_PER_BIT
        )
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_rx_serial => i_rx_serial,
            o_rx_dv     => uart_rx_dv,
            o_rx_byte   => uart_rx_byte
        );
    
    -- RX FIFO instance
    rx_fifo_inst : fifo_buffer
        generic map (
            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => 8
        )
        port map (
            clk        => i_clk,
            rst        => i_rst,
            wr_en      => fifo_wr_en,
            wr_data    => uart_rx_byte,
            rd_en      => i_rd_en,
            rd_data    => o_rx_data,
            full       => fifo_full,
            empty      => o_rx_empty,
            count      => o_rx_count
        );
    
    -- FIFO write control
    fifo_wr_en <= uart_rx_dv and not fifo_full;
    
    -- Overflow detection
    overflow_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            rx_overflow <= '0';
        elsif rising_edge(i_clk) then
            if uart_rx_dv = '1' and fifo_full = '1' then
                rx_overflow <= '1';
            end if;
        end if;
    end process;
    
    -- Output assignments
    o_rx_full <= fifo_full;
    o_rx_error <= rx_overflow;
    
end behavioral;