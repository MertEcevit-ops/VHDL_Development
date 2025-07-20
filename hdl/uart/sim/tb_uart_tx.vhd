
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end tb_uart_tx;

architecture sim of tb_uart_tx is
    
    -- Clock parameters
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz clock
    constant CLKS_PER_BIT : integer := 217;  -- For 115200 baud
    
    -- Signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal tx_start : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_line : std_logic;
    signal tx_busy : std_logic;
    signal tx_done : std_logic;
    
    -- Test data
    type test_data_array is array (0 to 3) of std_logic_vector(7 downto 0);
    constant TEST_DATA : test_data_array := (
        X"41",  -- 'A'
        X"42",  -- 'B'
        X"43",  -- 'C'
        X"0A"   -- Line feed
    );
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- DUT instantiation
    uut: entity work.UART_TX
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            i_clk => clk,
            i_rst => rst,
            i_tx_start => tx_start,
            i_tx_data => tx_data,
            o_tx_line => tx_line,
            o_tx_busy => tx_busy,
            o_tx_done => tx_done
        );
    
    -- Test process
    test_proc : process
    begin
        -- Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        -- Send test data
        for i in 0 to 3 loop
            -- Wait for idle
            wait until tx_busy = '0';
            wait for CLK_PERIOD;
            
            -- Send data
            tx_data <= TEST_DATA(i);
            tx_start <= '1';
            wait for CLK_PERIOD;
            tx_start <= '0';
            
            -- Wait for completion
            wait until tx_done = '1';
            wait for CLK_PERIOD;
            
            report "Sent data: " & integer'image(to_integer(unsigned(TEST_DATA(i))));
        end loop;
        
        wait for 1000 ns;
        
        report "Test completed successfully!";
        wait;
    end process;
    
end sim;