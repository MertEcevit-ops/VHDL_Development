library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity boron_uart_system is
    port (
        clk_i      : in  std_logic;
        rst_ni     : in  std_logic;
        uart_rx_i  : in  std_logic;
        uart_tx_o  : out std_logic;
        led_o      : out std_logic_vector(3 downto 0)  -- Status LEDs
    );
end boron_uart_system;

architecture Behavioral of boron_uart_system is
    -- Component declarations
    component uart_top is
        generic (CLK_FREQ : integer; BAUD : integer);
        port (clk_i, rst_ni : in std_logic;
              uart_rx_i : in std_logic;
              uart_tx_o : out std_logic;
              rx_data_o : out std_logic_vector(7 downto 0);
              rx_valid_o : out std_logic;
              tx_data_i : in std_logic_vector(7 downto 0);
              tx_send_i : in std_logic;
              tx_busy_o, rx_busy_o : out std_logic);
    end component;
    
    component boron_core is
        port (clk_i, rst_ni, start_i : in std_logic;
              plain_text_i : in std_logic_vector(63 downto 0);
              key_i : in std_logic_vector(79 downto 0);
              cipher_text_o : out std_logic_vector(63 downto 0);
              done_o : out std_logic);
    end component;
    
    component protocol_controller is
        port (clk_i, rst_ni : in std_logic;
              rx_data_i : in std_logic_vector(7 downto 0);
              rx_valid_i : in std_logic;
              tx_data_o : out std_logic_vector(7 downto 0);
              tx_send_o : out std_logic;
              tx_busy_i : in std_logic;
              plain_text_o : out std_logic_vector(63 downto 0);
              key_o : out std_logic_vector(79 downto 0);
              start_o : out std_logic;
              cipher_text_i : in std_logic_vector(63 downto 0);
              done_i : in std_logic);
    end component;
    
    component debouncer is
        generic (N_BOUNCE : integer; IS_PULLUP : integer);
        port (clk_i, rst_ni, din_i : in std_logic;
              bounce_o : out std_logic);
    end component;
    
    -- Internal signals
    signal rst_n_sync      : std_logic;
    signal rx_data         : std_logic_vector(7 downto 0);
    signal rx_valid        : std_logic;
    signal tx_data         : std_logic_vector(7 downto 0);
    signal tx_send         : std_logic;
    signal tx_busy         : std_logic;
    signal rx_busy         : std_logic;
    
    signal plain_text      : std_logic_vector(63 downto 0);
    signal key             : std_logic_vector(79 downto 0);
    signal cipher_text     : std_logic_vector(63 downto 0);
    signal encrypt_start   : std_logic;
    signal encrypt_done    : std_logic;
    
    -- Status signals
    signal activity_counter : unsigned(23 downto 0);
    
begin
    -- Reset debouncer
    reset_debouncer: debouncer
        generic map (N_BOUNCE => 3, IS_PULLUP => 0)
        port map (
            clk_i    => clk_i,
            rst_ni   => '1',  -- Always enabled for reset debouncing
            din_i    => rst_ni,
            bounce_o => rst_n_sync
        );
    
    -- UART Top Module
    uart_inst: uart_top
        generic map (
            CLK_FREQ => 50_000_000,
            BAUD     => 115200
        )
        port map (
            clk_i      => clk_i,
            rst_ni     => rst_n_sync,
            uart_rx_i  => uart_rx_i,
            uart_tx_o  => uart_tx_o,
            rx_data_o  => rx_data,
            rx_valid_o => rx_valid,
            tx_data_i  => tx_data,
            tx_send_i  => tx_send,
            tx_busy_o  => tx_busy,
            rx_busy_o  => rx_busy
        );
    
    -- BORON Core
    boron_inst: boron_core
        port map (
            clk_i         => clk_i,
            rst_ni        => rst_n_sync,
            start_i       => encrypt_start,
            plain_text_i  => plain_text,
            key_i         => key,
            cipher_text_o => cipher_text,
            done_o        => encrypt_done
        );
    
    -- Protocol Controller
    protocol_inst: protocol_controller
        port map (
            clk_i         => clk_i,
            rst_ni        => rst_n_sync,
            rx_data_i     => rx_data,
            rx_valid_i    => rx_valid,
            tx_data_o     => tx_data,
            tx_send_o     => tx_send,
            tx_busy_i     => tx_busy,
            plain_text_o  => plain_text,
            key_o         => key,
            start_o       => encrypt_start,
            cipher_text_i => cipher_text,
            done_i        => encrypt_done
        );
    
    -- Status LED Controller
    process(clk_i, rst_n_sync)
    begin
        if rst_n_sync = '0' then
            activity_counter <= (others => '0');
            led_o <= "0000";
        elsif rising_edge(clk_i) then
            activity_counter <= activity_counter + 1;
            
            -- LED assignments
            led_o(0) <= activity_counter(23);  -- Heartbeat LED
            led_o(1) <= rx_busy;               -- RX Activity
            led_o(2) <= tx_busy;               -- TX Activity  
            led_o(3) <= encrypt_start or not encrypt_done; -- Encryption Activity
        end if;
    end process;
    
end Behavioral;