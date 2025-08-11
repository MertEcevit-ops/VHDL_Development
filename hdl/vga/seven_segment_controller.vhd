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
    
    -- Seven segment patterns (active low) - Updated based on reference image
    function ascii_to_7seg(ascii : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable segments : std_logic_vector(6 downto 0);
    begin
        case ascii is
            -- Numbers
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
            
            -- Uppercase letters
            when x"41" => segments := "0001000"; -- A
            when x"42" => segments := "0000011"; -- B
            when x"43" => segments := "1000110"; -- C
            when x"44" => segments := "0100001"; -- D
            when x"45" => segments := "0000110"; -- E
            when x"46" => segments := "0001110"; -- F
            when x"47" => segments := "1000010"; -- G
            when x"48" => segments := "0001011"; -- H
            when x"49" => segments := "1111001"; -- I
            when x"4A" => segments := "1110001"; -- J
            when x"4B" => segments := "0001011"; -- K (same as H)
            when x"4C" => segments := "1000111"; -- L
            when x"4D" => segments := "0001000"; -- M (same as A)
            when x"4E" => segments := "1001000"; -- N
            when x"4F" => segments := "1000000"; -- O
            when x"50" => segments := "0001100"; -- P
            when x"51" => segments := "0011000"; -- Q
            when x"52" => segments := "1001111"; -- R
            when x"53" => segments := "0010010"; -- S
            when x"54" => segments := "0000111"; -- T
            when x"55" => segments := "1000001"; -- U
            when x"56" => segments := "1000001"; -- V (same as U)
            when x"57" => segments := "1000001"; -- W (same as U)
            when x"58" => segments := "0001011"; -- X (same as H)
            when x"59" => segments := "0010001"; -- Y
            when x"5A" => segments := "0100100"; -- Z (same as 2)
            
            -- Lowercase letters
            when x"61" => segments := "0100000"; -- a
            when x"62" => segments := "0000011"; -- b
            when x"63" => segments := "0100111"; -- c
            when x"64" => segments := "0100001"; -- d
            when x"65" => segments := "0000110"; -- e
            when x"66" => segments := "0001110"; -- f
            when x"67" => segments := "1000010"; -- g
            when x"68" => segments := "0001011"; -- h
            when x"69" => segments := "1111001"; -- i
            when x"6A" => segments := "1110001"; -- j
            when x"6B" => segments := "0001011"; -- k (same as h)
            when x"6C" => segments := "1000111"; -- l
            when x"6D" => segments := "0101010"; -- m
            when x"6E" => segments := "0101011"; -- n
            when x"6F" => segments := "0100011"; -- o
            when x"70" => segments := "0001100"; -- p
            when x"71" => segments := "0011000"; -- q
            when x"72" => segments := "0101111"; -- r
            when x"73" => segments := "0010010"; -- s
            when x"74" => segments := "0000111"; -- t
            when x"75" => segments := "1100011"; -- u
            when x"76" => segments := "1100011"; -- v (same as u)
            when x"77" => segments := "1100011"; -- w (same as u)
            when x"78" => segments := "0001011"; -- x (same as h)
            when x"79" => segments := "0010001"; -- y
            when x"7A" => segments := "0100100"; -- z (same as 2)
            
            -- Special characters
            when x"20" => segments := "1111111"; -- Space (all off)
            when x"2D" => segments := "0111111"; -- - (dash)
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