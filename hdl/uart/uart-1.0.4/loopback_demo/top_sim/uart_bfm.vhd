library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_bfm is
  generic (
    baud_rate : positive
  );
  port (
    -- Data to send (sampled on rising data_in_valid)
    data_in : in std_logic_vector(7 downto 0);
    data_in_ready : out boolean;
    data_in_valid : in boolean;
    
    -- Received data (valid on rising data_out_valid)
    data_out : out std_logic_vector(7 downto 0);
    data_out_valid : out boolean;

    -- UART interface
    rx : in std_logic;
    tx : out std_logic
  );
end uart_bfm;

architecture beh of uart_bfm is

  constant symbol_duration : time := 1 sec / real(baud_rate);

begin

  RX_PROC : process
    variable tmp : std_logic_vector(7 downto 0);

  begin
    wait until falling_edge(rx);

    -- Wait until the middle of the first bit
    wait for symbol_duration * 1.5;

    -- Sample all bits
    for i in 0 to 7 loop
      tmp(i) := rx;
      wait for symbol_duration;
    end loop;

    -- Check the stop bit
    assert rx = '1'
      report "Stop bit should be '1'"
      severity failure;
    
    data_out <= tmp;
    data_out_valid <= true;
    wait for 0 ns;
    data_out_valid <= false;
  end process;

  TX_PROC : process
    variable tmp : std_logic_vector(7 downto 0);

  begin
    data_in_ready <= true;
    tx <= '1';
    wait until data_in_valid;
    tmp := data_in;
    data_in_ready <= false;

    -- Send start bit
    tx <= '0';
    wait for symbol_duration;
    
    -- Send data bits
    for i in 0 to 7 loop
      tx <= tmp(i);
      wait for symbol_duration;
    end loop;

    -- Send stop bit
    tx <= '1';
    wait for symbol_duration;

  end process;

end architecture;