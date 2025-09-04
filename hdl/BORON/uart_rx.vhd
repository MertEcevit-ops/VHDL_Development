library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity uart_rx is
    generic (
        CLK_FREQ : integer := 50_000_000;  -- FPGA board frequency
        BAUD     : integer := 115200        -- Baud rate
    );
    port (
        clk_i   : in  std_logic;
        rst_ni  : in  std_logic;  -- Active-low async reset
        din_i   : in  std_logic;  -- UART RX signal
        data_o  : out std_logic_vector(7 downto 0);  -- Received data
        valid_o : out std_logic;  -- Valid signal, pulses high when data is ready
        busy_o  : out std_logic   -- Busy signal, set 1 if UART receiving signals
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD;
    constant CNT_WIDTH    : integer := integer(ceil(log2(real(CLKS_PER_BIT))));
    
    type state_t is (IDLE, RX_START_BIT, RX_DATA_BITS, RX_STOP_BIT, CLEANUP);
    signal state : state_t;
    
    signal clk_cnt : unsigned(CNT_WIDTH-1 downto 0);
    signal bit_idx : unsigned(2 downto 0);
    signal rx_byte : std_logic_vector(7 downto 0);
    
begin
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            state   <= IDLE;
            clk_cnt <= (others => '0');
            bit_idx <= (others => '0');
            data_o  <= (others => '0');
            valid_o <= '0';
            busy_o  <= '0';
            rx_byte <= (others => '0');
        elsif rising_edge(clk_i) then
            case state is
                when IDLE =>
                    valid_o <= '0';
                    clk_cnt <= (others => '0');
                    bit_idx <= (others => '0');
                    busy_o  <= '0';
                    
                    if din_i = '0' then  -- Start bit detected
                        state  <= RX_START_BIT;
                        busy_o <= '1';
                    end if;
                    
                when RX_START_BIT =>
                    if clk_cnt = (CLKS_PER_BIT - 1) / 2 then
                        if din_i = '0' then  -- Verify start bit
                            clk_cnt <= (others => '0');
                            state   <= RX_DATA_BITS;
                        else
                            state <= IDLE;  -- False start bit
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;
                    
                when RX_DATA_BITS =>
                    if clk_cnt < CLKS_PER_BIT - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= (others => '0');
                        rx_byte(to_integer(bit_idx)) <= din_i;  -- LSB first
                        
                        if bit_idx < 7 then
                            bit_idx <= bit_idx + 1;
                        else
                            bit_idx <= (others => '0');
                            state   <= RX_STOP_BIT;
                        end if;
                    end if;
                    
                when RX_STOP_BIT =>
                    if clk_cnt < CLKS_PER_BIT - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        if din_i = '1' then
                            valid_o <= '1';
                            data_o  <= rx_byte;
                        end if;
                        clk_cnt <= (others => '0');
                        state   <= CLEANUP;
                        busy_o  <= '0';
                    end if;
                    
                when CLEANUP =>
                    state   <= IDLE;
                    valid_o <= '0';
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;