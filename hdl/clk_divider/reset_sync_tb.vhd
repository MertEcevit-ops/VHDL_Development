library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use std.env.finish;

entity reset_sync_tb is
end reset_sync_tb;

architecture sim of reset_sync_tb is

  constant clk_hz : integer := 100e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst_in : std_logic := '0';
  signal rst_out : std_logic;

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.reset_sync(rtl)
  generic map (
    rst_strobe_cycles => 5
  )
  port map (
    clk => clk,
    rst_in => rst_in,
    rst_out => rst_out
  );

  SEQUENCER_PROC : process
  begin

    wait for clk_period * 100;

    rst_in <= '1';
    wait for clk_period;
    rst_in <= '0';
    
    wait for clk_period * 100;

    rst_in <= '1';
    wait for clk_period;
    rst_in <= '0';

    wait for clk_period * 100;
    finish;
  end process;

end architecture;