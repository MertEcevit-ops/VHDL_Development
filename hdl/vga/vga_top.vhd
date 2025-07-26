----------------------------------------------------------------------
-- Complete VGA Top Module for Basys3
-- Integrates: VGA Clock, Timing, Pattern Generator, Text Display, 
--            UART with FIFO, Seven Segment Display
-- Features: Dual mode VGA system with UART terminal capability
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_top is
    port (
        -- Clock and Reset
        clk         : in  std_logic;  -- 100MHz system clock
        btnC        : in  std_logic;  -- Center button for reset
        
        -- Mode Selection and Control
        sw          : in  std_logic_vector(15 downto 0);  -- Switches for control
        
        -- UART Interface
        RsRx        : in  std_logic;  -- UART receive
        RsTx        : out std_logic;  -- UART transmit
        
        -- VGA Interface
        vga_hsync   : out std_logic;
        vga_vsync   : out std_logic;
        vga_red     : out std_logic_vector(3 downto 0);
        vga_green   : out std_logic_vector(3 downto 0);
        vga_blue    : out std_logic_vector(3 downto 0);
        
        -- Seven Segment Display
        seg         : out std_logic_vector(6 downto 0);  -- Segment outputs
        an          : out std_logic_vector(3 downto 0);  -- Digit anodes
        
        -- Status LEDs
        led         : out std_logic_vector(15 downto 0)  -- Status indicators
    );
end vga_top;

