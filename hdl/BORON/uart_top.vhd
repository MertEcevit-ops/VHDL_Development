library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_top is
    generic (
        CLK_FREQ : integer := 50_000_000;
        BAUD     : integer := 115200
    );
    port (
        clk_i     : in  std_logic;
        rst_ni    : in  std_logic;
        -- UART interface
        uart_rx_i : in  std_logic;
        uart_tx_o : out std_logic;
        -- Internal interface
        rx_data_o  : out std_logic_vector(7 downto 0);
        rx_valid_o : out std_logic;
        tx_data_i  : in  std_logic_vector(7 downto 0);
        tx_send_i  : in  std_logic;
        tx_busy_o  : out std_logic;
        rx_busy_o  : out std_logic
    );
end uart_top;

architecture Behavioral of uart_top is
    component uart_rx is
        generic (CLK_FREQ : integer; BAUD : integer);
        port (clk_i, rst_ni, din_i : in std_logic;
              data_o : out std_logic_vector(7 downto 0);
              valid_o, busy_o : out std_logic);
    end component;
    
    component uart_tx is
        generic (BAUD : integer; CLK_FREQ : integer);
        port (clk_i, rst_ni : in std_logic;
              data_i : in std_logic_vector(7 downto 0);
              send_i : in std_logic;
              dout_o, busy_o : out std_logic);
    end component;
    
begin
    rx_inst: uart_rx
        generic map (CLK_FREQ => CLK_FREQ, BAUD => BAUD)
        port map (
            clk_i   => clk_i,
            rst_ni  => rst_ni,
            din_i   => uart_rx_i,
            data_o  => rx_data_o,
            valid_o => rx_valid_o,
            busy_o  => rx_busy_o
        );
    
    tx_inst: uart_tx
        generic map (BAUD => BAUD, CLK_FREQ => CLK_FREQ)
        port map (
            clk_i  => clk_i,
            rst_ni => rst_ni,
            data_i => tx_data_i,
            send_i => tx_send_i,
            dout_o => uart_tx_o,
            busy_o => tx_busy_o
        );
end Behavioral;