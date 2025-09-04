----------------------------------------------------------------------
-- Fixed VGA Timing Generator
-- Generates 640x480@60Hz timing signals with proper sync polarities
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_timing is
    generic (
        -- Horizontal timing
        H_TOTAL     : integer := 800;
        H_ACTIVE    : integer := 640;   -- Active pixels
        H_FRONT     : integer := 16;    -- Front porch
        H_SYNC      : integer := 96;    -- Sync pulse width
        H_BACK      : integer := 48;    -- Back porch
        H_POLARITY  : std_logic := '0'; -- Sync polarity

        -- Vertical timing  
        V_TOTAL     : integer := 525;
        V_ACTIVE    : integer := 480;   -- Active lines
        V_FRONT     : integer := 10;    -- Front porch
        V_SYNC      : integer := 2;     -- Sync pulse width
        V_BACK      : integer := 33;    -- Back porch
        V_POLARITY  : std_logic := '0'  -- Sync polarity
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Timing outputs
        hsync       : out std_logic;
        vsync       : out std_logic;
        display_en  : out std_logic;    -- When to show pixels
        
        -- Position outputs
        pixel_x     : out integer range 0 to H_TOTAL-1;
        pixel_y     : out integer range 0 to V_TOTAL-1
    );
end entity vga_timing;

architecture behavioral of vga_timing is
    
    -- Counters
    signal h_count : integer range 0 to H_TOTAL-1 := 0;
    signal v_count : integer range 0 to V_TOTAL-1 := 0;
    
    -- Sync signal generation
    signal hsync_int : std_logic;
    signal vsync_int : std_logic;
    
begin
    
    -- Horizontal and vertical counters
    timing_counters : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                h_count <= 0;
                v_count <= 0;
            else
                -- Horizontal counter
                if h_count = H_TOTAL-1 then
                    h_count <= 0;
                    -- Vertical counter
                    if v_count = V_TOTAL-1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process timing_counters;
    
    -- Generate horizontal sync
    hsync_generation : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                hsync_int <= not H_POLARITY;
            else
                if (h_count >= H_ACTIVE + H_FRONT) and 
                   (h_count < H_ACTIVE + H_FRONT + H_SYNC) then
                    hsync_int <= H_POLARITY;
                else
                    hsync_int <= not H_POLARITY;
                end if;
            end if;
        end if;
    end process hsync_generation;
    
    -- Generate vertical sync
    vsync_generation : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                vsync_int <= not V_POLARITY;
            else
                if (v_count >= V_ACTIVE + V_FRONT) and 
                   (v_count < V_ACTIVE + V_FRONT + V_SYNC) then
                    vsync_int <= V_POLARITY;
                else
                    vsync_int <= not V_POLARITY;
                end if;
            end if;
        end if;
    end process vsync_generation;
    
    -- Generate display enable
    display_enable_generation : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                display_en <= '0';
            else
                if (h_count < H_ACTIVE) and (v_count < V_ACTIVE) then
                    display_en <= '1';
                else
                    display_en <= '0';
                end if;
            end if;
        end if;
    end process display_enable_generation;
    
    -- Output assignments
    hsync <= hsync_int;
    vsync <= vsync_int;
    pixel_x <= h_count;
    pixel_y <= v_count;
    
end behavioral;