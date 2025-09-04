library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_de10_lite is
  port (
    MAX10_CLK2_50 : in std_logic;
    LEDR : out std_logic_vector(9 downto 0);
    ARDUINO_IO : inout std_logic_vector(15 downto 0)
  );
end top_de10_lite;

architecture str of top_de10_lite is
begin

  LEDR(9 downto 2) <= (others => '0');

  TOP : entity work.top(str)
    generic map (
      clk_hz => 50e6,
      baud_rate => 115200,
      rst_in_active_value => '0'
    )
    port map (
      clk => MAX10_CLK2_50,
      rst_in => '1',
      uart_rx => ARDUINO_IO(12),
      uart_tx => ARDUINO_IO(13),
      rx_fifo_full => LEDR(0),
      rx_stop_bit_error => LEDR(1)
    );

end architecture;