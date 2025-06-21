---------------------------------------------------------------------------------------------------
-- Company           : FPGA_FROM_ZERO_TO_HERO
-- Engineer          : Mert Ecevit
-- 
-- Create Date       : 26.02.2025 21:36
-- Design Name       : Unified Reset Synchronizer
-- Module Name       : unified_reset_synchronizer - behavioral
-- Project Name      : FILTER
-- Target Devices    : Multi-vendor FPGA support
-- Tool Versions     : Multi-vendor EDA tools
-- Description       : Unified reset synchronizer with vendor-specific optimizations
--                     Supports both simple sync and extended strobe modes
-- 
-- Dependencies      : none
-- 
-- Revision:
-- Revision 0.01 - File created
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity reset_sync is
    generic (
        VENDOR                : string               := "GOWIN";         -- "XILINX", "ALTERA", "GOWIN"
        RESET_MODE            : string               := "SIMPLE";        -- "SIMPLE", "STROBE"
        RESET_ACTIVE_STATUS   : std_logic            := '1';             -- '0': active low, '1': active high
        ASYNCH_FF_NUMBER      : natural range 2 to 5 := 3;              -- For simple mode
        RST_STROBE_CYCLES     : positive             := 128;             -- For strobe mode
        RST_IN_ACTIVE_VALUE   : std_logic            := '1';             -- Input reset polarity
        RST_OUT_ACTIVE_VALUE  : std_logic            := '1'              -- Output reset polarity
    );
    port (
        clk     : in std_logic;
        rst_in  : in std_logic;  -- asynchronous reset input
        rst_out : out std_logic := RST_OUT_ACTIVE_VALUE  -- synchronously de-asserted reset output
    );
end entity reset_sync;

architecture behavioral of reset_sync is

    -- Simple mode signals
    signal async_chain : std_logic_vector(ASYNCH_FF_NUMBER-1 downto 0) := (others => (not RESET_ACTIVE_STATUS));
    
    -- Strobe mode signals
    constant counter_max : integer := RST_STROBE_CYCLES - 1;
    signal counter : integer range 0 to counter_max := 0;
    signal rst_in_p1 : std_logic := not RST_IN_ACTIVE_VALUE;
    signal rst_in_p2 : std_logic := not RST_IN_ACTIVE_VALUE;

begin

    -- Simple synchronizer mode
    simple_mode : if RESET_MODE = "SIMPLE" generate
    
