library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity uart_tx is
    generic (
        BAUD     : integer := 115200;      -- Baud rate
        CLK_FREQ : integer := 50_000_000  -- FPGA board frequency
    );
    port (
        clk_i  : in  std_logic;
        rst_ni : in  std_logic;  -- Active-low async reset
        data_i : in  std_logic_vector(7 downto 0);  -- Data to be sent through UART
        send_i : in  std_logic;  -- Send signal
        dout_o : out std_logic;  -- UART TX signal
        busy_o : out std_logic   -- Busy signal, if UART transmitting set to 1
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD;
    constant CNT_WIDTH    : integer := integer(ceil(log2(real(CLKS_PER_BIT))));
    
    type state_t is (IDLE, TX_START_BIT, TX_DATA_BITS, TX_STOP_BIT, CLEANUP);
    signal state : state_t;
    
    signal clk_cnt : unsigned(CNT_WIDTH-1 downto 0);
    signal bit_idx : unsigned(2 downto 0);
    signal tx_data : std_logic_vector(7 downto 0);
    
begin
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            state   <= IDLE;
            clk_cnt <= (others => '0');
            bit_idx <= (others => '0');
            tx_data <= (others => '0');
            dout_o  <= '1';  -- Line high when idle
            busy_o  <= '0';
        elsif rising_edge(clk_i) then
            case state is
                when IDLE =>
                    dout_o  <= '1';  -- Keep line high for idle
                    clk_cnt <= (others => '0');
                    bit_idx <= (others => '0');
                    busy_o  <= '0';
                    
                    if send_i = '1' then
                        busy_o  <= '1';
                        tx_data <= data_i;
                        state   <= TX_START_BIT;
                    end if;
                    
                when TX_START_BIT =>
                    dout_o <= '0';  -- Start bit is 0
                    
                    if clk_cnt < CLKS_PER_BIT - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= (others => '0');
                        state   <= TX_DATA_BITS;
                    end if;
                    
                when TX_DATA_BITS =>
                    dout_o <= tx_data(to_integer(bit_idx));  -- Send LSB first
                    
                    if clk_cnt < CLKS_PER_BIT - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= (others => '0');
                        
                        if bit_idx < 7 then
                            bit_idx <= bit_idx + 1;
                        else
                            bit_idx <= (others => '0');
                            state   <= TX_STOP_BIT;
                        end if;
                    end if;
                    
                when TX_STOP_BIT =>
                    dout_o <= '1';  -- Stop bit is 1
                    
                    if clk_cnt < CLKS_PER_BIT - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= (others => '0');
                        state   <= CLEANUP;
                        busy_o  <= '0';
                    end if;
                    
                when CLEANUP =>
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;