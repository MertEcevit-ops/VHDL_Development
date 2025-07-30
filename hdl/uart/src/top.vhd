----------------------------------------------------------------------
-- UART Echo Top Module with FIFO Buffers for Basys3
-- Includes RX and TX FIFO buffers for better performance
-- 100MHz clock, 115200 baud rate
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
    port (
        -- Clock and Reset
        clk         : in  std_logic;  -- 100MHz system clock
        btnC        : in  std_logic;  -- Center button for reset
        
        -- UART Interface
        RsRx        : in  std_logic;  -- UART receive
        RsTx        : out std_logic;  -- UART transmit
        
        -- Seven Segment Display
        seg         : out std_logic_vector(6 downto 0);  -- Segment outputs
        an          : out std_logic_vector(3 downto 0);  -- Digit anodes
        
        -- Status LEDs
        led         : out std_logic_vector(15 downto 0)  -- Extended status indicators
    );
end top;

architecture behavioral of top is
    
    -- Clock divider for baud rate (100MHz / 115200 = 868.05 ≈ 868)
    constant CLKS_PER_BIT : integer := 868;
    constant RX_FIFO_DEPTH : integer := 32;
    constant TX_FIFO_DEPTH : integer := 32;
    
    -- Reset synchronizer
    signal reset_sync : std_logic_vector(2 downto 0) := "111";
    signal reset_n    : std_logic;
    
    -- UART RX with FIFO signals
    signal rx_rd_en     : std_logic;
    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_empty     : std_logic;
    signal rx_full      : std_logic;
    signal rx_count     : std_logic_vector(4 downto 0);
    signal rx_error     : std_logic;
    
    -- UART TX with FIFO signals
    signal tx_wr_en     : std_logic;
    signal tx_data      : std_logic_vector(7 downto 0);
    signal tx_full      : std_logic;
    signal tx_empty     : std_logic;
    signal tx_count     : std_logic_vector(4 downto 0);
    signal tx_active    : std_logic;
    signal tx_done      : std_logic;
    
    -- Echo control
    signal echo_enable  : std_logic := '1';
    signal char_received: std_logic;
    signal rx_data_delayed : std_logic_vector(7 downto 0);
    
    -- Status signals
    signal heartbeat    : std_logic := '0';
    signal heartbeat_counter : unsigned(25 downto 0) := (others => '0');
    
    -- Display control
    signal display_char : std_logic_vector(7 downto 0);
    signal display_valid: std_logic;
    
begin
    
    -- Reset synchronizer and inverter
    reset_sync_process : process(clk)
    begin
        if rising_edge(clk) then
            reset_sync <= reset_sync(1 downto 0) & (not btnC);
        end if;
    end process;
    
    reset_n <= reset_sync(2);
    
    -- UART RX with FIFO instance
    uart_rx_fifo_inst : entity work.uart_rx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT,
            FIFO_DEPTH     => RX_FIFO_DEPTH
        )
        port map (
            i_clk       => clk,
            i_rst       => not reset_n,
            i_rx_serial => RsRx,
            i_rd_en     => rx_rd_en,
            o_rx_data   => rx_data,
            o_rx_empty  => rx_empty,
            o_rx_full   => rx_full,
            o_rx_count  => rx_count,
            o_rx_error  => rx_error
        );
    
    -- UART TX with FIFO instance
    uart_tx_fifo_inst : entity work.uart_tx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT,
            FIFO_DEPTH     => TX_FIFO_DEPTH
        )
        port map (
            i_clk       => clk,
            i_rst       => not reset_n,
            i_wr_en     => tx_wr_en,
            i_tx_data   => tx_data,
            o_tx_full   => tx_full,
            o_tx_empty  => tx_empty,
            o_tx_count  => tx_count,
            o_tx_serial => RsTx,
            o_tx_active => tx_active,
            o_tx_done   => tx_done
        );
    
    -- Seven Segment Display Controller
    seven_seg_inst : entity work.seven_segment_controller
        port map (
            i_clk        => clk,
            i_rst        => not reset_n,
            i_ascii_char => display_char,
            i_char_valid => display_valid,
            o_segments   => seg,
            o_anodes     => an
        );
    
    -- Echo and display control process
    echo_control_process : process(clk, reset_n)
    begin
        if reset_n = '0' then
            rx_rd_en <= '0';
            tx_wr_en <= '0';
            tx_data <= (others => '0');
            display_char <= (others => '0');
            display_valid <= '0';
            char_received <= '0';
            rx_data_delayed <= (others => '0');
            
        elsif rising_edge(clk) then
            
            -- Default assignments
            rx_rd_en <= '0';
            tx_wr_en <= '0';
            display_valid <= '0';
            char_received <= '0';
            
            -- Check if there's data in RX FIFO and read it
            if rx_empty = '0' then
                rx_rd_en <= '1';
                char_received <= '1';
            end if;
            
            -- Handle the received data (delayed by one clock cycle due to FIFO read)
            if rx_rd_en = '1' then
                rx_data_delayed <= rx_data;
                display_char <= rx_data;
                display_valid <= '1';
                
                -- Echo the character if echo is enabled and TX FIFO not full
                if echo_enable = '1' and tx_full = '0' then
                    tx_wr_en <= '1';
                    tx_data <= rx_data;
                end if;
            end if;
        end if;
    end process;
    
    -- Heartbeat generator
    heartbeat_process : process(clk, reset_n)
    begin
        if reset_n = '0' then
            heartbeat_counter <= (others => '0');
            heartbeat <= '0';
        elsif rising_edge(clk) then
            heartbeat_counter <= heartbeat_counter + 1;
            -- Toggle every ~0.67 seconds (100MHz / 2^26)
            if heartbeat_counter = 0 then
                heartbeat <= not heartbeat;
            end if;
        end if;
    end process;
    
    -- Status LED assignments (16 LEDs total)
    led(0) <= not rx_empty;             -- RX FIFO has data
    led(1) <= not tx_empty;             -- TX FIFO has data
    led(2) <= rx_full;                  -- RX FIFO full
    led(3) <= tx_full;                  -- TX FIFO full
    led(4) <= tx_active;                -- TX active (transmitting)
    led(5) <= rx_error;                 -- RX overflow error
    led(6) <= char_received;            -- Character received indicator
    led(7) <= heartbeat;                -- Heartbeat
    
    -- RX FIFO count display (5 bits)
    led(12 downto 8) <= rx_count;
    
    -- TX FIFO count display (3 MSBs)
    led(15 downto 13) <= tx_count(2 downto 0);
    
end behavioral;