-- -- Xilinx-specific implementation
-- xilinx_impl : if VENDOR = "XILINX" generate
--     attribute ASYNC_REG                 : string;
--     attribute ASYNC_REG  of async_chain : signal is "true";
--     attribute DONT_TOUCH                : string;
--     attribute DONT_TOUCH of async_chain : signal is "true";
-- begin
--     proc_xilinx_sync : process (clk, rst_in)
--     begin
--         if rst_in = RESET_ACTIVE_STATUS then
--             async_chain <= (others => RESET_ACTIVE_STATUS);
--         elsif rising_edge(clk) then
--             async_chain <= async_chain(ASYNCH_FF_NUMBER-2 downto 0) & (not RESET_ACTIVE_STATUS);
--         end if;
--     end process proc_xilinx_sync;
--
--     rst_out <= async_chain(ASYNCH_FF_NUMBER-1);
-- end generate xilinx_impl;
--
-- -- Intel/Altera-specific implementation
-- altera_impl : if VENDOR = "ALTERA" generate
--     attribute ALTERA_ATTRIBUTE             : string;
--     attribute ALTERA_ATTRIBUTE of async_chain : signal is "PRESERVE_REGISTER=ON";
--     attribute DONT_MERGE                   : string;
--     attribute DONT_MERGE of async_chain    : signal is "true";
--     attribute PRESERVE                     : string;
--     attribute PRESERVE of async_chain      : signal is "true";
-- begin
--     proc_altera_sync : process (clk, rst_in)
--     begin
--         if rst_in = RESET_ACTIVE_STATUS then
--             async_chain <= (others => RESET_ACTIVE_STATUS);
--         elsif rising_edge(clk) then
--             async_chain <= async_chain(ASYNCH_FF_NUMBER-2 downto 0) & (not RESET_ACTIVE_STATUS);
--         end if;
--     end process proc_altera_sync;
--
--     rst_out <= async_chain(ASYNCH_FF_NUMBER-1);
-- end generate altera_impl;
--
   -- GOWIN-specific implementation
   gowin_impl : if VENDOR = "GOWIN" generate
      -- attribute SYN_PRESERVE : integer;
      -- attribute SYN_PRESERVE of async_chain : signal is 1;
   begin
       proc_gowin_sync : process (clk, rst_in)
       begin
           if rst_in = RESET_ACTIVE_STATUS then
               async_chain <= (others => RESET_ACTIVE_STATUS);
           elsif rising_edge(clk) then
               async_chain <= async_chain(ASYNCH_FF_NUMBER-2 downto 0) & (not RESET_ACTIVE_STATUS);
           end if;
       end process proc_gowin_sync;
            rst_out <= async_chain(ASYNCH_FF_NUMBER-1);
        end generate gowin_impl;
        
    end generate simple_mode;

 -- -- Strobe synchronizer mode
 -- strobe_mode : if RESET_MODE = "STROBE" generate
 -- 
 --     -- Xilinx-specific implementation
 --     xilinx_strobe_impl : if VENDOR = "XILINX" generate
 --         attribute ASYNC_REG                 : string;
 --         attribute ASYNC_REG  of rst_in_p1   : signal is "true";
 --         attribute ASYNC_REG  of rst_in_p2   : signal is "true";
 --         attribute DONT_TOUCH                : string;
 --         attribute DONT_TOUCH of rst_in_p1   : signal is "true";
 --         attribute DONT_TOUCH of rst_in_p2   : signal is "true";
 --     begin
 --         -- 2FF synchronizer to avoid metastability
 --         sync_proc_xilinx : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 rst_in_p2 <= rst_in_p1;
 --                 rst_in_p1 <= rst_in;
 --             end if;
 --         end process;

 --         -- Generate the rst_out signal
 --         rst_out_proc_xilinx : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 -- Synchronous reset
 --                 if rst_in_p2 = RST_IN_ACTIVE_VALUE then
 --                     rst_out <= RST_OUT_ACTIVE_VALUE;
 --                     counter <= 0;
 --                 else
 --                     -- Keep rst_out active for N clock cycles
 --                     if counter = counter_max then
 --                         rst_out <= not RST_OUT_ACTIVE_VALUE;
 --                     else
 --                         counter <= counter + 1;
 --                     end if;
 --                 end if;
 --             end if;
 --         end process;
 --     end generate xilinx_strobe_impl;

 --     -- Intel/Altera-specific implementation
 --     altera_strobe_impl : if VENDOR = "ALTERA" generate
 --         attribute ALTERA_ATTRIBUTE             : string;
 --         attribute ALTERA_ATTRIBUTE of rst_in_p1 : signal is "PRESERVE_REGISTER=ON";
 --         attribute ALTERA_ATTRIBUTE of rst_in_p2 : signal is "PRESERVE_REGISTER=ON";
 --         attribute PRESERVE                     : string;
 --         attribute PRESERVE of rst_in_p1        : signal is "true";
 --         attribute PRESERVE of rst_in_p2        : signal is "true";
 --     begin
 --         -- 2FF synchronizer to avoid metastability
 --         sync_proc_altera : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 rst_in_p2 <= rst_in_p1;
 --                 rst_in_p1 <= rst_in;
 --             end if;
 --         end process;

 --         -- Generate the rst_out signal
 --         rst_out_proc_altera : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 -- Synchronous reset
 --                 if rst_in_p2 = RST_IN_ACTIVE_VALUE then
 --                     rst_out <= RST_OUT_ACTIVE_VALUE;
 --                     counter <= 0;
 --                 else
 --                     -- Keep rst_out active for N clock cycles
 --                     if counter = counter_max then
 --                         rst_out <= not RST_OUT_ACTIVE_VALUE;
 --                     else
 --                         counter <= counter + 1;
 --                     end if;
 --                 end if;
 --             end if;
 --         end process;
 --     end generate altera_strobe_impl;

 --     -- GOWIN-specific implementation
 --     gowin_strobe_impl : if VENDOR = "GOWIN" generate
 --         attribute SYN_PRESERVE : integer;
 --         attribute SYN_PRESERVE of rst_in_p1 : signal is 1;
 --         attribute SYN_PRESERVE of rst_in_p2 : signal is 1;
 --     begin
 --         -- 2FF synchronizer to avoid metastability
 --         sync_proc_gowin : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 rst_in_p2 <= rst_in_p1;
 --                 rst_in_p1 <= rst_in;
 --             end if;
 --         end process;

 --         -- Generate the rst_out signal
 --         rst_out_proc_gowin : process(clk)
 --         begin
 --             if rising_edge(clk) then
 --                 -- Synchronous reset
 --                 if rst_in_p2 = RST_IN_ACTIVE_VALUE then
 --                     rst_out <= RST_OUT_ACTIVE_VALUE;
 --                     counter <= 0;
 --                 else
 --                     -- Keep rst_out active for N clock cycles
 --                     if counter = counter_max then
 --                         rst_out <= not RST_OUT_ACTIVE_VALUE;
 --                     else
 --                         counter <= counter + 1;
 --                     end if;
 --                 end if;
 --             end if;
 --         end process;
 --     end generate gowin_strobe_impl;
 --     
 -- end generate strobe_mode;

end architecture behavioral;