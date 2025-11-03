LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria IS
    PORT (
        address_bus 	: IN  unsigned(7 downto 0);
        data_in     		: IN  unsigned(7 downto 0);
        data_out    	: OUT unsigned(7 downto 0);
        mem_write   	: IN  std_logic;
        clk         		: IN  std_logic
    );
END memoria;

ARCHITECTURE MEMO OF memoria IS
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0); 
    signal data_array_sig : data_array_type; 

BEGIN
    process (clk)
    begin
        IF (rising_edge(clk)) THEN
            if mem_write = '1' then
                data_array_sig(to_integer(address_bus)) <= data_in;
            end if; 
        END IF;     
    end process;
    
    data_out <= data_array_sig(to_integer(address_bus));
END MEMO;