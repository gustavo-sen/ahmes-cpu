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
    -- As constantes de instrução são úteis para referência, mas não são estritamente necessárias aqui
    -- já que a UC irá decodificá-las.
    constant STA      : unsigned(7 downto 0) := x"10";
    constant LDA      : unsigned(7 downto 0) := x"20";
    constant JMP      : unsigned(7 downto 0) := x"80";
    constant HLT      : unsigned(7 downto 0) := x"F0";
    
    -- Tipo da memória agora armazena vetores unsigned
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    signal data_array_sig : data_array_type;

BEGIN
    process (rst, clk)
    begin
        IF (rst = '1') THEN
            -- Inicializa a memória com o novo programa durante o reset
            -- O programa lê os botões e os espelha nos LEDs em um loop infinito.
            
            -- Limpa toda a memória primeiro (boa prática)
            data_array_sig <= (others => (others => '0'));
            
            -- Programa principal
            data_array_sig(0) <= LDA;                       -- Carrega o valor do endereço especificado no acumulador
            data_array_sig(1) <= to_unsigned(254, 8);       -- Endereço dos botões (ADDR_BTN)
            data_array_sig(2) <= STA;                       -- Armazena o valor do acumulador no endereço especificado
            data_array_sig(3) <= to_unsigned(248, 8);       -- Endereço dos LEDs (ADDR_LED)
            data_array_sig(4) <= JMP;                       -- Salta para um endereço
            data_array_sig(5) <= to_unsigned(0, 8);         -- Endereço de destino do salto (início do programa)
            data_array_sig(6) <= HLT;                       -- Para o processador (não será alcançado devido ao loop)
            
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