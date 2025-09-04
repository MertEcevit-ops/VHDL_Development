library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_generator_plus_vga_interface is
    generic (
        -- VGA 640x480 @ 60Hz timing parameters
        H_LOW  : natural := 96;   -- Horizontal sync pulse width
        HBP    : natural := 48;   -- Horizontal back porch
        H_HIGH : natural := 640;  -- Visible horizontal pixels
        HFP    : natural := 16;   -- Horizontal front porch
        V_LOW  : natural := 2;    -- Vertical sync pulse width
        VBP    : natural := 33;   -- Vertical back porch
        V_HIGH : natural := 480;  -- Visible vertical pixels
        VFP    : natural := 10    -- Vertical front porch
    );
    port (
        clk         : in std_logic;  -- 25MHz pixel clock
        rst         : in std_logic;  -- Reset signal
        R_switch    : in std_logic;  -- Red pattern enable
        G_switch    : in std_logic;  -- Green pattern enable
        B_switch    : in std_logic;  -- Blue pattern enable
        
        -- VGA outputs
        Hsync       : out std_logic; -- Horizontal sync
        Vsync       : out std_logic; -- Vertical sync
        R           : out std_logic_vector(3 downto 0); -- Red output
        G           : out std_logic_vector(3 downto 0); -- Green output
        B           : out std_logic_vector(3 downto 0); -- Blue output
        BLANK       : out std_logic; -- Blank signal
        SYNC        : out std_logic  -- Composite sync
    );
end entity;

architecture rtl of image_generator_plus_vga_interface is
    -- Horizontal and vertical counters
    signal Hcount : natural range 0 to H_LOW + HBP + H_HIGH + HFP;
    signal Vcount : natural range 0 to V_LOW + VBP + V_HIGH + VFP;
    
    -- Line count for pattern generation
    signal line_count : natural range 0 to V_HIGH;
    
    -- Display enable signals
    signal Hactive : std_logic;
    signal Vactive : std_logic;
    signal dena    : std_logic;
    
    -- Internal sync signals
    signal Hsync_int : std_logic;
    signal Vsync_int : std_logic;

begin

    -- CIRCUIT 1: VGA TIMING GENERATOR
    
    -- Horizontal counter process
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                Hcount <= 0;
            else
                if Hcount = H_LOW + HBP + H_HIGH + HFP - 1 then
                    Hcount <= 0;
                else
                    Hcount <= Hcount + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Vertical counter process
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                Vcount <= 0;
            else
                if Hcount = H_LOW + HBP + H_HIGH + HFP - 1 then
                    if Vcount = V_LOW + VBP + V_HIGH + VFP - 1 then
                        Vcount <= 0;
                    else
                        Vcount <= Vcount + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate horizontal sync
    Hsync_int <= '0' when Hcount < H_LOW else '1';
    
    -- Generate vertical sync  
    Vsync_int <= '0' when Vcount < V_LOW else '1';
    
    -- Generate active display regions
    Hactive <= '1' when Hcount >= H_LOW + HBP and Hcount < H_LOW + HBP + H_HIGH else '0';
    Vactive <= '1' when Vcount >= V_LOW + VBP and Vcount < V_LOW + VBP + V_HIGH else '0';
    
    -- Display enable
    dena <= Hactive and Vactive;
    
    -- CIRCUIT 2: PATTERN GENERATOR
    
    -- Line counter for pattern generation
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                line_count <= 0;
            else
                if Vactive = '1' then
                    if Hcount = H_LOW + HBP then -- Start of visible line
                        if Vcount = V_LOW + VBP then -- First visible line
                            line_count <= 0;
                        elsif line_count < V_HIGH - 1 then
                            line_count <= line_count + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Pattern generation process
    process (clk)
        variable pixel_x : natural range 0 to H_HIGH;
        variable pixel_y : natural range 0 to V_HIGH;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            else
                if dena = '1' then
                    pixel_x := Hcount - (H_LOW + HBP);
                    pixel_y := line_count;
                    
                    -- Pattern generation based on vertical position
                    if pixel_y < 160 then
                        -- Red region (top third): Horizontal stripes
                        if (pixel_y / 10) mod 2 = 0 then
                            R <= "1111";  -- Bright red
                            G <= "0000";
                            B <= "0000";
                        else
                            R <= "1000";  -- Dim red
                            G <= "0000";
                            B <= "0000";
                        end if;
                        
                    elsif pixel_y < 320 then
                        -- Green region (middle third): Vertical stripes
                        if (pixel_x / 20) mod 2 = 0 then
                            R <= "0000";
                            G <= "1111";  -- Bright green
                            B <= "0000";
                        else
                            R <= "0000";
                            G <= "1000";  -- Dim green
                            B <= "0000";
                        end if;
                        
                    else
                        -- Blue region (bottom third): Checkerboard pattern
                        if ((pixel_x / 20) + (pixel_y / 20)) mod 2 = 0 then
                            R <= "0000";
                            G <= "0000";
                            B <= "1111";  -- Bright blue
                        else
                            R <= "0000";
                            G <= "0000";
                            B <= "1000";  -- Dim blue
                        end if;
                    end if;
                    
                    -- Apply switch controls for mixing colors
                    if R_switch = '0' then
                        R <= "0000";
                    end if;
                    if G_switch = '0' then
                        G <= "0000";
                    end if;
                    if B_switch = '0' then
                        B <= "0000";
                    end if;
                    
                else
                    -- Blank period - no color output
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    -- Output assignments
    Hsync <= Hsync_int;
    Vsync <= Vsync_int;
    BLANK <= dena;
    SYNC <= Hsync_int and Vsync_int;

end architecture;