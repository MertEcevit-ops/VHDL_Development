library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic (
        N_BOUNCE  : integer := 3;  -- Bouncing interval in clock cycles = 2^N_BOUNCE
        IS_PULLUP : integer := 0   -- '1' for pull-up switch, '0' for pull-down switch
    );
    port (
        clk_i    : in  std_logic;
        rst_ni   : in  std_logic;  -- Active-low reset
        din_i    : in  std_logic;  -- Input
        bounce_o : out std_logic   -- Debounced input signal
    );
end debouncer;

architecture Behavioral of debouncer is
    signal isig_rg, isig_sync_rg          : std_logic;
    signal sig_rg, sig_d_rg, sig_debounced_rg : std_logic;
    signal counter_rg                      : unsigned(N_BOUNCE downto 0);
    signal nxt_cnt                         : unsigned(N_BOUNCE downto 0);
    
    function bool_to_sl(b : boolean) return std_logic is
    begin
        if b then return '1'; else return '0'; end if;
    end function;
    
begin
    -- Main debouncing logic
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            sig_rg           <= bool_to_sl(IS_PULLUP = 1);
            sig_d_rg         <= bool_to_sl(IS_PULLUP = 1);
            sig_debounced_rg <= bool_to_sl(IS_PULLUP = 1);
            counter_rg       <= to_unsigned(1, N_BOUNCE + 1);
        elsif rising_edge(clk_i) then
            sig_rg   <= isig_sync_rg;
            sig_d_rg <= sig_rg;
            
            if sig_d_rg = sig_rg then
                counter_rg <= nxt_cnt;
            else
                counter_rg <= to_unsigned(1, N_BOUNCE + 1);
            end if;
            
            if counter_rg(N_BOUNCE) = '1' then
                sig_debounced_rg <= sig_d_rg;
            end if;
        end if;
    end process;
    
    nxt_cnt <= counter_rg when counter_rg(N_BOUNCE) = '1' else counter_rg + 1;
    
    -- 2FF Synchronizer
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            isig_rg      <= bool_to_sl(IS_PULLUP = 1);
            isig_sync_rg <= bool_to_sl(IS_PULLUP = 1);
        elsif rising_edge(clk_i) then
            isig_rg      <= din_i;
            isig_sync_rg <= isig_rg;
        end if;
    end process;
    
    bounce_o <= sig_debounced_rg;
end Behavioral;