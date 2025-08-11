----------------------------------------------------------------------
-- VGA Pattern Generator
-- Generic test pattern generator for VGA displays
-- Supports multiple patterns with configurable color depth
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_pattern is
    generic (
        -- Screen resolution
        H_ACTIVE        : integer := 640;       -- Screen width in pixels
        V_ACTIVE        : integer := 480;       -- Screen height in pixels
        
        -- Color configuration
        COLOR_DEPTH     : integer := 12;        -- Total color bits (4 bits per R,G,B)
        
        -- Pattern configuration
        PATTERN_NUM     : integer := 8          -- Number of available patterns
    );
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        
        -- Position inputs from sync generator
        pixel_x         : in  integer range 0 to H_ACTIVE-1;
        pixel_y         : in  integer range 0 to V_ACTIVE-1;
        display_en      : in  std_logic;
        
        -- Pattern selection
        pattern_sel     : in  integer range 0 to PATTERN_NUM-1;
        
        -- Color outputs
        red             : out std_logic_vector(COLOR_DEPTH/3-1 downto 0);
        green           : out std_logic_vector(COLOR_DEPTH/3-1 downto 0);
        blue            : out std_logic_vector(COLOR_DEPTH/3-1 downto 0)
    );
end vga_pattern;

architecture behavioral of vga_pattern is
    
    -- Color width for each channel
    constant COLOR_WIDTH : integer := COLOR_DEPTH/3;
    constant MAX_COLOR   : std_logic_vector(COLOR_WIDTH-1 downto 0) := (others => '1');
    constant MIN_COLOR   : std_logic_vector(COLOR_WIDTH-1 downto 0) := (others => '0');
    
    -- Pattern array types
    type color_pattern_array is array (0 to PATTERN_NUM-1) of std_logic_vector(COLOR_WIDTH-1 downto 0);
    
    -- Pattern storage signals
    signal red_patterns   : color_pattern_array;
    signal green_patterns : color_pattern_array;
    signal blue_patterns  : color_pattern_array;
    
    -- Helper signals for pattern generation
    signal checkerboard_bit : std_logic;
    signal color_bar_select : integer range 0 to 7;
    signal bar_width        : integer;
    signal border_condition : std_logic;
    signal gradient_red     : std_logic_vector(COLOR_WIDTH-1 downto 0);
    signal gradient_green   : std_logic_vector(COLOR_WIDTH-1 downto 0);
    
    -- Convert integers to unsigned for bit indexing
    signal pixel_x_u : unsigned(9 downto 0);  -- 10 bits for up to 1024
    signal pixel_y_u : unsigned(9 downto 0);  -- 10 bits for up to 1024
    
