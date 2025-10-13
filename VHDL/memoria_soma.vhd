LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria_soma IS
    PORT (
        address_bus : IN  unsigned(7 downto 0);
        data_in     : IN  unsigned(7 downto 0);
        data_out    : OUT unsigned(7 downto 0);
        mem_write   : IN  std_logic;
        clk         : IN  std_logic;
        rst         : IN  std_logic
    );
END memoria_soma;

ARCHITECTURE MEMO OF memoria_soma IS
    -- Opcodes
    constant STA    : unsigned(7 downto 0) := x"10";
    constant LDA    : unsigned(7 downto 0) := x"20";
    constant ADD    : unsigned(7 downto 0) := x"30";
    constant HLT    : unsigned(7 downto 0) := x"F0";

    -- Tipo da memória
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    signal data_array_sig : data_array_type;

BEGIN
    process(rst, clk)
        variable data_array : data_array_type;
    BEGIN
        if rst = '1' then
            data_array := (others => (others => '0'));

            -- Programa para somar 6 + 4
            data_array(0) := LDA;
            data_array(1) := to_unsigned(100, 8); -- carregar do endereço 100
            data_array(2) := ADD; -- x"30"
            data_array(3) := to_unsigned(101, 8); -- carregar do endereço 101
            data_array(4) := STA;
            data_array(5) := to_unsigned(102, 8); 
            data_array(6) := HLT;

            -- Data
            -- 6
            data_array(100) := to_unsigned(6, 8);
            -- 4
            data_array(101) := to_unsigned(4, 8);

        elsif rising_edge(clk) then
            if mem_write = '1' then
                data_array(to_integer(address_bus)) := data_in;
            end if;
        end if;
        data_array_sig <= data_array;
    end process;

    data_out <= data_array_sig(to_integer(address_bus));

END MEMO;