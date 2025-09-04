library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

entity uart_tb is
end uart_tb; 

architecture sim of uart_tb is

  constant clk_hz : integer := 100e6;
  constant baud_rate : integer := 115200;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  -- UART tx output looped back to the rx input  
  signal tx_rx : std_logic;

  -- Data received by the DUT
  signal recv_tdata : std_logic_vector(7 downto 0);
  signal recv_tvalid : std_logic;
  signal recv_tready : std_logic := '0';

  -- Data that the DUT shall send
  signal send_tdata : std_logic_vector(7 downto 0) := (others => '0');
  signal send_tvalid : std_logic := '0';
  signal send_tready : std_logic;

  -- DUT error indicator signals
  signal rx_fifo_full : std_logic;
  signal rx_stop_bit_error : std_logic;

  procedure print(msg : string) is
    variable l : line;
  begin
    write(l, to_string(now), LEFT, 20);
    write(l, msg);
    writeline(output, l);
  end procedure;

  -- Generate a random byte value based on the two seeds
  procedure rand_byte(
    variable slv : inout std_logic_vector;
    variable seed1, seed2 : inout integer) is

    variable r : real;
  begin
    for i in slv'range loop
      uniform(seed1, seed2, r);
      slv(i) := '1' when r > 0.5 else '0';
    end loop;
  end procedure;

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.uart_buffered(rtl)
    generic map (
      clk_hz => clk_hz,
      baud_rate => baud_rate
    )
    port map (
      clk => clk,
      rst => rst,

      -- UART input/output lines
      rx => tx_rx,
      tx => tx_rx,

      -- Received byte (sample on pulsed valid)
      recv_tdata => recv_tdata,
      recv_tvalid => recv_tvalid,
      recv_tready => recv_tready,

      -- Word to send (ready/valid handshake)
      send_tdata => send_tdata,
      send_tvalid => send_tvalid,
      send_tready => send_tready,

      -- Error conditions ('0' = no error)
      rx_fifo_full => rx_fifo_full,
      rx_stop_bit_error => rx_stop_bit_error
    );

  SEQUENCER_PROC : process

    constant bytes_to_send : integer := 256;

    -- Using identical seed values to generate the same
    -- random sequence on the send side as on the receive side
    variable seed_a1, seed_a2, seed_b1, seed_b2 : integer := 12345;

    variable send_byte, expected_byte : std_logic_vector(7 downto 0);

  begin
    print("Releasing reset");
    wait for clk_period * 2;
    rst <= '0';
    wait for clk_period * 10;

    print("Sending " & to_string(bytes_to_send) & " random bytes");

    for i in 0 to bytes_to_send - 1 loop
      rand_byte(send_byte, seed_a1, seed_a2);
      send_tdata <= send_byte;
      send_tvalid <= '1';
      wait for clk_period;
    end loop;

    send_tvalid <= '0';
    recv_tready <= '1';

    print("Expecting to receive " & to_string(bytes_to_send) & " bytes");
    for i in 0 to bytes_to_send - 1 loop

      loop 
        wait until rising_edge(clk);
        if recv_tvalid /= '1' then
          exit;
        end if;
      end loop;

      if recv_tvalid /= '1' then
        wait until recv_tvalid = '1';
      end if;

      -- Use an identical random sequence to generate the expected byte
      rand_byte(expected_byte, seed_b1, seed_b2);

      assert recv_tdata = expected_byte
        report "Received byte (" & to_string(recv_tdata) & ")" &
          " doesn't match sent byte (" & to_string(expected_byte)
        severity failure;
    end loop;

    print("All bytes received");
    print("Test: OK");
    finish;
  end process;

end architecture;