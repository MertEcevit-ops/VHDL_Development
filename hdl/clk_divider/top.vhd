library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
  port (
    clk_100_mhz : in std_logic; -- 100 MHz
    ext_rst : in std_logic; -- External reset button
    leds : out std_logic_vector(7 downto 0)
  );
end top;

architecture rtl of top is

  -- Synchronous reset
  signal rst : std_logic;

  signal clk_1_mhz : std_logic;

  signal leds_1_mhz_domain : std_logic_vector(7 downto 0);

begin

    -- TODO: Replace with clock divider
    clk_1_mhz <= clk_100_mhz;

  RESET_SYNC : entity work.reset_sync(rtl)
    generic map (
      rst_strobe_cycles => 2
    )
    port map (
      clk => clk_1_mhz,
      rst_in => ext_rst,
      rst_out => rst
    );

  LED_CYCLER : entity work.led_cycler(rtl)
    port map (
      clk_1_mhz => clk_1_mhz,
      rst_1_mhz => rst,
      leds => leds_1_mhz_domain
    );
  
  OUTPUT_PROC : process(clk_100_mhz)
  begin
    if rising_edge(clk_100_mhz) then
      leds <= leds_1_mhz_domain;
    end if;
  end process;

end architecture;