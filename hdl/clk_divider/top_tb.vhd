library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity top_tb is
end top_tb;

architecture sim of top_tb is

  constant clk_hz : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal ext_rst : std_logic := '1';
  signal leds : std_logic_vector(7 downto 0);

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.top(rtl)
    port map (
      clk_100_mhz => clk,
      ext_rst => ext_rst,
      leds => leds
    );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;

    ext_rst <= '0';

    wait for 3 sec;

    finish;
  end process;

end architecture;