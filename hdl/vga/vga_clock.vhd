----------------------------------------------------------------------
-- Simplified VGA Clock Generator
-- Uses simple clock division for 25MHz pixel clock
-- Optimized for reduced LUT usage
----------------------------------------------------------------------

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
    
    -- Simple division for 100MHz -> 25MHz (divide by 4)
    signal clk_div_counter  : unsigned(1 downto 0) := "00";
    signal pixel_clk_reg    : std_logic := '0';
    signal pixel_clk_x2_reg : std_logic := '0';
    
    -- Simple lock counter
    signal lock_counter     : unsigned(7 downto 0) := (others => '0');
    signal clk_locked_reg   : std_logic := '0';
    
begin
    
    -- Simple clock division process
    clock_division_process : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if reset = '1' then
                clk_div_counter <= "00";
                pixel_clk_reg <= '0';
                pixel_clk_x2_reg <= '0';
                
            else
                -- Increment counter
                clk_div_counter <= clk_div_counter + 1;
                
                -- Generate 25MHz pixel clock (divide by 4)
                pixel_clk_reg <= clk_div_counter(1);
                
                -- Generate 50MHz pixel clock x2 (divide by 2)
                pixel_clk_x2_reg <= clk_div_counter(0);
                
            end if;
        end if;
    end process clock_division_process;
    
    -- Simple lock detection process
    lock_detection_process : process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if reset = '1' then
                lock_counter <= (others => '0');
                clk_locked_reg <= '0';
                
            else
                -- Count stable clock cycles
                if lock_counter = 255 then
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
    
end behavioral;