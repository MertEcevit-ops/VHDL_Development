----------------------------------------------------------------------
-- VGA Text Display Generator
-- Character-based display system with UART integration
-- Supports 80x30 text display with cursor and scrolling
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_pattern_txt is
    generic (
        -- Screen resolution
        H_ACTIVE            : integer := 640;       -- Screen width in pixels
        V_ACTIVE            : integer := 480;       -- Screen height in pixels
        
        -- Character dimensions
        CHAR_WIDTH          : integer := 8;         -- Character width in pixels
        CHAR_HEIGHT         : integer := 16;        -- Character height in pixels
        
        -- Text area dimensions  
        TEXT_COLS           : integer := 80;        -- Characters per row (640/8)
        TEXT_ROWS           : integer := 30;        -- Character rows (480/16)
        
        -- Color configuration
        COLOR_DEPTH         : integer := 12;        -- Total color bits
        
        -- Cursor blink frequency (in clock cycles)
        CURSOR_BLINK_PERIOD : integer := 25_000_000 -- 1 second at 25MHz
    );
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        
        -- Position inputs from sync generator
        pixel_x         : in  integer range 0 to H_ACTIVE-1;
        pixel_y         : in  integer range 0 to V_ACTIVE-1;
        display_en      : in  std_logic;
        
        -- UART character input
        uart_char       : in  std_logic_vector(7 downto 0);
        uart_char_valid : in  std_logic;
        
        -- Display control
        text_color      : in  std_logic_vector(COLOR_DEPTH-1 downto 0);
        bg_color        : in  std_logic_vector(COLOR_DEPTH-1 downto 0);
        cursor_enable   : in  std_logic;
        
        -- Color outputs
        red             : out std_logic_vector(COLOR_DEPTH/3-1 downto 0);
        green           : out std_logic_vector(COLOR_DEPTH/3-1 downto 0);
        blue            : out std_logic_vector(COLOR_DEPTH/3-1 downto 0)
    );
end vga_pattern_txt;

