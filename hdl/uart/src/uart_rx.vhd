----------------------------------------------------------------------
-- UART Receiver Module
-- 8 data bits, 1 start bit, 1 stop bit, no parity
-- Improved version with reset support
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        g_CLKS_PER_BIT : integer := 217  -- Clock cycles per bit
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_rx_serial : in  std_logic;
        o_rx_dv     : out std_logic;
        o_rx_byte   : out std_logic_vector(7 downto 0)
    );
end uart_rx;

architecture behavioral of UART_RX is
    
    -- State machine definition
    type uart_rx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state : uart_rx_state_t := IDLE;
    
    -- Internal signals
    signal clk_counter : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal rx_byte_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_dv_reg   : std_logic := '0';
    
begin
    
    -- Main UART RX process
    uart_rx_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Reset all signals
            state <= IDLE;
            clk_counter <= 0;
            bit_counter <= 0;
            rx_byte_reg <= (others => '0');
            rx_dv_reg <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- Default assignment
            rx_dv_reg <= '0';
            
            case state is
                
                when IDLE =>
                    clk_counter <= 0;
                    bit_counter <= 0;
                    
                    if i_rx_serial = '0' then  -- Start bit detected
                        state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    -- Check middle of start bit to make sure it's still low
                    if clk_counter = (g_CLKS_PER_BIT-1)/2 then
                        if i_rx_serial = '0' then
                            clk_counter <= 0;  -- Reset counter
                            state <= DATA_BITS;
                        else
                            state <= IDLE;  -- False start
                        end if;
                    else
                        clk_counter <= clk_counter + 1;
                    end if;
                    
                when DATA_BITS =>
                    if clk_counter < g_CLKS_PER_BIT-1 then
                        clk_counter <= clk_counter + 1;
                    else
                        clk_counter <= 0;
                        rx_byte_reg(bit_counter) <= i_rx_serial;
                        
                        if bit_counter < 7 then
                            bit_counter <= bit_counter + 1;
                        else
                            bit_counter <= 0;
                            state <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    if clk_counter < g_CLKS_PER_BIT-1 then
                        clk_counter <= clk_counter + 1;
                    else
                        rx_dv_reg <= '1';
                        clk_counter <= 0;
                        state <= CLEANUP;
                    end if;
                    
                when CLEANUP =>
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- Output assignments
    o_rx_dv <= rx_dv_reg;
    o_rx_byte <= rx_byte_reg;
    
end behavioral;