library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end tb_uart_rx;

architecture sim of tb_uart_rx is
    
    -- Clock parameters
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz clock
    constant CLKS_PER_BIT : integer := 217;  -- For 115200 baud
    constant BIT_PERIOD : time := CLK_PERIOD * CLKS_PER_BIT;
    
    -- Signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal rx_serial : std_logic := '1';
    signal rx_dv : std_logic;
    signal rx_byte : std_logic_vector(7 downto 0);
    
    -- Test data
    constant TEST_BYTE : std_logic_vector(7 downto 0) := X"55";  -- 01010101
    
    -- UART send procedure
    procedure send_uart_byte(
        constant data : in std_logic_vector(7 downto 0);
        signal tx_line : out std_logic) is
    begin
        -- Start bit
        tx_line <= '0';
        wait for BIT_PERIOD;
        
        -- Data bits (LSB first)
        for i in 0 to 7 loop
            tx_line <= data(i);
            wait for BIT_PERIOD;
        end loop;
        
        -- Stop bit
        tx_line <= '1';
        wait for BIT_PERIOD;
    end procedure;
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- DUT instantiation
    uut: entity work.UART_RX
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            i_clk => clk,
            i_rst => rst,
            i_rx_serial => rx_serial,
            o_rx_dv => rx_dv,
            o_rx_byte => rx_byte
        );
    
    -- Test process
    test_proc : process
    begin
        -- Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        -- Send test byte
        send_uart_byte(TEST_BYTE, rx_serial);
        
        -- Wait for reception
        wait until rx_dv = '1';
        
        -- Check received data
        assert rx_byte = TEST_BYTE
            report "Received data mismatch!"
            severity error;
            
        report "Test completed successfully!";
        wait;
    end process;
    
end sim;