architecture behavioral of vga_top is
    
    -- Clock generation constants
    constant CLKS_PER_BIT : integer := 868;  -- 100MHz / 115200 baud
    
    -- Reset synchronizer
    signal reset_sync : std_logic_vector(2 downto 0) := "111";
    signal reset_n    : std_logic;
    signal sys_reset  : std_logic;
    
    -- Clock signals
    signal pixel_clk     : std_logic;
    signal pixel_clk_x2  : std_logic;
    signal clk_locked    : std_logic;
    
    -- VGA timing signals
    signal hsync_int     : std_logic;
    signal vsync_int     : std_logic;
    signal display_en    : std_logic;
    signal pixel_x       : integer range 0 to 799;
    signal pixel_y       : integer range 0 to 524;
    
    -- UART RX signals
    signal rx_rd_en      : std_logic;
    signal rx_data       : std_logic_vector(7 downto 0);
    signal rx_empty      : std_logic;
    signal rx_full       : std_logic;
    signal rx_count      : std_logic_vector(4 downto 0);
    signal rx_error      : std_logic;
    
    -- UART TX signals
    signal tx_wr_en      : std_logic;
    signal tx_data       : std_logic_vector(7 downto 0);
    signal tx_full       : std_logic;
    signal tx_empty      : std_logic;
    signal tx_count      : std_logic_vector(4 downto 0);
    signal tx_busy       : std_logic;
    
    -- VGA Pattern Generator signals
    signal pattern_red   : std_logic_vector(3 downto 0);
    signal pattern_green : std_logic_vector(3 downto 0);
    signal pattern_blue  : std_logic_vector(3 downto 0);
    signal pattern_sel   : integer range 0 to 7;
    
    -- VGA Text Display signals
    signal text_red      : std_logic_vector(3 downto 0);
    signal text_green    : std_logic_vector(3 downto 0);
    signal text_blue     : std_logic_vector(3 downto 0);
    signal text_color    : std_logic_vector(11 downto 0);
    signal bg_color      : std_logic_vector(11 downto 0);
    
    -- Character processing
    signal char_received : std_logic;
    signal display_char  : std_logic_vector(7 downto 0);
    signal display_valid : std_logic;
    
    -- Mode control signals
    signal vga_text_mode : std_logic;
    signal echo_enable   : std_logic;
    signal cursor_enable : std_logic;
    
    -- Status signals
    signal heartbeat        : std_logic := '0';
    signal heartbeat_counter : unsigned(25 downto 0) := (others => '0');
    
    -- Components
    component vga_clock is
        generic (
            SYS_CLK_FREQ    : integer := 100_000_000;
            PIXEL_CLK_FREQ  : integer := 25_000_000;
            COUNTER_WIDTH   : integer := 8
        );
        port (
            sys_clk      : in  std_logic;
            reset        : in  std_logic;
            pixel_clk    : out std_logic;
            pixel_clk_x2 : out std_logic;
            clk_locked   : out std_logic
        );
    end component;
    
    component vga_timing is
        generic (
            H_TOTAL     : integer := 800;
            H_ACTIVE    : integer := 640;
            H_FRONT     : integer := 16;
            H_SYNC      : integer := 96;
            H_BACK      : integer := 48;
            H_POLARITY  : std_logic := '0';
            V_TOTAL     : integer := 525;
            V_ACTIVE    : integer := 480;
            V_FRONT     : integer := 10;
            V_SYNC      : integer := 2;
            V_BACK      : integer := 33;
            V_POLARITY  : std_logic := '0'
        );
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            hsync      : out std_logic;
            vsync      : out std_logic;
            display_en : out std_logic;
            pixel_x    : out integer range 0 to 799;
            pixel_y    : out integer range 0 to 524
        );
    end component;
    
    component vga_pattern is
        generic (
            H_ACTIVE    : integer := 640;
            V_ACTIVE    : integer := 480;
            COLOR_DEPTH : integer := 12;
            PATTERN_NUM : integer := 8
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            pixel_x     : in  integer range 0 to 639;
            pixel_y     : in  integer range 0 to 479;
            display_en  : in  std_logic;
            pattern_sel : in  integer range 0 to 7;
            red         : out std_logic_vector(3 downto 0);
            green       : out std_logic_vector(3 downto 0);
            blue        : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component vga_pattern_txt is
        generic (
            H_ACTIVE            : integer := 640;
            V_ACTIVE            : integer := 480;
            CHAR_WIDTH          : integer := 8;
            CHAR_HEIGHT         : integer := 16;
            TEXT_COLS           : integer := 80;
            TEXT_ROWS           : integer := 30;
            COLOR_DEPTH         : integer := 12;
            CURSOR_BLINK_PERIOD : integer := 25_000_000
        );
        port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            pixel_x         : in  integer range 0 to 639;
            pixel_y         : in  integer range 0 to 479;
            display_en      : in  std_logic;
            uart_char       : in  std_logic_vector(7 downto 0);
            uart_char_valid : in  std_logic;
            text_color      : in  std_logic_vector(11 downto 0);
            bg_color        : in  std_logic_vector(11 downto 0);
            cursor_enable   : in  std_logic;
            red             : out std_logic_vector(3 downto 0);
            green           : out std_logic_vector(3 downto 0);
            blue            : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component uart_rx is
        generic (
            g_CLKS_PER_BIT : integer := 868;
            FIFO_DEPTH     : integer := 16
        );
        port (
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_rx_serial : in  std_logic;
            i_rd_en     : in  std_logic;
            o_rx_data   : out std_logic_vector(7 downto 0);
            o_rx_empty  : out std_logic;
            o_rx_full   : out std_logic;
            o_rx_count  : out std_logic_vector(4 downto 0);
            o_rx_error  : out std_logic
        );
    end component;
    
    component uart_tx is
        generic (
            g_CLKS_PER_BIT : integer := 868;
            FIFO_DEPTH     : integer := 16
        );
        port (
            i_clk      : in  std_logic;
            i_rst      : in  std_logic;
            i_wr_en    : in  std_logic;
            i_tx_data  : in  std_logic_vector(7 downto 0);
            o_tx_full  : out std_logic;
            o_tx_empty : out std_logic;
            o_tx_count : out std_logic_vector(4 downto 0);
            o_tx_line  : out std_logic;
            o_tx_busy  : out std_logic
        );
    end component;
    
    component seven_segment_controller is
        port (
            i_clk        : in  std_logic;
            i_rst        : in  std_logic;
            i_ascii_char : in  std_logic_vector(7 downto 0);
            i_char_valid : in  std_logic;
            o_segments   : out std_logic_vector(6 downto 0);
            o_anodes     : out std_logic_vector(3 downto 0)
        );
    end component;
    
begin
    
    -- Reset synchronizer and inverter
    reset_sync_process : process(clk)
    begin
        if rising_edge(clk) then
            reset_sync <= reset_sync(1 downto 0) & (not btnC);
        end if;
    end process;
    
    reset_n <= reset_sync(2);
    sys_reset <= not reset_n;
    
    -- VGA Clock Generator
    vga_clock_inst : vga_clock
        generic map (
            SYS_CLK_FREQ   => 100_000_000,
            PIXEL_CLK_FREQ => 25_000_000,
            COUNTER_WIDTH  => 8
        )
        port map (
            sys_clk      => clk,
            reset        => sys_reset,
            pixel_clk    => pixel_clk,
            pixel_clk_x2 => pixel_clk_x2,
            clk_locked   => clk_locked
        );
    
    -- VGA Timing Generator
    vga_timing_inst : vga_timing
        generic map (
            H_TOTAL    => 800,
            H_ACTIVE   => 640,
            H_FRONT    => 16,
            H_SYNC     => 96,
            H_BACK     => 48,
            H_POLARITY => '0',
            V_TOTAL    => 525,
            V_ACTIVE   => 480,
            V_FRONT    => 10,
            V_SYNC     => 2,
            V_BACK     => 33,
            V_POLARITY => '0'
        )
        port map (
            clk        => pixel_clk,
            reset      => sys_reset,
            hsync      => hsync_int,
            vsync      => vsync_int,
            display_en => display_en,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y
        );
    
    -- VGA Pattern Generator
    vga_pattern_inst : vga_pattern
        generic map (
            H_ACTIVE    => 640,
            V_ACTIVE    => 480,
            COLOR_DEPTH => 12,
            PATTERN_NUM => 8
        )
        port map (
            clk         => pixel_clk,
            reset       => sys_reset,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            display_en  => display_en,
            pattern_sel => pattern_sel,
            red         => pattern_red,
            green       => pattern_green,
            blue        => pattern_blue
        );
    
    -- VGA Text Display Generator
    vga_text_inst : vga_pattern_txt
        generic map (
            H_ACTIVE            => 640,
            V_ACTIVE            => 480,
            CHAR_WIDTH          => 8,
            CHAR_HEIGHT         => 16,
            TEXT_COLS           => 80,
            TEXT_ROWS           => 30,
            COLOR_DEPTH         => 12,
            CURSOR_BLINK_PERIOD => 25_000_000
        )
        port map (
            clk             => pixel_clk,
            reset           => sys_reset,
            pixel_x         => pixel_x,
            pixel_y         => pixel_y,
            display_en      => display_en,
            uart_char       => display_char,
            uart_char_valid => display_valid,
            text_color      => text_color,
            bg_color        => bg_color,
            cursor_enable   => cursor_enable,
            red             => text_red,
            green           => text_green,
            blue            => text_blue
        );
    
    -- UART RX with FIFO
    uart_rx_inst : uart_rx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT,
            FIFO_DEPTH     => 32
        )
        port map (
            i_clk       => clk,
            i_rst       => sys_reset,
            i_rx_serial => RsRx,
            i_rd_en     => rx_rd_en,
            o_rx_data   => rx_data,
            o_rx_empty  => rx_empty,
            o_rx_full   => rx_full,
            o_rx_count  => rx_count,
            o_rx_error  => rx_error
        );
    
    -- UART TX with FIFO
    uart_tx_inst : uart_tx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT,
            FIFO_DEPTH     => 32
        )
        port map (
            i_clk      => clk,
            i_rst      => sys_reset,
            i_wr_en    => tx_wr_en,
            i_tx_data  => tx_data,
            o_tx_full  => tx_full,
            o_tx_empty => tx_empty,
            o_tx_count => tx_count,
            o_tx_line  => RsTx,
            o_tx_busy  => tx_busy
        );
    
    -- Seven Segment Display Controller
    seven_seg_inst : seven_segment_controller
        port map (
            i_clk        => clk,
            i_rst        => sys_reset,
            i_ascii_char => display_char,
            i_char_valid => display_valid,
            o_segments   => seg,
            o_anodes     => an
        );
    
    -- Switch-based configuration
    vga_text_mode <= sw(0);           -- SW0: VGA mode (1=text, 0=pattern)
    echo_enable   <= sw(1);           -- SW1: Echo enable
    cursor_enable <= sw(2);           -- SW2: Cursor enable
    pattern_sel   <= to_integer(unsigned(sw(5 downto 3))); -- SW[5:3]: Pattern select
    
    -- Color configuration based on switches
    text_color <= x"FFF" when sw(8) = '0' else x"0F0";  -- SW8: Text color (white/green)
    bg_color   <= x"000" when sw(9) = '0' else x"008";  -- SW9: Background (black/dark blue)
    
    -- Character processing and echo control
    char_process : process(clk)
    begin
        if rising_edge(clk) then
            if sys_reset = '1' then
                rx_rd_en <= '0';
                tx_wr_en <= '0';
                tx_data <= (others => '0');
                display_char <= (others => '0');
                display_valid <= '0';
                char_received <= '0';
            else
                -- Default assignments
                rx_rd_en <= '0';
                tx_wr_en <= '0';
                display_valid <= '0';
                char_received <= '0';
                
                -- Process incoming characters
                if rx_empty = '0' then
                    rx_rd_en <= '1';
                    char_received <= '1';
                    display_char <= rx_data;
                    display_valid <= '1';
                    
                    -- Echo character if enabled and TX FIFO not full
                    if echo_enable = '1' and tx_full = '0' then
                        tx_wr_en <= '1';
                        tx_data <= rx_data;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- VGA output multiplexer based on mode
    vga_output_mux : process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if clk_locked = '1' then
                if vga_text_mode = '1' then
                    -- Text mode
                    vga_red   <= text_red;
                    vga_green <= text_green;
                    vga_blue  <= text_blue;
                else
                    -- Pattern mode
                    vga_red   <= pattern_red;
                    vga_green <= pattern_green;
                    vga_blue  <= pattern_blue;
                end if;
                
                -- Output sync signals
                vga_hsync <= hsync_int;
                vga_vsync <= vsync_int;
            else
                -- Clock not locked - output black
                vga_red   <= (others => '0');
                vga_green <= (others => '0');
                vga_blue  <= (others => '0');
                vga_hsync <= '1';
                vga_vsync <= '1';
            end if;
        end if;
    end process;
    
    -- Heartbeat generator
    heartbeat_process : process(clk)
    begin
        if rising_edge(clk) then
            if sys_reset = '1' then
                heartbeat_counter <= (others => '0');
                heartbeat <= '0';
            else
                heartbeat_counter <= heartbeat_counter + 1;
                -- Toggle every ~0.67 seconds (100MHz / 2^26)
                if heartbeat_counter = 0 then
                    heartbeat <= not heartbeat;
                end if;
            end if;
        end if;
    end process;
    
    -- Status LED assignments
    led(0)  <= not rx_empty;        -- RX FIFO has data
    led(1)  <= not tx_empty;        -- TX FIFO has data
    led(2)  <= rx_full;             -- RX FIFO full
    led(3)  <= tx_full;             -- TX FIFO full
    led(4)  <= tx_busy;             -- TX busy
    led(5)  <= rx_error;            -- RX overflow error
    led(6)  <= char_received;       -- Character received indicator
    led(7)  <= heartbeat;           -- Heartbeat
    led(8)  <= vga_text_mode;       -- Current VGA mode
    led(9)  <= echo_enable;         -- Echo status
    led(10) <= cursor_enable;       -- Cursor status
    led(11) <= clk_locked;          -- Clock locked status
    led(12) <= display_en;          -- VGA display enable
    led(15 downto 13) <= std_logic_vector(to_unsigned(pattern_sel, 3)); -- Pattern selection
    
end behavioral;