architecture behavioral of vga_pattern_txt is
    
    -- Color width for each channel
    constant COLOR_WIDTH : integer := COLOR_DEPTH/3;
    
    -- Character buffer size
    constant BUFFER_SIZE : integer := TEXT_COLS * TEXT_ROWS;
    
    -- Font ROM constants
    constant FONT_ROM_SIZE : integer := 128 * CHAR_HEIGHT; -- 128 ASCII chars
    
    -- Types
    type char_buffer_type is array (0 to BUFFER_SIZE-1) of std_logic_vector(7 downto 0);
    type font_rom_type is array (0 to FONT_ROM_SIZE-1) of std_logic_vector(CHAR_WIDTH-1 downto 0);
    
    -- Character buffer (initialized with spaces)
    signal char_buffer : char_buffer_type := (others => x"20");
    
    -- Cursor position
    signal cursor_x : integer range 0 to TEXT_COLS-1 := 0;
    signal cursor_y : integer range 0 to TEXT_ROWS-1 := 0;
    
    -- Current display position
    signal char_col : integer range 0 to TEXT_COLS-1;
    signal char_row : integer range 0 to TEXT_ROWS-1;
    signal pixel_in_char_x : integer range 0 to CHAR_WIDTH-1;
    signal pixel_in_char_y : integer range 0 to CHAR_HEIGHT-1;
    
    -- Font data
    signal current_char : std_logic_vector(7 downto 0);
    signal font_addr : integer range 0 to FONT_ROM_SIZE-1;
    signal font_data : std_logic_vector(CHAR_WIDTH-1 downto 0);
    signal pixel_bit : std_logic;
    
    -- Cursor blinking
    signal cursor_counter : integer range 0 to CURSOR_BLINK_PERIOD-1 := 0;
    signal cursor_blink : std_logic := '0';
    signal cursor_at_position : std_logic;
    
    -- Pipeline registers
    signal display_en_reg : std_logic;
    signal pixel_bit_reg : std_logic;
    signal cursor_at_position_reg : std_logic;
    
    -- Simple 8x16 Font ROM (basic ASCII characters)
    function init_font_rom return font_rom_type is
        variable rom : font_rom_type := (others => (others => '0'));
    begin
        -- Space (0x20)
        for i in 0 to CHAR_HEIGHT-1 loop
            rom(32 * CHAR_HEIGHT + i) := "00000000";
        end loop;
        
        -- 'A' (0x41)
        rom(65 * CHAR_HEIGHT + 0)  := "00000000";
        rom(65 * CHAR_HEIGHT + 1)  := "00010000";
        rom(65 * CHAR_HEIGHT + 2)  := "00111000";
        rom(65 * CHAR_HEIGHT + 3)  := "01101100";
        rom(65 * CHAR_HEIGHT + 4)  := "11000110";
        rom(65 * CHAR_HEIGHT + 5)  := "11000110";
        rom(65 * CHAR_HEIGHT + 6)  := "11111110";
        rom(65 * CHAR_HEIGHT + 7)  := "11000110";
        rom(65 * CHAR_HEIGHT + 8)  := "11000110";
        rom(65 * CHAR_HEIGHT + 9)  := "11000110";
        rom(65 * CHAR_HEIGHT + 10) := "00000000";
        rom(65 * CHAR_HEIGHT + 11) := "00000000";
        rom(65 * CHAR_HEIGHT + 12) := "00000000";
        rom(65 * CHAR_HEIGHT + 13) := "00000000";
        rom(65 * CHAR_HEIGHT + 14) := "00000000";
        rom(65 * CHAR_HEIGHT + 15) := "00000000";
        
        -- Initialize other characters with a simple pattern
        for char in 33 to 126 loop
            if char /= 65 then -- Skip 'A' as it's already defined
                for row in 0 to CHAR_HEIGHT-1 loop
                    -- Simple pattern based on character code
                    rom(char * CHAR_HEIGHT + row) := std_logic_vector(
                        to_unsigned((char + row) mod 256, CHAR_WIDTH));
                end loop;
            end if;
        end loop;
        
        return rom;
    end function;
    
    constant font_rom : font_rom_type := init_font_rom;
    
