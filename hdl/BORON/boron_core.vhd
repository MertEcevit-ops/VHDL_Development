library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity boron_core is
    port (
        clk_i         : in  std_logic;
        rst_ni        : in  std_logic;
        start_i       : in  std_logic;
        plain_text_i  : in  std_logic_vector(63 downto 0);
        key_i         : in  std_logic_vector(79 downto 0);
        cipher_text_o : out std_logic_vector(63 downto 0);
        done_o        : out std_logic
    );
end boron_core;

architecture Behavioral of boron_core is
    component boron_key_scheduler is
        port (clk_i, rst_ni : in std_logic;
              key_i : in std_logic_vector(79 downto 0);
              round_cnt_i : in unsigned(4 downto 0);
              key_o : out std_logic_vector(79 downto 0));
    end component;
    
    component boron_round_function is
        port (data_i, round_key_i : in std_logic_vector(63 downto 0);
              data_o : out std_logic_vector(63 downto 0));
    end component;
    
    signal current_key     : std_logic_vector(79 downto 0);
    signal round_key       : std_logic_vector(63 downto 0);
    signal current_data    : std_logic_vector(63 downto 0);
    signal next_data       : std_logic_vector(63 downto 0);
    signal round_counter   : unsigned(4 downto 0);
    signal active          : std_logic;
    
begin
    -- Extract round key (LSB 64 bits from 80-bit key)
    round_key <= current_key(63 downto 0);
    
    -- Key Scheduler
    key_sched: boron_key_scheduler
        port map (
            clk_i       => clk_i,
            rst_ni      => rst_ni,
            key_i       => key_i,
            round_cnt_i => round_counter,
            key_o       => current_key
        );
    
    -- Round Function
    round_func: boron_round_function
        port map (
            data_i      => current_data,
            round_key_i => round_key,
            data_o      => next_data
        );
    
    -- Control and data process
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            current_data  <= (others => '0');
            round_counter <= (others => '0');
            active        <= '0';
            done_o        <= '0';
        elsif rising_edge(clk_i) then
            done_o <= '0';
            
            if start_i = '1' and active = '0' then
                active        <= '1';
                current_data  <= plain_text_i;
                round_counter <= (others => '0');
            elsif active = '1' then
                if round_counter = 24 then -- 25 rounds (0-24)
                    active <= '0';
                    done_o <= '1';
                else
                    current_data  <= next_data;
                    round_counter <= round_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    cipher_text_o <= current_data;
end Behavioral;