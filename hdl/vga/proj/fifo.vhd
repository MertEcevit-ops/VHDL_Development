----------------------------------------------------------------------
-- FIFO Buffer Module
-- Generic FIFO for UART buffering
-- Configurable depth and data width
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_buffer is
    generic (
        FIFO_DEPTH : integer := 16;    -- FIFO depth (must be power of 2)
        DATA_WIDTH : integer := 8      -- Data width in bits
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        
        -- Write interface
        wr_en      : in  std_logic;
        wr_data    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read interface  
        rd_en      : in  std_logic;
        rd_data    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Status flags
        full       : out std_logic;
        empty      : out std_logic;
        count      : out std_logic_vector(4 downto 0)  -- Assumes max 32 depth
    );
end fifo_buffer;

architecture behavioral of fifo_buffer is
    
    -- Calculate address width based on depth
    function clog2(depth : integer) return integer is
        variable temp : integer := depth;
        variable ret_val : integer := 0;
    begin
        while temp > 1 loop
            ret_val := ret_val + 1;
            temp := temp / 2;
        end loop;
        return ret_val;
    end function;
    
    constant ADDR_WIDTH : integer := clog2(FIFO_DEPTH);
    
    -- FIFO memory array
    type fifo_mem_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_mem : fifo_mem_type := (others => (others => '0'));
    
    -- FIFO pointers
    signal wr_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal rd_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    
    -- FIFO status
    signal fifo_count : unsigned(ADDR_WIDTH downto 0) := (others => '0');
    signal full_flag  : std_logic := '0';
    signal empty_flag : std_logic := '1';
    
begin
    
    -- FIFO write process
    write_process : process(clk, rst)
    begin
        if rst = '1' then
            wr_ptr <= (others => '0');
            fifo_mem <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if wr_en = '1' and full_flag = '0' then
                fifo_mem(to_integer(wr_ptr)) <= wr_data;
                if wr_ptr = FIFO_DEPTH-1 then
                    wr_ptr <= (others => '0');
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- FIFO read process
    read_process : process(clk, rst)
    begin
        if rst = '1' then
            rd_ptr <= (others => '0');
            rd_data <= (others => '0');
        elsif rising_edge(clk) then
            if rd_en = '1' and empty_flag = '0' then
                rd_data <= fifo_mem(to_integer(rd_ptr));
                if rd_ptr = FIFO_DEPTH-1 then
                    rd_ptr <= (others => '0');
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- FIFO count and status flags
    status_process : process(clk, rst)
    begin
        if rst = '1' then
            fifo_count <= (others => '0');
        elsif rising_edge(clk) then
            case (wr_en and not full_flag) & (rd_en and not empty_flag) is
                when "10" => -- Write only
                    fifo_count <= fifo_count + 1;
                when "01" => -- Read only
                    fifo_count <= fifo_count - 1;
                when "11" => -- Read and write
                    fifo_count <= fifo_count;
                when others => -- No operation
                    fifo_count <= fifo_count;
            end case;
        end if;
    end process;
    
    -- Status flag assignments
    full_flag <= '1' when fifo_count = FIFO_DEPTH else '0';
    empty_flag <= '1' when fifo_count = 0 else '0';
    
    -- Output assignments
    full <= full_flag;
    empty <= empty_flag;
    count <= std_logic_vector(resize(fifo_count, 5));
    
end behavioral;