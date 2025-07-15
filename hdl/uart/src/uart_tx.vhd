----------------------------------------------------------------------
-- UART Transmitter Module
-- 8 data bits, 1 start bit, 1 stop bit, no parity
-- Configurable baud rate via generic parameter
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        g_CLKS_PER_BIT : integer := 217  -- Clock cycles per bit
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
end uart_tx;

architecture behavioral of UART_TX is
    
    -- State machine definition
    type uart_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : uart_state_t := IDLE;
    
    -- Internal signals
    signal clk_counter : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal tx_buffer   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_done_reg : std_logic := '0';
    
begin
    
    -- Main UART TX process
    uart_tx_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Reset all signals
            state <= IDLE;
            clk_counter <= 0;
            bit_counter <= 0;
            tx_buffer <= (others => '0');
            o_tx_line <= '1';
            o_tx_busy <= '0';
            tx_done_reg <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- Default assignments
            tx_done_reg <= '0';
            
            case state is
                
                when IDLE =>
                    o_tx_line <= '1';  -- Line idle high
                    o_tx_busy <= '0';
                    clk_counter <= 0;
                    bit_counter <= 0;
                    
                    if i_tx_start = '1' then
                        tx_buffer <= i_tx_data;
                        state <= START_BIT;
                        o_tx_busy <= '1';
                    end if;
                    
                when START_BIT =>
                    o_tx_line <= '0';  -- Start bit is low
                    o_tx_busy <= '1';
                    
                    if clk_counter < g_CLKS_PER_BIT-1 then
                        clk_counter <= clk_counter + 1;
                    else
                        clk_counter <= 0;
                        state <= DATA_BITS;
                        bit_counter <= 0;
                    end if;
                    
                when DATA_BITS =>
                    o_tx_line <= tx_buffer(bit_counter);  -- Send LSB first
                    o_tx_busy <= '1';
                    
                    if clk_counter < g_CLKS_PER_BIT-1 then
                        clk_counter <= clk_counter + 1;
                    else
                        clk_counter <= 0;
                        
                        if bit_counter < 7 then
                            bit_counter <= bit_counter + 1;
                        else
                            bit_counter <= 0;
                            state <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    o_tx_line <= '1';  -- Stop bit is high
                    o_tx_busy <= '1';
                    
                    if clk_counter < g_CLKS_PER_BIT-1 then
                        clk_counter <= clk_counter + 1;
                    else
                        clk_counter <= 0;
                        tx_done_reg <= '1';
                        state <= IDLE;
                    end if;
                    
                when others =>
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- Output assignment
    o_tx_done <= tx_done_reg;
    
end behavioral;