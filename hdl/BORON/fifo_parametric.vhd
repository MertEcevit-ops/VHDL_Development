library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity fifo_parametric is
    generic (
        WIDTH : integer := 8;   -- Data width
        DEPTH : integer := 16   -- FIFO depth
    );
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;  -- active low
        wr_enable_i : in  std_logic;
        rd_enable_i : in  std_logic;
        din_i       : in  std_logic_vector(WIDTH-1 downto 0);
        dout_o      : out std_logic_vector(WIDTH-1 downto 0);
        empty_o     : out std_logic;
        full_o      : out std_logic
    );
end fifo_parametric;

architecture Behavioral of fifo_parametric is
    constant PTR_WIDTH : integer := integer(ceil(log2(real(DEPTH))));
    constant CNT_WIDTH : integer := integer(ceil(log2(real(DEPTH + 1))));
    
    type mem_type is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);
    signal mem : mem_type;
    
    signal wptr : unsigned(PTR_WIDTH-1 downto 0);
    signal rptr : unsigned(PTR_WIDTH-1 downto 0);
    signal cnt  : unsigned(CNT_WIDTH-1 downto 0);
    
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            wptr   <= (others => '0');
            rptr   <= (others => '0');
            cnt    <= (others => '0');
            dout_o <= (others => '0');
        elsif rising_edge(clk_i) then
            if wr_enable_i = '1' and rd_enable_i = '1' and full_o = '0' and empty_o = '0' then
                -- Simultaneous read and write
                mem(to_integer(wptr)) <= din_i;
                dout_o <= mem(to_integer(rptr));
                wptr <= wptr + 1;
                rptr <= rptr + 1;
            elsif wr_enable_i = '1' and full_o = '0' then
                -- Write only
                mem(to_integer(wptr)) <= din_i;
                wptr <= wptr + 1;
                cnt <= cnt + 1;
            elsif rd_enable_i = '1' and empty_o = '0' then
                -- Read only
                dout_o <= mem(to_integer(rptr));
                rptr <= rptr + 1;
                cnt <= cnt - 1;
            end if;
        end if;
    end process;
    
    empty_o <= '1' when cnt = 0 else '0';
    full_o  <= '1' when cnt = DEPTH else '0';
end Behavioral;