library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_arty_a7_35t is
  port (
    clk : in std_logic;
    rst_button : in std_logic; -- The "RESET" button on the board
    uart_rx : in std_logic;
    uart_tx : out std_logic;
    led : out std_logic_vector(3 downto 0)
  );
end top_arty_a7_35t;

architecture str of top_arty_a7_35t is
begin

  led(2) <= '0';
  led(3) <= '0';

  TOP : entity work.top(str)
    generic map (
      clk_hz => 100e6,
      baud_rate => 115200,
      rst_in_active_value => '0'
    )
    port map (
      clk => clk,
      rst_in => rst_button,
      uart_rx => uart_rx,
      uart_tx => uart_tx,
      rx_fifo_full => led(0),
      rx_stop_bit_error => led(1)
    );

end architecture;