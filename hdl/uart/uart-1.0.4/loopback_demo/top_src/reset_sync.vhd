library ieee;
use ieee.std_logic_1164.all;

entity reset_sync is
  generic (
    -- Clock cycles to hold rst_out for after rst_in is released
    rst_strobe_cycles : positive := 128;

    -- The polarity of rst_in when reset is active
    rst_in_active_value : std_logic := '1';

    -- The desired polarity of rst_out when active
    rst_out_active_value : std_logic := '1'
  );
  port (
    clk : in std_logic; -- Slowest clock that uses rst_out
    rst_in : in std_logic;
    rst_out : out std_logic := rst_out_active_value
  );
end reset_sync;

architecture rtl of reset_sync is

  constant counter_max : integer := rst_strobe_cycles - 1;
  signal counter : integer range 0 to counter_max;

  signal rst_in_p1 : std_logic;
  signal rst_in_p2 : std_logic;

  -- Avoid pruning of registers if rst_in is set to a constant instead of a pin
  -- (Synthesis attribute for Synopsis/Synplify Pro)
  attribute syn_preserve : boolean;
  attribute syn_preserve of rst_in_p2 : signal is true;

begin

  -- 2FF synchronizer to avoid metastability
  SYNC_PROC : process(clk)
  begin
    if rising_edge(clk) then
      rst_in_p2 <= rst_in_p1;
      rst_in_p1 <= rst_in;
    end if;
  end process;

  -- Generate the rst_out signal
  RST_OUT_PROC : process(clk)
  begin
    if rising_edge(clk) then

      -- Synchronous reset
      if rst_in_p2 = rst_in_active_value then
        rst_out <= rst_out_active_value;
        counter <= 0;

      else

        -- Keep rst_out active for N clock cycles
        if counter = counter_max then
          rst_out <= not rst_out_active_value;
        else
          counter <= counter + 1;
        end if;

      end if;
    end if;
  end process;

end architecture;