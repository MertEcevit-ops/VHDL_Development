library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  generic (
    -- Set the system clock frequency for your board
    clk_hz : positive;

    baud_rate : positive := 115200;

    rx_fifo_ram_depth : positive := 2048;
    tx_fifo_ram_depth : positive := 2048;

    -- Clock cycles to hold rst_out for after rst_in is released
    rst_strobe_cycles : positive := 128;

    -- The polarity of rst_in when reset is active
    rst_in_active_value : std_logic := '1';

    -- The desired polarity of rst_out when active
    rst_out_active_value : std_logic := '1'
  );
  port (
    clk : in std_logic;
    rst_in : in std_logic; -- Set to '0' if there is no reset button 
    uart_rx : in std_logic;
    uart_tx : out std_logic;
    rx_fifo_full : out std_logic;
    rx_stop_bit_error : out std_logic
  );
end top;

architecture str of top is

  signal rst : std_logic;
  signal data : std_logic_vector(7 downto 0);
  signal valid : std_logic;
  signal ready : std_logic;
  
begin

  RESET_SYNC : entity work.reset_sync(rtl)
    generic map (
      rst_strobe_cycles => rst_strobe_cycles,
      rst_in_active_value => rst_in_active_value,
      rst_out_active_value => rst_out_active_value
    )
    port map (
      clk => clk,
      rst_in => rst_in,
      rst_out => rst
    );
  
  UART : entity work.uart_buffered(rtl)
    generic map (
      clk_hz => clk_hz,
      baud_rate => baud_rate,
      rx_fifo_ram_depth => rx_fifo_ram_depth,
      tx_fifo_ram_depth => tx_fifo_ram_depth
    )
    port map (
      clk => clk,
      rst => rst,
      rx => uart_rx,
      tx => uart_tx,
      recv_tdata => data,
      recv_tvalid => valid,
      recv_tready => ready,
      send_tdata => data,
      send_tvalid => valid,
      send_tready => ready,
      rx_fifo_full => rx_fifo_full,
      rx_stop_bit_error => rx_stop_bit_error
    );

end architecture;