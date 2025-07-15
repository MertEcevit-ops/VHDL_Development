----------------------------------------------------------------------
-- UART Echo Top Module for Basys3
-- Receives characters via UART, echoes them back and displays on 7-segment
-- 100MHz clock, 115200 baud rate
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        led         : out std_logic_vector(3 downto 0)   -- Status indicators
    );
end top;

architecture behavioral of top is
    
    -- Clock divider for baud rate (100MHz / 115200 = 868.05 ≈ 868)
    constant CLKS_PER_BIT : integer := 868;
    
    -- Reset synchronizer
    signal reset_sync : std_logic_vector(2 downto 0) := "111";
    signal reset_n    : std_logic;
    
    -- UART RX signals
    signal rx_data_valid : std_logic;
    signal rx_data       : std_logic_vector(7 downto 0);
    
    -- UART TX signals
    signal tx_start      : std_logic;
    signal tx_data       : std_logic_vector(7 downto 0);
    signal tx_busy       : std_logic;
    signal tx_done       : std_logic;
    
    -- Echo state machine
    type echo_state_t is (IDLE, WAIT_TX_READY, START_TX, WAIT_TX_DONE);
    signal echo_state : echo_state_t := IDLE;
    
    -- Status signals
    signal rx_activity   : std_logic := '0';
    signal tx_activity   : std_logic := '0';
    signal error_flag    : std_logic := '0';
    signal heartbeat     : std_logic := '0';
    
    -- Heartbeat counter
    signal heartbeat_counter : unsigned(25 downto 0) := (others => '0');
    
begin
    
    -- Reset synchronizer and inverter
    reset_sync_process : process(clk)
    begin
        if rising_edge(clk) then
            reset_sync <= reset_sync(1 downto 0) & (not btnC);
        end if;
    end process;
    
    reset_n <= reset_sync(2);
    
    -- UART RX instance
    uart_rx_inst : entity work.uart_rx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            i_clk       => clk,
            i_rst       => not reset_n,
            i_rx_serial => RsRx,
            o_rx_dv     => rx_data_valid,
            o_rx_byte   => rx_data
        );
    
    -- UART TX instance
    uart_tx_inst : entity work.uart_tx
        generic map (
            g_CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            i_clk      => clk,
            i_rst      => not reset_n,
            i_tx_start => tx_start,
            i_tx_data  => tx_data,
            o_tx_line  => RsTx,
            o_tx_busy  => tx_busy,
            o_tx_done  => tx_done
        );
    
    -- Seven Segment Display Controller
    seven_seg_inst : entity work.seven_segment_controller
        port map (
            i_clk        => clk,
            i_rst        => not reset_n,
            i_ascii_char => rx_data,
            i_char_valid => rx_data_valid,
            o_segments   => seg,
            o_anodes     => an
        );
    
    -- Echo state machine
    echo_process : process(clk, reset_n)
    begin
        if reset_n = '0' then
            echo_state <= IDLE;
            tx_start <= '0';
            tx_data <= (others => '0');
            tx_activity <= '0';
            
        elsif rising_edge(clk) then
            
            -- Default assignments
            tx_start <= '0';
            tx_activity <= tx_busy;
            
            case echo_state is
                
                when IDLE =>
                    if rx_data_valid = '1' then
                        tx_data <= rx_data;
                        if tx_busy = '0' then
                            echo_state <= START_TX;
                        else
                            echo_state <= WAIT_TX_READY;
                        end if;
                    end if;
                    
                when WAIT_TX_READY =>
                    if tx_busy = '0' then
                        echo_state <= START_TX;
                    end if;
                    
                when START_TX =>
                    tx_start <= '1';
                    echo_state <= WAIT_TX_DONE;
                    
                when WAIT_TX_DONE =>
                    if tx_done = '1' then
                        echo_state <= IDLE;
                    end if;
                    
                when others =>
                    echo_state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- RX activity indicator
    rx_activity_process : process(clk, reset_n)
        variable activity_counter : unsigned(23 downto 0) := (others => '0');
    begin
        if reset_n = '0' then
            rx_activity <= '0';
            activity_counter := (others => '0');
        elsif rising_edge(clk) then
            if rx_data_valid = '1' then
                rx_activity <= '1';
                activity_counter := (others => '0');
            elsif activity_counter = x"FFFFFF" then
                rx_activity <= '0';
            else
                activity_counter := activity_counter + 1;
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
    
    -- Status LED assignments
    led(0) <= rx_activity;     -- RX activity
    led(1) <= tx_activity;     -- TX activity
    led(2) <= error_flag;      -- Error indicator (currently unused)
    led(3) <= heartbeat;       -- Heartbeat
    
end behavioral;