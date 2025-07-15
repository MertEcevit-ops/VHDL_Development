----------------------------------------------------------------------
-- Seven Segment Display Controller
-- Converts ASCII character to 7-segment display pattern
-- Supports 0-9, A-F characters
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_segment_controller is
    port (
        i_clk        : in  std_logic;
        i_rst        : in  std_logic;
        i_ascii_char : in  std_logic_vector(7 downto 0);
        i_char_valid : in  std_logic;
        o_segments   : out std_logic_vector(6 downto 0);  -- a,b,c,d,e,f,g
        o_anodes     : out std_logic_vector(3 downto 0)   -- digit select
    );
end seven_segment_controller;

architecture behavioral of seven_segment_controller is
    
    -- Display refresh counter (for multiplexing)
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select    : unsigned(1 downto 0) := (others => '0');
    
    -- Character storage for 4 digits
    signal char_buffer : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Current character to display
    signal current_char : std_logic_vector(7 downto 0);
    
    -- Seven segment patterns (active low)
    function ascii_to_7seg(ascii : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable segments : std_logic_vector(6 downto 0);
    begin
        case ascii is
            when x"30" => segments := "1000000"; -- 0
            when x"31" => segments := "1111001"; -- 1
            when x"32" => segments := "0100100"; -- 2
            when x"33" => segments := "0110000"; -- 3
            when x"34" => segments := "0011001"; -- 4
            when x"35" => segments := "0010010"; -- 5
            when x"36" => segments := "0000010"; -- 6
            when x"37" => segments := "1111000"; -- 7
            when x"38" => segments := "0000000"; -- 8
            when x"39" => segments := "0010000"; -- 9
            when x"41" | x"61" => segments := "0001000"; -- A/a
            when x"42" | x"62" => segments := "0000011"; -- B/b
            when x"43" | x"63" => segments := "1000110"; -- C/c
            when x"44" | x"64" => segments := "0100001"; -- D/d
            when x"45" | x"65" => segments := "0000110"; -- E/e
            when x"46" | x"66" => segments := "0001110"; -- F/f
            when x"47" | x"67" => segments := "0010000"; -- G/g (same as 9)
            when x"48" | x"68" => segments := "0001011"; -- H/h
            when x"49" | x"69" => segments := "1111001"; -- I/i (same as 1)
            when x"4A" | x"6A" => segments := "1110001"; -- J/j
            when x"4C" | x"6C" => segments := "1000111"; -- L/l
            when x"4E" | x"6E" => segments := "0001001"; -- N/n
            when x"4F" | x"6F" => segments := "1000000"; -- O/o (same as 0)
            when x"50" | x"70" => segments := "0001100"; -- P/p
            when x"52" | x"72" => segments := "0001111"; -- R/r
            when x"53" | x"73" => segments := "0010010"; -- S/s (same as 5)
            when x"54" | x"74" => segments := "0000111"; -- T/t
            when x"55" | x"75" => segments := "1000001"; -- U/u
            when x"59" | x"79" => segments := "0010001"; -- Y/y
            when x"20" => segments := "1111111"; -- Space (all off)
            when others => segments := "0111111"; -- - (dash for unknown)
        end case;
        return segments;
    end function;
    
begin
    
    -- Character buffer shift process
    char_buffer_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            char_buffer <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_char_valid = '1' then
                -- Shift left and add new character
                char_buffer(31 downto 24) <= char_buffer(23 downto 16);
                char_buffer(23 downto 16) <= char_buffer(15 downto 8);
                char_buffer(15 downto 8)  <= char_buffer(7 downto 0);
                char_buffer(7 downto 0)   <= i_ascii_char;
            end if;
        end if;
    end process;
    
    -- Display refresh process
    refresh_process : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            refresh_counter <= (others => '0');
            digit_select <= (others => '0');
        elsif rising_edge(i_clk) then
            refresh_counter <= refresh_counter + 1;
            
            -- Change digit every ~2.6ms (100MHz / 2^18)
            if refresh_counter(17 downto 16) = "11" then
                digit_select <= digit_select + 1;
                refresh_counter <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Digit selection multiplexer
    digit_mux_process : process(digit_select, char_buffer)
    begin
        case digit_select is
            when "00" => 
                current_char <= char_buffer(7 downto 0);   -- Rightmost digit
                o_anodes <= "1110";
            when "01" => 
                current_char <= char_buffer(15 downto 8);  -- Second digit
                o_anodes <= "1101";
            when "10" => 
                current_char <= char_buffer(23 downto 16); -- Third digit
                o_anodes <= "1011";
            when "11" => 
                current_char <= char_buffer(31 downto 24); -- Leftmost digit
                o_anodes <= "0111";
            when others => 
                current_char <= (others => '0');
                o_anodes <= "1111";
        end case;
    end process;
    
    -- Seven segment decoder
    o_segments <= ascii_to_7seg(current_char);
    
end behavioral;