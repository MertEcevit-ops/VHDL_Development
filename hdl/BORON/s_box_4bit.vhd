library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity s_box_4bit is
    port (
        data_i : in  std_logic_vector(3 downto 0);
        data_o : out std_logic_vector(3 downto 0)
    );
end s_box_4bit;

architecture Behavioral of s_box_4bit is
    type sbox_array is array (0 to 15) of std_logic_vector(3 downto 0);
    constant SBOX : sbox_array := (
        x"C", x"5", x"6", x"B", x"9", x"0", x"A", x"D",
        x"3", x"E", x"F", x"8", x"4", x"7", x"1", x"2"
    );
begin
    data_o <= SBOX(to_integer(unsigned(data_i)));
end Behavioral;