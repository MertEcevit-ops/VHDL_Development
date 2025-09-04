library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_icestick is
  port (
    clk : in std_logic;
    rst_button : in std_logic; -- J3 connector, pin 44, pull-up
    uart_rx : in std_logic;
    uart_tx : out std_logic;
    led_1 : out std_logic; -- rx_fifo_full
    led_2 : out std_logic; -- rx_stop_bit_error
    led_3 : out std_logic;
    led_4 : out std_logic;
    led_5 : out std_logic -- Power LED
  );
end top_icestick;

architecture str of top_icestick is
begin

  led_3 <= '0';
  led_4 <= '0';
  led_5 <= '1';

  TOP : entity work.top(str)
    generic map (
      clk_hz => 12e6, -- The Lattice iCEstick oscillator is 12 MHz
      baud_rate => 115200,
      rst_in_active_value => '0'
    )
    port map (
      clk => clk,
      rst_in => rst_button,
      uart_rx => uart_rx,
      uart_tx => uart_tx,
      rx_fifo_full => led_1,
      rx_stop_bit_error => led_2
    );

end architecture;