-- Arquivo: tb_top_ahmes_spi.vhd

-- ... (início do arquivo, constantes, etc.) ...
ARCHITECTURE simulation OF tb_top_ahmes_spi IS

    -- 1. Declaração do componente ATUALIZADA
    COMPONENT top_ahmes IS
        PORT (
            clk              : IN  STD_LOGIC;
            reset            : IN  STD_LOGIC;
            btns             : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            leds             : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            spi_sck          : IN  STD_LOGIC;
            spi_ss           : IN  STD_LOGIC;
            spi_mosi         : IN  STD_LOGIC;
            -- Novas portas
            debug_addr_in    : IN  unsigned(7 downto 0);
            debug_data_out   : OUT unsigned(7 downto 0)
        );
    END COMPONENT top_ahmes;

    -- 2. Sinais para conectar ao UUT
    -- ... (sinais existentes) ...
    SIGNAL s_debug_addr_in  : unsigned(7 downto 0) := (others => '0');
    SIGNAL s_debug_data_out : unsigned(7 downto 0);

    -- ... (constantes) ...
    
BEGIN
    -- 3. Instanciação do UUT ATUALIZADA
    UUT : top_ahmes
        PORT MAP (
            clk              => s_clk,
            reset            => s_reset,
            btns             => s_btns,
            leds             => s_leds,
            spi_sck          => s_spi_sck,
            spi_ss           => s_spi_ss,
            spi_mosi         => s_spi_mosi,
            -- Conexão das novas portas
            debug_addr_in    => s_debug_addr_in,
            debug_data_out   => s_debug_data_out
        );
    -- ... (geração de clock) ...

    stimuli : PROCESS
        -- ... (procedimento spi_send_byte) ...
    BEGIN
        -- ... (FASE 1, 2 e 3 são iguais) ...

        -- =================================================================
        -- FASE 4: VERIFICAÇÃO (MODIFICADA)
        -- =================================================================
        REPORT "Verificando o resultado na memoria usando a porta de debug...";
        
        -- Ativa o modo de leitura de depuração e coloca o endereço desejado (102) no barramento
        s_btns(1) <= '1';
        s_debug_addr_in <= to_unsigned(102, 8);
        
        -- A leitura da memória é combinacional, mas esperamos um pequeno delta time para garantir a propagação do sinal.
        WAIT FOR 1 ns; 

        -- Agora, o valor no endereço 102 está presente na porta s_debug_data_out
        ASSERT s_debug_data_out = RESULTADO_ESPERADO
            REPORT "ERRO: O resultado da soma na memoria nao confere! Esperado: " & 
                   integer'image(to_integer(RESULTADO_ESPERADO)) & 
                   ", Obtido: " & 
                   integer'image(to_integer(s_debug_data_out))
            SEVERITY FAILURE;

        REPORT "SUCESSO: O resultado da soma foi armazenado corretamente na memoria.";
        REPORT "Simulacao finalizada com sucesso.";
        
        -- Desativa o modo de debug
        s_btns(1) <= '0';
        
        WAIT;

    END PROCESS stimuli;

END ARCHITECTURE simulation;