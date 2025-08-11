----------------------------------------------------------------------
-- UART Receiver with BRAM FIFO Buffer
-- Uses external BRAM-based FIFO for better resource utilization
-- Significantly reduces LUT and FF usage
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        g_CLKS_PER_BIT : integer := 868;   -- Clock cycles per bit
        FIFO_DEPTH     : integer := 256    -- RX FIFO depth (BRAM friendly)
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_rx_serial : in  std_logic;
        
        -- FIFO read interface
        i_rd_en     : in  std_logic;
        o_rx_data   : out std_logic_vector(7 downto 0);
        o_rx_empty  : out std_logic;
        o_rx_full   : out std_logic;
        o_rx_count  : out std_logic_vector(9 downto 0);
        
        -- Status
        o_rx_error  : out std_logic
    );
end uart_rx;

architecture behavioral of uart_rx is
    
    -- UART RX State Machine
    type uart_rx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal uart_state : uart_rx_state_t := IDLE;
    
    -- UART RX signals
    signal clk_counter : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal rx_byte_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_rx_dv  : std_logic := '0';
    
    -- FIFO interface signals
    signal fifo_wr_en   : std_logic;
    signal fifo_wr_data : std_logic_vector(7 downto 0);
    signal fifo_rd_en   : std_logic;
    signal fifo_rd_data : std_logic_vector(7 downto 0);
    signal fifo_full    : std_logic;
    signal fifo_empty   : std_logic;
    signal fifo_count   : std_logic_vector(9 downto 0);
    
    -- Error signals
    signal rx_overflow  : std_logic := '0';
    
    -- BRAM FIFO component
    component fifo is
        generic (
            FIFO_DEPTH : integer := 512;
            DATA_WIDTH : integer := 8
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            wr_en      : in  std_logic;
            wr_data    : in  std_logic_vector(7 downto 0);
            rd_en      : in  std_logic;
            rd_data    : out std_logic_vector(7 downto 0);
            full       : out std_logic;
            empty      : out std_logic;
            count      : out std_logic_vector(9 downto 0)
        );
    end component;
    
begin
    
    -- BRAM FIFO instantiation
    fifo_inst : fifo
        generic map (
            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => 8
        )
        port map (
            clk     => i_clk,
            rst     => i_rst,
            wr_en   => fifo_wr_en,
            wr_data => fifo_wr_data,
            rd_en   => fifo_rd_en,
            rd_data => fifo_rd_data,
            full    => fifo_full,
            empty   => fifo_empty,
            count   => fifo_count
        );
    
    -----------------------------------------------------------------------
    -- UART RX Core Logic (Simplified)
    -----------------------------------------------------------------------
    uart_rx_process : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                uart_state <= IDLE;
                clk_counter <= 0;
                bit_counter <= 0;
                rx_byte_reg <= (others => '0');
                uart_rx_dv <= '0';
                
            else
                -- Default assignment
                uart_rx_dv <= '0';
                
                case uart_state is
                    
                    when IDLE =>
                        clk_counter <= 0;
                        bit_counter <= 0;
                        
                        if i_rx_serial = '0' then  -- Start bit detected
                            uart_state <= START_BIT;
                        end if;
                        
                    when START_BIT =>
                        -- Check middle of start bit
                        if clk_counter = (g_CLKS_PER_BIT-1)/2 then
                            if i_rx_serial = '0' then
                                clk_counter <= 0;
                                uart_state <= DATA_BITS;
                            else
                                uart_state <= IDLE;  -- False start
                            end if;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;
                        
                    when DATA_BITS =>
                        if clk_counter < g_CLKS_PER_BIT-1 then
                            clk_counter <= clk_counter + 1;
                        else
                            clk_counter <= 0;
                            rx_byte_reg(bit_counter) <= i_rx_serial;
                            
                            if bit_counter < 7 then
                                bit_counter <= bit_counter + 1;
                            else
                                bit_counter <= 0;
                                uart_state <= STOP_BIT;
                            end if;
                        end if;
                        
                    when STOP_BIT =>
                        if clk_counter < g_CLKS_PER_BIT-1 then
                            clk_counter <= clk_counter + 1;
                        else
                            uart_rx_dv <= '1';
                            clk_counter <= 0;
                            uart_state <= CLEANUP;
                        end if;
                        
                    when CLEANUP =>
                        uart_state <= IDLE;
                        
                end case;
            end if;
        end if;
    end process uart_rx_process;
    
    -----------------------------------------------------------------------
    -- FIFO Control Logic
    -----------------------------------------------------------------------
    fifo_control_process : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                rx_overflow <= '0';
            else
                -- Write to FIFO when data is valid
                if uart_rx_dv = '1' and fifo_full = '0' then
                    -- Normal write operation
                    null;
                elsif uart_rx_dv = '1' and fifo_full = '1' then
                    -- Overflow condition
                    rx_overflow <= '1';
                end if;
            end if;
        end if;
    end process fifo_control_process;
    
    -----------------------------------------------------------------------
    -- Signal Assignments
    -----------------------------------------------------------------------
    
    -- FIFO control
    fifo_wr_en <= uart_rx_dv and (not fifo_full);
    fifo_wr_data <= rx_byte_reg;
    fifo_rd_en <= i_rd_en;
    
    -- Output assignments
    o_rx_data <= fifo_rd_data;
    o_rx_empty <= fifo_empty;
    o_rx_full <= fifo_full;
    o_rx_count <= fifo_count;
    o_rx_error <= rx_overflow;
    
end behavioral;