begin
    
    -- Calculate character position from pixel position
    char_col <= pixel_x / CHAR_WIDTH when pixel_x < H_ACTIVE else 0;
    char_row <= pixel_y / CHAR_HEIGHT when pixel_y < V_ACTIVE else 0;
    pixel_in_char_x <= pixel_x mod CHAR_WIDTH;
    pixel_in_char_y <= pixel_y mod CHAR_HEIGHT;
    
    -- UART Character Input Processing
    uart_input_process : process(clk)
        variable buffer_addr : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cursor_x <= 0;
                cursor_y <= 0;
                -- Clear buffer with spaces
                for i in 0 to BUFFER_SIZE-1 loop
                    char_buffer(i) <= x"20";
                end loop;
            elsif uart_char_valid = '1' then
                case uart_char is
                    when x"0A" => -- Line Feed (LF)
                        cursor_x <= 0;
                        if cursor_y = TEXT_ROWS-1 then
                            -- Scroll screen up
                            for i in 0 to BUFFER_SIZE-TEXT_COLS-1 loop
                                char_buffer(i) <= char_buffer(i + TEXT_COLS);
                            end loop;
                            -- Clear last line
                            for i in BUFFER_SIZE-TEXT_COLS to BUFFER_SIZE-1 loop
                                char_buffer(i) <= x"20";
                            end loop;
                        else
                            cursor_y <= cursor_y + 1;
                        end if;
                        
                    when x"0D" => -- Carriage Return (CR)
                        cursor_x <= 0;
                        
                    when x"08" => -- Backspace
                        if cursor_x > 0 then
                            cursor_x <= cursor_x - 1;
                            buffer_addr := cursor_y * TEXT_COLS + cursor_x - 1;
                            char_buffer(buffer_addr) <= x"20";
                        end if;
                        
                    when x"7F" => -- Delete
                        buffer_addr := cursor_y * TEXT_COLS + cursor_x;
                        char_buffer(buffer_addr) <= x"20";
                        
                    when others => -- Printable characters
                        if uart_char >= x"20" and uart_char <= x"7E" then
                            -- Store character in buffer
                            buffer_addr := cursor_y * TEXT_COLS + cursor_x;
                            char_buffer(buffer_addr) <= uart_char;
                            
                            -- Advance cursor
                            if cursor_x = TEXT_COLS-1 then
                                cursor_x <= 0;
                                if cursor_y = TEXT_ROWS-1 then
                                    -- Scroll screen up
                                    for i in 0 to BUFFER_SIZE-TEXT_COLS-1 loop
                                        char_buffer(i) <= char_buffer(i + TEXT_COLS);
                                    end loop;
                                    for i in BUFFER_SIZE-TEXT_COLS to BUFFER_SIZE-1 loop
                                        char_buffer(i) <= x"20";
                                    end loop;
                                else
                                    cursor_y <= cursor_y + 1;
                                end if;
                            else
                                cursor_x <= cursor_x + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process uart_input_process;
    
    -- Cursor blinking logic
    cursor_blink_process : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cursor_counter <= 0;
                cursor_blink <= '0';
            else
                if cursor_counter = CURSOR_BLINK_PERIOD-1 then
                    cursor_counter <= 0;
                    cursor_blink <= not cursor_blink;
                else
                    cursor_counter <= cursor_counter + 1;
                end if;
            end if;
        end if;
    end process cursor_blink_process;
    
    -- Character and font data lookup
    current_char <= char_buffer(char_row * TEXT_COLS + char_col) when 
                   (char_row < TEXT_ROWS and char_col < TEXT_COLS) else x"20";
    
    font_addr <= to_integer(unsigned(current_char)) * CHAR_HEIGHT + pixel_in_char_y;
    font_data <= font_rom(font_addr) when font_addr < FONT_ROM_SIZE else (others => '0');
    pixel_bit <= font_data(CHAR_WIDTH-1 - pixel_in_char_x);
    
    -- Check if cursor is at current position
    cursor_at_position <= '1' when (char_col = cursor_x and char_row = cursor_y and
                                   cursor_enable = '1' and cursor_blink = '1') else '0';
    
    -- Pipeline stage 1: Register display signals
    pipeline_stage1 : process(clk)
    begin
        if rising_edge(clk) then
            display_en_reg <= display_en;
            pixel_bit_reg <= pixel_bit;
            cursor_at_position_reg <= cursor_at_position;
        end if;
    end process pipeline_stage1;
    
    -- Color output generation
    color_output_process : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            elsif display_en_reg = '1' then
                if pixel_bit_reg = '1' or cursor_at_position_reg = '1' then
                    -- Character pixel or cursor - use text color
                    red   <= text_color(COLOR_DEPTH-1 downto COLOR_DEPTH-COLOR_WIDTH);
                    green <= text_color(COLOR_DEPTH-COLOR_WIDTH-1 downto COLOR_WIDTH);
                    blue  <= text_color(COLOR_WIDTH-1 downto 0);
                else
                    -- Background pixel - use background color
                    red   <= bg_color(COLOR_DEPTH-1 downto COLOR_DEPTH-COLOR_WIDTH);
                    green <= bg_color(COLOR_DEPTH-COLOR_WIDTH-1 downto COLOR_WIDTH);
                    blue  <= bg_color(COLOR_WIDTH-1 downto 0);
                end if;
            else
                -- Blanking area - output black
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            end if;
        end if;
    end process color_output_process;
    
end behavioral;