LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria_led IS
    PORT (
        address_bus : IN  unsigned(7 downto 0);
        data_in     : IN  unsigned(7 downto 0);
        data_out    : OUT unsigned(7 downto 0);
        mem_write   : IN  std_logic;
        clk         : IN  std_logic;
        rst         : IN  std_logic
    );
END memoria_led;

ARCHITECTURE MEMO OF memoria_led IS
    -- Opcodes e Endereços Especiais
    constant STA      : unsigned(7 downto 0) := x"10";
    constant LDA      : unsigned(7 downto 0) := x"20";
    constant ADD      : unsigned(7 downto 0) := x"30";
    constant JMP      : unsigned(7 downto 0) := x"80";
    constant JZ       : unsigned(7 downto 0) := x"A0";
    constant HLT      : unsigned(7 downto 0) := x"F0";
    constant ADDR_BTN : unsigned(7 downto 0) := x"FE";
    -- =================================================================
    -- == CORREÇÃO 1: Adicionar a constante do endereço dos LEDs      ==
    -- =================================================================
    constant ADDR_LED : unsigned(7 downto 0) := x"F8"; -- Endereço especial dos LEDs (248)

    -- Tipo da memória
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    signal data_array_sig : data_array_type;

BEGIN
    process (rst, clk)
    begin
        IF (rst = '1') THEN
            -- O programa principal (endereços 0 a 15) permanece o mesmo
            data_array_sig(0) <= LDA;
            data_array_sig(1) <= ADDR_BTN;
            data_array_sig(2) <= ADD;
            data_array_sig(3) <= to_unsigned(132, 8);
            data_array_sig(4) <= JZ;
            data_array_sig(5) <= to_unsigned(12, 8);
            data_array_sig(6) <= LDA;
            data_array_sig(7) <= to_unsigned(129, 8);
            data_array_sig(8) <= ADD;
            data_array_sig(9) <= to_unsigned(133, 8);
            data_array_sig(10) <= JMP;
            data_array_sig(11) <= to_unsigned(16, 8);
            data_array_sig(12) <= LDA;
            data_array_sig(13) <= to_unsigned(130, 8);
            data_array_sig(14) <= ADD;
            data_array_sig(15) <= to_unsigned(131, 8);
            
            -- =================================================================
            -- == CORREÇÃO 2: Modificar o final do programa para ativar os LEDs ==
            -- =================================================================
            -- 6. Armazena o resultado (opcional, mas bom para depuração)
            data_array_sig(16) <= STA;
            data_array_sig(17) <= to_unsigned(128, 8);

            -- 7. Envia o mesmo resultado (que ainda está no acumulador) para os LEDs
            data_array_sig(18) <= STA;
            data_array_sig(19) <= ADDR_LED; -- Usa o endereço especial dos LEDs

            -- 8. Para o processador
            data_array_sig(20) <= HLT;
            
            -- Os dados (datasets) permanecem os mesmos
            data_array_sig(128) <= to_unsigned(0, 8);
            data_array_sig(129) <= to_unsigned(5, 8);
            data_array_sig(130) <= to_unsigned(10, 8);
            data_array_sig(131) <= to_unsigned(18, 8);
            data_array_sig(132) <= to_unsigned(0, 8);
            data_array_sig(133) <= to_unsigned(1, 8);

        ELSIF (rising_edge(clk)) THEN
            if mem_write = '1' then
                data_array_sig(to_integer(address_bus)) <= data_in;
            end if; 
        END IF;     
    end process;
    
    data_out <= (others => '0') when rst = '1' else data_array_sig(to_integer(address_bus));

END MEMO;