LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria IS
    PORT (
        address_bus : IN  unsigned(7 downto 0);
        data_in     : IN  unsigned(7 downto 0);
        data_out    : OUT unsigned(7 downto 0);
        mem_write   : IN  std_logic;
        clk         : IN  std_logic;
        rst         : IN  std_logic
    );
END memoria;

ARCHITECTURE MEMO OF memoria IS

    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    SIGNAL data_array_sig : data_array_type;

BEGIN

    process (clk)
    begin

        IF (rising_edge(clk)) THEN
            IF (rst = '1') THEN
                data_array_sig <= (others => (others => '0'));
            ELSE
                IF mem_write = '1' THEN
                    data_array_sig(to_integer(address_bus)) <= data_in;
                END IF;
            END IF;
        END IF;
    end process;

    data_out <= data_array_sig(to_integer());

END MEMO;