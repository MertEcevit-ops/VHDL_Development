library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity boron_key_scheduler is
    port (
        clk_i       : in  std_logic;
        rst_ni      : in  std_logic;
        key_i       : in  std_logic_vector(79 downto 0);
        round_cnt_i : in  unsigned(4 downto 0);
        key_o       : out std_logic_vector(79 downto 0)
    );
end boron_key_scheduler;

architecture Behavioral of boron_key_scheduler is
    component s_box_4bit is
        port (data_i : in std_logic_vector(3 downto 0);
              data_o : out std_logic_vector(3 downto 0));
    end component;
    
    signal key_reg      : std_logic_vector(79 downto 0);
    signal key_shifted  : std_logic_vector(79 downto 0);
    signal key_sboxed   : std_logic_vector(79 downto 0);
    signal key_xored    : std_logic_vector(79 downto 0);
    
begin
    -- Round shift (left rotate by 1)
    key_shifted <= key_reg(78 downto 0) & key_reg(79);
    
    -- S-box substitution for most significant 4 bits
    sbox_inst: s_box_4bit
        port map (
            data_i => key_shifted(79 downto 76),
            data_o => key_sboxed(79 downto 76)
        );
    
    key_sboxed(75 downto 0) <= key_shifted(75 downto 0);
    
    -- XOR with round counter
    key_xored(79 downto 5) <= key_sboxed(79 downto 5);
    key_xored(4 downto 0) <= key_sboxed(4 downto 0) xor std_logic_vector(round_cnt_i);
    
    -- Key register process
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            key_reg <= (others => '0');
        elsif rising_edge(clk_i) then
            if round_cnt_i = 0 then
                key_reg <= key_i;
            else
                key_reg <= key_xored;
            end if;
        end if;
    end process;
    
    key_o <= key_reg;
end Behavioral;