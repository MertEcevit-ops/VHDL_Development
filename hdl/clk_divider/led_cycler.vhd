library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity led_cycler is
    port (
        clk_100_mhz : in  std_logic;
        rst_1_mhz   : in  std_logic;
        leds        : out std_logic_vector(7 downto 0)    
    );
end led_cycler;

architecture bhv of led_cycler is
    constant sreg_rst     : std_logic_vector(7 downto 0) := "00000001";
    signal sreg           : std_logic_vector(7 downto 0);

    constant counter_max  : integer := 1e6 - 1;
    signal counter        : integer range 0 to counter_max;

    type arr_type is array (0 to 18) of std_logic_vector(leds'range);
    signal arr           : arr_type;

    attribute dont_touch  : string;
    attribute dont_touch of arr : signal is "true";

begin
    arr(arr'high) <= sreg;
    leds          <= arr(0);

    shift_reg_proc : process(clk_100_mhz)
    begin
        if rising_edge(clk_100_mhz) then
            if rst_1_mhz = '1' then
                sreg     <= sreg_rst;
                counter  <= 0;
            else
                if counter = counter_max then
                    counter <= 0;
                    sreg    <= sreg(sreg'high - 1 downto 0) & sreg(sreg'high);
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Generate deep dummy logic
    DEEP_LOGIC_GEN : for i in 0 to arr'high - 1 generate
        arr(i) <= not arr(i + 1);
    end generate;

end bhv;