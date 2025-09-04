library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_fifo is
  generic (
    ram_width : natural;
    ram_depth : natural
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- AXI input interface
    in_tready : out std_logic;
    in_tvalid : in std_logic;
    in_tdata : in std_logic_vector(ram_width - 1 downto 0);

    -- AXI output interface
    out_tready : in std_logic;
    out_tvalid : out std_logic;
    out_tdata : out std_logic_vector(ram_width - 1 downto 0)
  );
end axi_fifo;

architecture rtl of axi_fifo is

  -- The FIFO is full when the RAM contains ram_depth - 1 elements
  type ram_type is array (0 to ram_depth - 1) of std_logic_vector(in_tdata'range);
  signal ram : ram_type;

  -- Newest element at head, oldest element at tail
  subtype index_type is natural range ram_type'range;
  signal head : index_type;
  signal tail : index_type;
  signal count : index_type;
  signal count_p1 : index_type;

  -- Internal versions of entity signals with mode "out"
  signal in_tready_i : std_logic;
  signal out_tvalid_i : std_logic;

  -- True the clock cycle after a simultaneous read and write
  signal read_while_write_p1 : std_logic;

  -- Increment or wrap the index if this transaction is valid
  function next_index(
    index : index_type;
    ready : std_logic;
    valid : std_logic) return index_type is
  begin
    if ready = '1' and valid = '1' then
      if index = index_type'high then
        return index_type'low;
      else
        return index + 1;
      end if;
    end if;

    return index;
  end function;

  -- Logic for handling the head and tail signals
  procedure index_proc(
    signal clk : in std_logic;
    signal rst : in std_logic;
    signal index : inout index_type;
    signal ready : in std_logic;
    signal valid : in std_logic) is
  begin
      if rising_edge(clk) then
        if rst = '1' then
          index <= index_type'low;
        else
          index <= next_index(index, ready, valid);
        end if;
      end if;
  end procedure;

begin

  -- Copy internal signals to output
  in_tready <= in_tready_i;
  out_tvalid <= out_tvalid_i;

  -- Update head index on write
  PROC_HEAD : index_proc(clk, rst, head, in_tready_i, in_tvalid);

  -- Update tail index on read
  PROC_TAIL : index_proc(clk, rst, tail, out_tready, out_tvalid_i);

  -- Write to and read from the RAM
  PROC_RAM : process(clk)
  begin
    if rising_edge(clk) then
      ram(head) <= in_tdata;
      out_tdata <= ram(next_index(tail, out_tready, out_tvalid_i));
    end if;
  end process;

  -- Find the number of elements in the RAM
  PROC_COUNT : process(head, tail)
  begin
    if head < tail then
      count <= head - tail + ram_depth;
    else
      count <= head - tail;
    end if;
  end process;

  -- Delay the count by one clock cycles
  PROC_COUNT_P1 : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count_p1 <= 0;
      else
        count_p1 <= count;
      end if;
    end if;
  end process;

  -- Set in_tready when the RAM isn't full
  PROC_in_tREADY : process(count)
  begin
    if count < ram_depth - 1 then
      in_tready_i <= '1';
    else
      in_tready_i <= '0';
    end if;
  end process;

  -- Detect simultaneous read and write operations
  PROC_READ_WHILE_WRITE_P1: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        read_while_write_p1 <= '0';

      else
        read_while_write_p1 <= '0';
        if in_tready_i = '1' and in_tvalid = '1' and
          out_tready = '1' and out_tvalid_i = '1' then
          read_while_write_p1 <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Set out_tvalid when the RAM outputs valid data
  PROC_out_tVALID : process(count, count_p1, read_while_write_p1)
  begin
    out_tvalid_i <= '1';

    -- If the RAM is empty or was empty in the prev cycle
    if count = 0 or count_p1 = 0 then
      out_tvalid_i <= '0';
    end if;

    -- If simultaneous read and write when almost empty
    if count = 1 and read_while_write_p1 = '1' then
      out_tvalid_i <= '0';
    end if;

  end process;

end architecture;