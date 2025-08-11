----------------------------------------------------------------------
-- BRAM Optimized FIFO Buffer with Full Attribute Set
-- Guaranteed BRAM usage with comprehensive synthesis directives
-- Optimized for Xilinx 7-series FPGAs (Basys3)
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        FIFO_DEPTH : integer := 512;      -- FIFO depth (must be power of 2 for BRAM)
        DATA_WIDTH : integer := 8         -- Data width in bits
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
        count      : out std_logic_vector(9 downto 0)
    );
end fifo;

architecture behavioral of fifo is
    
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
    
    -- BRAM memory array
    type bram_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bram_memory : bram_type := (others => (others => '0'));
    
    -- === BRAM INFERENCE ATTRIBUTES ===
    -- Force Block RAM usage (most important)
    attribute ram_style : string;
    attribute ram_style of bram_memory : signal is "block";
    
    -- Prevent distributed RAM inference
    attribute ram_extract : string;
    attribute ram_extract of bram_memory : signal is "yes";
    
    -- Control RAM decomposition
    attribute ram_decomp : string;
    attribute ram_decomp of bram_memory : signal is "power";
    
    -- === SYNTHESIS OPTIMIZATION ATTRIBUTES ===
    -- Keep hierarchy for better BRAM mapping
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of behavioral : architecture is "yes";
    
    -- FIFO pointers
    signal wr_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal rd_ptr : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    
    -- Prevent optimization of pointers
    attribute keep : string;
    attribute keep of wr_ptr : signal is "true";
    attribute keep of rd_ptr : signal is "true";
    
    -- FIFO status
    signal fifo_count : unsigned(ADDR_WIDTH downto 0) := (others => '0');
    signal full_flag  : std_logic := '0';
    signal empty_flag : std_logic := '1';
    
    -- BRAM output register for better timing
    signal bram_out_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    -- Ensure output register stays
    attribute keep of bram_out_reg : signal is "true";
    
    -- Internal control signals
    signal wr_en_int : std_logic;
    signal rd_en_int : std_logic;
    
    -- === TIMING OPTIMIZATION ATTRIBUTES ===
    -- Maximum fanout control
    attribute max_fanout : integer;
    attribute max_fanout of wr_en_int : signal is 1;
    attribute max_fanout of rd_en_int : signal is 1;
    
    -- === BRAM SPECIFIC ATTRIBUTES ===
    -- Control BRAM primitive selection
    attribute bram_map : string;
    attribute bram_map of bram_memory : signal is "yes";
    
    -- Block RAM utilization mode
    attribute ram_style_distributed : string;
    attribute ram_style_distributed of bram_memory : signal is "no";
    
begin
    
    -- Internal enable signals
    wr_en_int <= wr_en and not full_flag;
    rd_en_int <= rd_en and not empty_flag;
    
    -- === BRAM WRITE PROCESS ===
    bram_write_process : process(clk)
    begin
        if rising_edge(clk) then
            if wr_en_int = '1' then
                bram_memory(to_integer(wr_ptr)) <= wr_data;
            end if;
        end if;
    end process;
    
    -- Write process attributes
    --attribute ram_style of bram_write_process : label is "block";
    
    -- === BRAM READ PROCESS ===
    bram_read_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bram_out_reg <= (others => '0');
            else
                -- Always read for BRAM optimization
                bram_out_reg <= bram_memory(to_integer(rd_ptr));
            end if;
        end if;
    end process;
    
    -- Read process attributes
    --attribute ram_style of bram_read_process : label is "block";
    
    -- === WRITE POINTER MANAGEMENT ===
    write_pointer_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wr_ptr <= (others => '0');
            elsif wr_en_int = '1' then
                if wr_ptr = FIFO_DEPTH-1 then
                    wr_ptr <= (others => '0');
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- === READ POINTER MANAGEMENT ===
    read_pointer_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rd_ptr <= (others => '0');
            elsif rd_en_int = '1' then
                if rd_ptr = FIFO_DEPTH-1 then
                    rd_ptr <= (others => '0');
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- === FIFO COUNT MANAGEMENT ===
    status_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fifo_count <= (others => '0');
            else
                -- Use if-elsif structure for better synthesis
                if wr_en_int = '1' and rd_en_int = '0' then
                    -- Write only
                    fifo_count <= fifo_count + 1;
                elsif wr_en_int = '0' and rd_en_int = '1' then
                    -- Read only
                    fifo_count <= fifo_count - 1;
                elsif wr_en_int = '1' and rd_en_int = '1' then
                    -- Read and write simultaneously
                    fifo_count <= fifo_count;
                else
                    -- No operation
                    fifo_count <= fifo_count;
                end if;
            end if;
        end if;
    end process;
    
    -- === STATUS FLAGS GENERATION ===
    status_flags_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                full_flag <= '0';
                empty_flag <= '1';
            else
                -- Full flag
                if fifo_count = to_unsigned(FIFO_DEPTH, ADDR_WIDTH+1) then
                    full_flag <= '1';
                else
                    full_flag <= '0';
                end if;
                
                -- Empty flag
                if fifo_count = 0 then
                    empty_flag <= '1';
                else
                    empty_flag <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- === OUTPUT ASSIGNMENTS ===
    rd_data <= bram_out_reg;
    full <= full_flag;
    empty <= empty_flag;
    count <= std_logic_vector(resize(fifo_count, 10));
    
end behavioral;

-- === ARCHITECTURE LEVEL ATTRIBUTES ===
-- Overall synthesis strategy
--attribute syn_hier : string;
--attribute syn_hier of behavioral : architecture is "hard";

-- Keep design hierarchy
--attribute keep_hierarchy of behavioral : architecture is "yes";

-- Optimize for area
--attribute optimize : string;
--attribute optimize of behavioral : architecture is "area";