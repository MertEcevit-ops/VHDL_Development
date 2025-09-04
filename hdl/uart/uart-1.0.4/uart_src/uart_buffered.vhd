library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_buffered is
  generic (
    clk_hz : positive;
    baud_rate : positive;
    rx_fifo_ram_depth : positive := 2048;
    tx_fifo_ram_depth : positive := 2048
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- UART input/output lines
    rx : in std_logic;
    tx : out std_logic;

    -- Received byte (sample on pulsed valid)
    recv_tdata : out std_logic_vector(7 downto 0);
    recv_tvalid : out std_logic;
    recv_tready : in std_logic;

    -- Word to send (ready/valid handshake)
    send_tdata : in std_logic_vector(7 downto 0);
    send_tvalid : in std_logic;
    send_tready : out std_logic;

    -- Error conditions ('0' = no error)
    rx_fifo_full : out std_logic;
    rx_stop_bit_error : out std_logic
  );
end uart_buffered;

architecture rtl of uart_buffered is

  signal rx_tdata : std_logic_vector(7 downto 0);
  signal rx_tvalid : std_logic;
  signal rx_fifo_in_tready : std_logic;
  signal tx_tdata : std_logic_vector(7 downto 0);
  signal tx_tvalid : std_logic;
  signal tx_tready : std_logic;

begin

  rx_fifo_full <= not rx_fifo_in_tready;

  UART_RX : entity work.uart_rx(rtl)
    generic map (
      clk_hz => clk_hz,
      baud_rate => baud_rate
    )
    port map (
      clk => clk,
      rst => rst,
      rx => rx,
      recv_tdata => rx_tdata,
      recv_tvalid => rx_tvalid,
      stop_bit_error => rx_stop_bit_error
    );

  RX_FIFO : entity work.axi_fifo(rtl)
    generic map (
      ram_width => 8,
      ram_depth => rx_fifo_ram_depth
    )
    port map (
      clk => clk,
      rst => rst,

      -- FIFO input
      in_tready => rx_fifo_in_tready,
      in_tvalid => rx_tvalid,
      in_tdata => rx_tdata,

      -- FIFO output
      out_tready => recv_tready,
      out_tvalid => recv_tvalid,
      out_tdata => recv_tdata
    );

  TX_FIFO : entity work.axi_fifo(rtl)
    generic map (
      ram_width => 8,
      ram_depth => tx_fifo_ram_depth
    )
    port map (
      clk => clk,
      rst => rst,

      -- FIFO input
      in_tready => send_tready,
      in_tvalid => send_tvalid,
      in_tdata => send_tdata,

      -- FIFO output
      out_tready => tx_tready,
      out_tvalid => tx_tvalid,
      out_tdata => tx_tdata
    );

  UART_TX : entity work.uart_tx(rtl)
    generic map (
      clk_hz => clk_hz,
      baud_rate => baud_rate
    )
    port map (
      clk => clk,
      rst => rst,
      tx => tx,
      send_tdata => tx_tdata,
      send_tvalid => tx_tvalid,
      send_tready => tx_tready
    );

end architecture;