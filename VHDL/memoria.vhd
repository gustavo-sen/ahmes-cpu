LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; -- Biblioteca padrão moderna

ENTITY memoria IS
    PORT (
        -- Alterado de INTEGER para unsigned para melhor representar um barramento de hardware
        address_bus : IN  unsigned(7 downto 0);
        data_in     : IN  unsigned(7 downto 0);
        data_out    : OUT unsigned(7 downto 0);
        mem_write   : IN  std_logic;
        clk         : IN  std_logic;
        rst         : IN  std_logic
    );
END memoria;

ARCHITECTURE MEMO OF memoria IS
    -- Constantes convertidas para unsigned(7 downto 0) usando notação hexadecimal
    constant STA      : unsigned(7 downto 0) := x"10";
    constant LDA      : unsigned(7 downto 0) := x"20";
    constant ADD      : unsigned(7 downto 0) := x"30";
    constant SUB      : unsigned(7 downto 0) := x"70";
    constant JMP      : unsigned(7 downto 0) := x"80";
    constant JZ       : unsigned(7 downto 0) := x"A0";
    constant IOR      : unsigned(7 downto 0) := x"40";
    constant SHL      : unsigned(7 downto 0) := x"E1";
    constant HLT      : unsigned(7 downto 0) := x"F0";
    
    -- Tipo da memória agora armazena vetores unsigned
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    signal data_array_sig : data_array_type;

BEGIN
    process (rst, clk)
    begin
        IF (rst = '1') THEN
            -- Inicializa a memória com o programa durante o reset
            -- Literais inteiros são convertidos para unsigned de 8 bits
            data_array_sig(0) <= LDA;
            data_array_sig(1) <= to_unsigned(130, 8);
            data_array_sig(2) <= SUB;
            data_array_sig(3) <= to_unsigned(132, 8);
            data_array_sig(4) <= JZ;
            data_array_sig(5) <= to_unsigned(8, 8);
            data_array_sig(6) <= JMP;
            data_array_sig(7) <= to_unsigned(2, 8);
            data_array_sig(8) <= LDA;
            data_array_sig(9) <= to_unsigned(130, 8);
            data_array_sig(10) <= ADD;
            data_array_sig(11) <= to_unsigned(131, 8);
            data_array_sig(12) <= STA;
            data_array_sig(13) <= to_unsigned(128, 8);
            data_array_sig(14) <= LDA;
            data_array_sig(15) <= to_unsigned(129, 8);
            data_array_sig(16) <= SHL;
            data_array_sig(17) <= SHL;
            data_array_sig(18) <= SHL;
            data_array_sig(19) <= SHL;
            data_array_sig(20) <= IOR;
            data_array_sig(21) <= to_unsigned(128, 8);
            data_array_sig(22) <= STA;
            data_array_sig(23) <= to_unsigned(133, 8);
            data_array_sig(24) <= HLT;
            
            -- Dados do programa
            data_array_sig(128) <= to_unsigned(0, 8);
            data_array_sig(129) <= to_unsigned(5, 8);
            data_array_sig(130) <= to_unsigned(10, 8);
            data_array_sig(131) <= to_unsigned(18, 8);
            data_array_sig(132) <= to_unsigned(1, 8);

        ELSIF (rising_edge(clk)) THEN
            if mem_write = '1' then
                -- O endereço (unsigned) precisa ser convertido para integer para indexar o array
                data_array_sig(to_integer(address_bus)) <= data_in;
            end if; 
        END IF;     
    end process;
    
    -- Lógica de leitura: saída padrão '0' durante o reset para evitar metavalores
    data_out <= (others => '0') when rst = '1' else data_array_sig(to_integer(address_bus));

END MEMO;