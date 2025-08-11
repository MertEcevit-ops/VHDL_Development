----------------------------------------------------------------------
-- UART Transmitter with BRAM FIFO Buffer
-- Uses external BRAM-based FIFO for better resource utilization
-- Significantly reduces LUT and FF usage
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        g_CLKS_PER_BIT : integer := 868;   -- Clock cycles per bit
        FIFO_DEPTH     : integer := 256    -- TX FIFO depth (BRAM friendly)
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        
        -- FIFO write interface
        i_wr_en     : in  std_logic;
        i_tx_data   : in  std_logic_vector(7 downto 0);
        o_tx_full   : out std_logic;
        o_tx_empty  : out std_logic;
        o_tx_count  : out std_logic_vector(9 downto 0);
        
        -- UART output
        o_tx_line   : out std_logic;
        o_tx_busy   : out std_logic
    );
end uart_tx;

architecture behavioral of uart_tx is
    
    -- UART TX State Machine
    type uart_tx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal uart_state : uart_tx_state_t := IDLE;
    
    -- UART TX signals
    signal clk_counter : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal tx_buffer   : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_busy : std_logic := '0';
    signal uart_tx_done : std_logic := '0';
    signal tx_line_reg  : std_logic := '1';
    
    -- FIFO interface signals
    signal fifo_wr_en   : std_logic;
    signal fifo_wr_data : std_logic_vector(7 downto 0);
    signal fifo_rd_en   : std_logic;
    signal fifo_rd_data : std_logic_vector(7 downto 0);
    signal fifo_full    : std_logic;
    signal fifo_empty   : std_logic;
    signal fifo_count   : std_logic_vector(9 downto 0);
    
    -- TX control signals
    signal uart_tx_start : std_logic;
    
    -- TX controller state machine
    type tx_ctrl_state_t is (CTRL_IDLE, CTRL_READ_FIFO, CTRL_TRANSMITTING);
    signal tx_ctrl_state : tx_ctrl_state_t := CTRL_IDLE;
    
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
    -- UART TX Core Logic (Simplified)
    -----------------------------------------------------------------------
    uart_tx_process : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                uart_state <= IDLE;
                clk_counter <= 0;
                bit_counter <= 0;
                tx_buffer <= (others => '0');
                uart_tx_busy <= '0';
                uart_tx_done <= '0';
                tx_line_reg <= '1';
                
            else
                -- Default assignments
                uart_tx_done <= '0';
                
                case uart_state is
                    
                    when IDLE =>
                        tx_line_reg <= '1';  -- Line idle high
                        uart_tx_busy <= '0';
                        clk_counter <= 0;
                        bit_counter <= 0;
                        
                        if uart_tx_start = '1' then
                            tx_buffer <= fifo_rd_data;
                            uart_state <= START_BIT;
                            uart_tx_busy <= '1';
                        end if;
                        
                    when START_BIT =>
                        tx_line_reg <= '0';  -- Start bit is low
                        uart_tx_busy <= '1';
                        
                        if clk_counter < g_CLKS_PER_BIT-1 then
                            clk_counter <= clk_counter + 1;
                        else
                            clk_counter <= 0;
                            uart_state <= DATA_BITS;
                            bit_counter <= 0;
                        end if;
                        
                    when DATA_BITS =>
                        tx_line_reg <= tx_buffer(bit_counter);  -- Send LSB first
                        uart_tx_busy <= '1';
                        
                        if clk_counter < g_CLKS_PER_BIT-1 then
                            clk_counter <= clk_counter + 1;
                        else
                            clk_counter <= 0;
                            
                            if bit_counter < 7 then
                                bit_counter <= bit_counter + 1;
                            else
                                bit_counter <= 0;
                                uart_state <= STOP_BIT;
                            end if;
                        end if;
                        
                    when STOP_BIT =>
                        tx_line_reg <= '1';  -- Stop bit is high
                        uart_tx_busy <= '1';
                        
                        if clk_counter < g_CLKS_PER_BIT-1 then
                            clk_counter <= clk_counter + 1;
                        else
                            clk_counter <= 0;
                            uart_tx_done <= '1';
                            uart_state <= IDLE;
                        end if;
                        
                end case;
            end if;
        end if;
    end process uart_tx_process;
    
    -----------------------------------------------------------------------
    -- TX Controller State Machine (Simplified)
    -----------------------------------------------------------------------
    tx_controller_process : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                tx_ctrl_state <= CTRL_IDLE;
                uart_tx_start <= '0';
                fifo_rd_en <= '0';
                
            else
                -- Default assignments
                uart_tx_start <= '0';
                fifo_rd_en <= '0';
                
                case tx_ctrl_state is
                    
                    when CTRL_IDLE =>
                        if fifo_empty = '0' and uart_tx_busy = '0' then
                            tx_ctrl_state <= CTRL_READ_FIFO;
                        end if;
                        
                    when CTRL_READ_FIFO =>
                        fifo_rd_en <= '1';
                        uart_tx_start <= '1';
                        tx_ctrl_state <= CTRL_TRANSMITTING;
                        
                    when CTRL_TRANSMITTING =>
                        if uart_tx_done = '1' then
                            tx_ctrl_state <= CTRL_IDLE;
                        end if;
                        
                end case;
            end if;
        end if;
    end process tx_controller_process;
    
    -----------------------------------------------------------------------
    -- Signal Assignments
    -----------------------------------------------------------------------
    
    -- FIFO control
    fifo_wr_en <= i_wr_en;
    fifo_wr_data <= i_tx_data;
    
    -- Output assignments
    o_tx_full <= fifo_full;
    o_tx_empty <= fifo_empty;
    o_tx_count <= fifo_count;
    o_tx_line <= tx_line_reg;
    o_tx_busy <= uart_tx_busy or (not fifo_empty);
    
end behavioral;