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

    -- Define um tipo de dado para a RAM de 256 bytes
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    -- Sinal interno que representa a memória
    SIGNAL data_array_sig : data_array_type;

BEGIN

    -- Processo de escrita e reset SÍNCRONO
    process (clk)
    begin
        -- Toda a lógica de escrita e reset ocorre na borda de subida do clock
        IF (rising_edge(clk)) THEN
            -- A lógica de reset está DENTRO da verificação de clock.
            -- A memória só é zerada no ciclo de clock em que o reset é ativado.
            IF (rst = '1') THEN
                data_array_sig <= (others => (others => '0'));
            ELSE
                -- A lógica de escrita só é avaliada quando não há reset ativo neste ciclo de clock.
                -- No entanto, como o reset é síncrono, em ciclos subsequentes
                -- a escrita será permitida, resolvendo o conflito com o SPI loader.
                IF mem_write = '1' THEN
                    data_array_sig(to_integer(address_bus)) <= data_in;
                END IF;
            END IF;
        END IF;
    end process;

    -- Processo de leitura COMBINACIONAL
    -- A saída de dados (data_out) reflete imediatamente o conteúdo
    -- do endereço apontado pelo address_bus.
    data_out <= data_array_sig(to_integer(address_bus));

END MEMO;