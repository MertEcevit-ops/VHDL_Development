library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

entity top_tb is
end top_tb;

architecture sim of top_tb is

  constant clk_hz : integer := 12e6;
  constant clk_period : time := 1 sec / clk_hz;

  constant baud_rate : integer := 115200;

  constant dut_fifo_ram_depth : integer := 128;

  -- Determines for how long the testbench will run
  constant bytes_to_send : integer := 2048;

  -- The seed values determine the pseudo-random test sequence
  constant seed_values : integer := 12345;

  -- DUT signals
  signal clk : std_logic := '1';
  signal uart_rx : std_logic := '1';
  signal uart_tx : std_logic;
  signal rx_fifo_full : std_logic;
  signal rx_stop_bit_error : std_logic;

  -- UART BFM signals
  signal data_in : std_logic_vector(7 downto 0);
  signal data_in_ready : boolean;
  signal data_in_valid : boolean;
  signal data_out : std_logic_vector(7 downto 0);
  signal data_out_valid : boolean;

  -- Testbench signaling
  signal bfms_start : boolean;
  signal tx_proc_done : boolean;
  signal rx_proc_done : boolean;

  -- Generate random a std_logic_vector(7 downto 0) value
  procedure rand_byte (
    variable seed1, seed2 : inout integer;
    variable slv : out std_logic_vector(7 downto 0)
  ) is
    variable r : real;
  begin
    for i in slv'range loop
      uniform(seed1, seed2, r);
      slv(i) := '1' when r > 0.5 else '0';
    end loop;
  end procedure;

  procedure print(msg : string) is
    variable l : line;
  begin
    write(l, to_string(now), LEFT, 20);
    write(l, msg);
    writeline(output, l);
  end procedure;

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.top(str)
    generic map (
      clk_hz => clk_hz,
      baud_rate => baud_rate,
      rx_fifo_ram_depth => dut_fifo_ram_depth,
      tx_fifo_ram_depth => dut_fifo_ram_depth
    )
    port map (
      clk => clk,
      rst_in => '0',
      uart_rx => uart_rx,
      uart_tx => uart_tx,
      rx_fifo_full => rx_fifo_full,
      rx_stop_bit_error => rx_stop_bit_error
    );

  BFM : entity work.uart_bfm(beh)
    generic map (
      baud_rate => baud_rate
    )
    port map (
      data_in => data_in,
      data_in_ready => data_in_ready,
      data_in_valid => data_in_valid,

      data_out => data_out,
      data_out_valid => data_out_valid,

      rx => uart_tx,
      tx => uart_rx
    );

  TX_PROC : process
    variable seed1, seed2 : integer := seed_values;
    variable send_byte : std_logic_vector(7 downto 0);
  begin
    wait until bfms_start;
    
    for i in 0 to bytes_to_send - 1 loop

      wait until rising_edge(clk) and data_in_ready;

      -- Generate a random sequence
      rand_byte(seed1, seed2, send_byte);
      data_in <= send_byte;
      data_in_valid <= true;

      wait until rising_edge(clk);
      data_in_valid <= false;
    end loop;
    
    tx_proc_done <= true;
    wait;
  end process;

  RX_PROC : process
    variable seed1, seed2 : integer := seed_values;
    variable expected_byte : std_logic_vector(7 downto 0);
  begin
    wait until bfms_start;
    
    for i in 0 to bytes_to_send - 1 loop

      wait until data_out_valid;

      -- Generate the same random sequence as TX_PROC
      rand_byte(seed1, seed2, expected_byte);

      assert data_out = expected_byte
        report "Received " & to_hstring(data_out) &
          " from the DUT. Expected " & to_hstring(expected_byte)
        severity failure;

    end loop;
    
    rx_proc_done <= true;
    wait;
  end process;

  SEQUENCER_PROC : process
  begin
    print("Waiting for the DUT to release the reset");
    wait until << signal dut.rst : std_logic >> = '0';

    print("Starting TX and RX BFM processes");
    bfms_start <= true;

    print("Waiting for " & to_string(bytes_to_send) & " bytes to be sent and received");
    wait until tx_proc_done and rx_proc_done;

    print("All bytes received");
    print("Test: OK");
    finish;
  end process;

end architecture;