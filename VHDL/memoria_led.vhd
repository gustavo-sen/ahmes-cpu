LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria IS
    PORT (
        address_bus 	: IN  unsigned(7 downto 0);
        data_in     		: IN  unsigned(7 downto 0);
        data_out    	: OUT unsigned(7 downto 0);
        mem_write   	: IN  std_logic;
        clk         		: IN  std_logic;
        rst         		: IN  std_logic
    );
END memoria;

ARCHITECTURE MEMO OF memoria IS
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0); 
    signal data_array_sig : data_array_type; 

BEGIN
    process (rst, clk)
    begin
        IF (rst = '1') THEN
            data_array_sig <= (others => (others => '0'));
			
			-- Programa de inicialização:
            -- 0x00: LDA 0x10   (carrega AC com o dado em 0x10)
            -- 0x02: STA 0xF8   (escreve AC nos LEDs — ADDR_LED = 0xF8)
            -- 0x04: JMP 0x04   (loop infinito)
            -- 0x10: 0x0F       (dado: 00001111 -> 4 LEDs ligados)
            data_array_sig(0)  	<= x"20"; -- LDA
            data_array_sig(1)  	<= x"10"; -- endereço do dado (0x10)
            data_array_sig(2)  	<= x"10"; -- STA
            data_array_sig(3)  	<= x"F8"; -- Endereco Base LED
            data_array_sig(4)  	<= x"80"; -- JMP
            data_array_sig(5)  	<= x"00"; -- addr destino JMP
			
            data_array_sig(16) 	<= x"FD"; 
            
        ELSIF (rising_edge(clk)) THEN
            if mem_write = '1' then
                data_array_sig(to_integer(address_bus)) <= data_in;
            end if; 
        END IF;     
    end process;
    
    data_out <= (others => '0') when rst = '1' else data_array_sig(to_integer(address_bus));
END MEMO;