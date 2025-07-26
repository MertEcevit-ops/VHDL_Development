

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_clock is
    generic (
        -- Clock frequencies in Hz
        SYS_CLK_FREQ    : integer := 100_000_000;   -- System clock frequency (100MHz)
        PIXEL_CLK_FREQ  : integer := 25_000_000;    -- Target pixel clock frequency (25MHz)
        
        -- Counter width (automatically calculated but can be overridden)
        COUNTER_WIDTH   : integer := 8              -- Width of the counter
    );
    port (
        sys_clk         : in  std_logic;            -- System clock input
        reset           : in  std_logic;            -- Synchronous reset
        
        -- Clock outputs
        pixel_clk       : out std_logic;            -- Generated pixel clock
        pixel_clk_x2    : out std_logic;            -- 2x pixel clock (for DDR operations)
        
        -- Status outputs
        clk_locked      : out std_logic             -- Clock generation locked/stable
    );
end vga_clock;

architecture behavioral of vga_clock is
    
    -- Calculate clock division ratio
    constant DIVISOR        : integer := SYS_CLK_FREQ / PIXEL_CLK_FREQ;
    constant HALF_DIVISOR   : integer := DIVISOR / 2;
    constant QUARTER_DIVISOR: integer := DIVISOR / 4;
    
    -- Counter for clock division
    signal clk_counter      : integer range 0 to DIVISOR-1 := 0;
    
    -- Generated clock signals
    signal pixel_clk_reg    : std_logic := '0';
    signal pixel_clk_x2_reg : std_logic := '0';
    
    -- Lock detection
    signal lock_counter     : integer range 0 to 1023 := 0;
    signal clk_locked_reg   : std_logic := '0';
    
    -- Clock enable signals for different phases
    signal clk_en_pixel     : std_logic := '0';
    signal clk_en_pixel_x2  : std_logic := '0';
    
begin
    
    -- Main clock division process
    clock_division_process : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if reset = '1' then
                clk_counter <= 0;
                pixel_clk_reg <= '0';
                pixel_clk_x2_reg <= '0';
                clk_en_pixel <= '0';
                clk_en_pixel_x2 <= '0';
                
            else
                -- Default enable signals
                clk_en_pixel <= '0';
                clk_en_pixel_x2 <= '0';
                
                -- Counter increment
                if clk_counter = DIVISOR-1 then
                    clk_counter <= 0;
                else
                    clk_counter <= clk_counter + 1;
                end if;
                
                -- Generate pixel clock (divide by DIVISOR)
                if clk_counter = HALF_DIVISOR-1 then
                    pixel_clk_reg <= '1';
                    clk_en_pixel <= '1';
                elsif clk_counter = DIVISOR-1 then
                    pixel_clk_reg <= '0';
                end if;
                
                -- Generate 2x pixel clock (divide by DIVISOR/2)
                if clk_counter = QUARTER_DIVISOR-1 then
                    pixel_clk_x2_reg <= '1';
                    clk_en_pixel_x2 <= '1';
                elsif clk_counter = QUARTER_DIVISOR + HALF_DIVISOR-1 then
                    pixel_clk_x2_reg <= '0';
                elsif clk_counter = (3*QUARTER_DIVISOR)-1 then
                    pixel_clk_x2_reg <= '1';
                    clk_en_pixel_x2 <= '1';
                elsif clk_counter = DIVISOR-1 then
                    pixel_clk_x2_reg <= '0';
                end if;
                
            end if;
        end if;
    end process clock_division_process;
    
    -- Clock lock detection process
    lock_detection_process : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if reset = '1' then
                lock_counter <= 0;
                clk_locked_reg <= '0';
                
            else
                -- Count stable clock cycles
                if lock_counter = 1023 then
                    clk_locked_reg <= '1';
                else
                    lock_counter <= lock_counter + 1;
                end if;
                
            end if;
        end if;
    end process lock_detection_process;
    
    -- Output assignments
    pixel_clk <= pixel_clk_reg;
    pixel_clk_x2 <= pixel_clk_x2_reg;
    clk_locked <= clk_locked_reg;
    
    -- Synthesis attributes for better clock generation
    attribute KEEP : string;
    attribute KEEP of pixel_clk_reg : signal is "TRUE";
    attribute KEEP of pixel_clk_x2_reg : signal is "TRUE";
    
end behavioral;