begin
    
    -- Convert integer coordinates to unsigned
    pixel_x_u <= to_unsigned(pixel_x, 10);
    pixel_y_u <= to_unsigned(pixel_y, 10);
    
    -- Calculate helper signals
    bar_width <= H_ACTIVE / 8;
    
    -- Checkerboard pattern (32x32 pixel squares) - Fixed bit indexing
    checkerboard_bit <= pixel_x_u(5) xor pixel_y_u(5);
    
    -- Color bar selection
    color_bar_select <= 0 when pixel_x < bar_width*1 else
                       1 when pixel_x < bar_width*2 else
                       2 when pixel_x < bar_width*3 else
                       3 when pixel_x < bar_width*4 else
                       4 when pixel_x < bar_width*5 else
                       5 when pixel_x < bar_width*6 else
                       6 when pixel_x < bar_width*7 else
                       7;
    
    -- Border condition (2 pixel border)
    border_condition <= '1' when (pixel_x <= 1 or pixel_x >= H_ACTIVE-2 or
                                 pixel_y <= 1 or pixel_y >= V_ACTIVE-2) else '0';
    
    -- Gradient colors
    gradient_red <= std_logic_vector(to_unsigned(
        (pixel_x * (2**COLOR_WIDTH-1)) / H_ACTIVE, COLOR_WIDTH));
    gradient_green <= std_logic_vector(to_unsigned(
        (pixel_y * (2**COLOR_WIDTH-1)) / V_ACTIVE, COLOR_WIDTH));
    
    -- Pattern generation process
    pattern_generation : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                red_patterns   <= (others => MIN_COLOR);
                green_patterns <= (others => MIN_COLOR);
                blue_patterns  <= (others => MIN_COLOR);
            else
                -- Generate all patterns in parallel
                
                -- Pattern 0: Black (disabled)
                red_patterns(0)   <= MIN_COLOR;
                green_patterns(0) <= MIN_COLOR;
                blue_patterns(0)  <= MIN_COLOR;
                
                -- Pattern 1: Solid Red
                if display_en = '1' then
                    red_patterns(1)   <= MAX_COLOR;
                    green_patterns(1) <= MIN_COLOR;
                    blue_patterns(1)  <= MIN_COLOR;
                else
                    red_patterns(1)   <= MIN_COLOR;
                    green_patterns(1) <= MIN_COLOR;
                    blue_patterns(1)  <= MIN_COLOR;
                end if;
                
                -- Pattern 2: Solid Green
                if display_en = '1' then
                    red_patterns(2)   <= MIN_COLOR;
                    green_patterns(2) <= MAX_COLOR;
                    blue_patterns(2)  <= MIN_COLOR;
                else
                    red_patterns(2)   <= MIN_COLOR;
                    green_patterns(2) <= MIN_COLOR;
                    blue_patterns(2)  <= MIN_COLOR;
                end if;
                
                -- Pattern 3: Solid Blue
                if display_en = '1' then
                    red_patterns(3)   <= MIN_COLOR;
                    green_patterns(3) <= MIN_COLOR;
                    blue_patterns(3)  <= MAX_COLOR;
                else
                    red_patterns(3)   <= MIN_COLOR;
                    green_patterns(3) <= MIN_COLOR;
                    blue_patterns(3)  <= MIN_COLOR;
                end if;
                
                -- Pattern 4: Checkerboard (White/Black)
                if display_en = '1' and checkerboard_bit = '1' then
                    red_patterns(4)   <= MAX_COLOR;
                    green_patterns(4) <= MAX_COLOR;
                    blue_patterns(4)  <= MAX_COLOR;
                else
                    red_patterns(4)   <= MIN_COLOR;
                    green_patterns(4) <= MIN_COLOR;
                    blue_patterns(4)  <= MIN_COLOR;
                end if;
                
                -- Pattern 5: Color Bars
                if display_en = '1' then
                    -- RGB truth table implementation
                    if color_bar_select = 4 or color_bar_select = 5 or 
                       color_bar_select = 6 or color_bar_select = 7 then
                        red_patterns(5) <= MAX_COLOR;
                    else
                        red_patterns(5) <= MIN_COLOR;
                    end if;
                    
                    if color_bar_select = 2 or color_bar_select = 3 or
                       color_bar_select = 6 or color_bar_select = 7 then
                        green_patterns(5) <= MAX_COLOR;
                    else
                        green_patterns(5) <= MIN_COLOR;
                    end if;
                    
                    if color_bar_select = 1 or color_bar_select = 3 or
                       color_bar_select = 5 or color_bar_select = 7 then
                        blue_patterns(5) <= MAX_COLOR;
                    else
                        blue_patterns(5) <= MIN_COLOR;
                    end if;
                else
                    red_patterns(5)   <= MIN_COLOR;
                    green_patterns(5) <= MIN_COLOR;
                    blue_patterns(5)  <= MIN_COLOR;
                end if;
                
                -- Pattern 6: White Border with Black Center
                if display_en = '1' and border_condition = '1' then
                    red_patterns(6)   <= MAX_COLOR;
                    green_patterns(6) <= MAX_COLOR;
                    blue_patterns(6)  <= MAX_COLOR;
                else
                    red_patterns(6)   <= MIN_COLOR;
                    green_patterns(6) <= MIN_COLOR;
                    blue_patterns(6)  <= MIN_COLOR;
                end if;
                
                -- Pattern 7: Gradient
                if display_en = '1' then
                    red_patterns(7)   <= gradient_red;
                    green_patterns(7) <= gradient_green;
                    blue_patterns(7)  <= MIN_COLOR;
                else
                    red_patterns(7)   <= MIN_COLOR;
                    green_patterns(7) <= MIN_COLOR;
                    blue_patterns(7)  <= MIN_COLOR;
                end if;
                
            end if;
        end if;
    end process pattern_generation;
    
    -- Pattern selection output
    pattern_selection : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                red   <= MIN_COLOR;
                green <= MIN_COLOR;
                blue  <= MIN_COLOR;
            else
                red   <= red_patterns(pattern_sel);
                green <= green_patterns(pattern_sel);
                blue  <= blue_patterns(pattern_sel);
            end if;
        end if;
    end process pattern_selection;
    
end behavioral;