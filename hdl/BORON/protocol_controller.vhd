library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity protocol_controller is
    port (
        clk_i         : in  std_logic;
        rst_ni        : in  std_logic;
        -- UART interface
        rx_data_i     : in  std_logic_vector(7 downto 0);
        rx_valid_i    : in  std_logic;
        tx_data_o     : out std_logic_vector(7 downto 0);
        tx_send_o     : out std_logic;
        tx_busy_i     : in  std_logic;
        -- BORON interface
        plain_text_o  : out std_logic_vector(63 downto 0);
        key_o         : out std_logic_vector(79 downto 0);
        start_o       : out std_logic;
        cipher_text_i : in  std_logic_vector(63 downto 0);
        done_i        : in  std_logic
    );
end protocol_controller;

architecture Behavioral of protocol_controller is
    type state_t is (IDLE, COLLECT_KEY, COLLECT_DATA, ENCRYPT, SEND_RESULT);
    signal state : state_t;
    
    signal key_buffer    : std_logic_vector(79 downto 0);
    signal data_buffer   : std_logic_vector(63 downto 0);
    signal result_buffer : std_logic_vector(63 downto 0);
    
    signal byte_counter  : unsigned(3 downto 0);
    signal send_counter  : unsigned(3 downto 0);
    
begin
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            state         <= IDLE;
            key_buffer    <= (others => '0');
            data_buffer   <= (others => '0');
            result_buffer <= (others => '0');
            byte_counter  <= (others => '0');
            send_counter  <= (others => '0');
            tx_data_o     <= (others => '0');
            tx_send_o     <= '0';
            plain_text_o  <= (others => '0');
            key_o         <= (others => '0');
            start_o       <= '0';
        elsif rising_edge(clk_i) then
            tx_send_o <= '0';
            start_o   <= '0';
            
            case state is
                when IDLE =>
                    if rx_valid_i = '1' then
                        if rx_data_i = x"4B" then -- 'K' for Key
                            state        <= COLLECT_KEY;
                            byte_counter <= (others => '0');
                        elsif rx_data_i = x"44" then -- 'D' for Data
                            state        <= COLLECT_DATA;
                            byte_counter <= (others => '0');
                        end if;
                    end if;
                    
                when COLLECT_KEY =>
                    if rx_valid_i = '1' then
                        -- Collect 10 bytes for 80-bit key
                        key_buffer(79 - to_integer(byte_counter)*8 downto 72 - to_integer(byte_counter)*8) <= rx_data_i;
                        if byte_counter = 9 then
                            state <= IDLE;
                            key_o <= key_buffer;
                        else
                            byte_counter <= byte_counter + 1;
                        end if;
                    end if;
                    
                when COLLECT_DATA =>
                    if rx_valid_i = '1' then
                        -- Collect 8 bytes for 64-bit data
                        data_buffer(63 - to_integer(byte_counter)*8 downto 56 - to_integer(byte_counter)*8) <= rx_data_i;
                        if byte_counter = 7 then
                            state         <= ENCRYPT;
                            plain_text_o  <= data_buffer;
                            start_o       <= '1';
                        else
                            byte_counter <= byte_counter + 1;
                        end if;
                    end if;
                    
                when ENCRYPT =>
                    if done_i = '1' then
                        result_buffer <= cipher_text_i;
                        state         <= SEND_RESULT;
                        send_counter  <= (others => '0');
                    end if;
                    
                when SEND_RESULT =>
                    if tx_busy_i = '0' then
                        -- Send 8 bytes of cipher text
                        tx_data_o <= result_buffer(63 - to_integer(send_counter)*8 downto 56 - to_integer(send_counter)*8);
                        tx_send_o <= '1';
                        if send_counter = 7 then
                            state <= IDLE;
                        else
                            send_counter <= send_counter + 1;
                        end if;
                    end if;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;