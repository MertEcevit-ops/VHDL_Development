library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity boron_round_function is
    port (
        data_i      : in  std_logic_vector(63 downto 0);
        round_key_i : in  std_logic_vector(63 downto 0);
        data_o      : out std_logic_vector(63 downto 0)
    );
end boron_round_function;

architecture Behavioral of boron_round_function is
    component s_box_4bit is
        port (data_i : in std_logic_vector(3 downto 0);
              data_o : out std_logic_vector(3 downto 0));
    end component;
    
    signal xor_result     : std_logic_vector(63 downto 0);
    signal sbox_result    : std_logic_vector(63 downto 0);
    signal shuffle_result : std_logic_vector(63 downto 0);
    
begin
    -- Step 1: XOR with round key
    xor_result <= data_i xor round_key_i;
    
    -- Step 2: S-box substitution (16 S-boxes for 64-bit data)
    sbox_gen: for i in 0 to 15 generate
        sbox_inst: s_box_4bit
            port map (
                data_i => xor_result(4*i+3 downto 4*i),
                data_o => sbox_result(4*i+3 downto 4*i)
            );
    end generate;
    
    -- Step 3: Block Shuffle and Round Permutation
    shuffle_result(63 downto 32) <= sbox_result(31 downto 0);
    shuffle_result(31 downto 0)  <= sbox_result(63 downto 32);
    
    data_o <= shuffle_result;
end Behavioral;