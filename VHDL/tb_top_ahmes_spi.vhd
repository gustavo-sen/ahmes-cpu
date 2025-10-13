LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_top_ahmes_spi IS
END ENTITY tb_top_ahmes_spi;

ARCHITECTURE test OF tb_top_ahmes_spi IS

    -- Constantes para a simulação
    CONSTANT CLK_PERIOD      : time := 10 ns;
    CONSTANT SPI_CLK_PERIOD  : time := 40 ns;

    -- Componente a ser testado
    COMPONENT top_ahmes IS
        PORT (
            clk       : IN  STD_LOGIC;
            reset     : IN  STD_LOGIC;
            btns      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            leds      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            spi_sck   : IN  STD_LOGIC;
            spi_ss    : IN  STD_LOGIC;
            spi_mosi  : IN  STD_LOGIC
        );
    END COMPONENT top_ahmes;

    -- Sinais de conexão
    SIGNAL s_clk      : STD_LOGIC := '0';
    SIGNAL s_reset    : STD_LOGIC := '1';
    SIGNAL s_btns     : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_leds     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_spi_sck  : STD_LOGIC := '0';
    SIGNAL s_spi_ss   : STD_LOGIC := '1';
    SIGNAL s_spi_mosi : STD_LOGIC := '0';

    -- O array precisa ter tamanho para ir do endereço 0 até o 101.
    TYPE program_memory_t IS ARRAY (0 TO 101) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Programa para somar 6 + 4
    CONSTANT PROGRAM_DATA : program_memory_t := (
        0   => x"20",          -- LDA
        1   => x"64",          -- operando 100
        2   => x"30",          -- ADD
        3   => x"65",          -- operando 101
        4   => x"10",          -- STA
        5   => x"66",          -- operando 102
        6   => x"F0",          -- HLT
        100 => x"06",          -- Dado 6
        101 => x"04",          -- Dado 4
        OTHERS => x"00"     -- Preenche todo o resto com NOP (0x00)
    );

BEGIN
    -- Instanciação do DUT (Device Under Test)
    dut_inst : top_ahmes PORT MAP (
        clk      => s_clk,
        reset    => s_reset,
        btns     => s_btns,
        leds     => s_leds,
        spi_sck  => s_spi_sck,
        spi_ss   => s_spi_ss,
        spi_mosi => s_spi_mosi
    );

    -- Geração de Clock
    clk_process : PROCESS
    BEGIN
        LOOP
            s_clk <= '0'; WAIT FOR CLK_PERIOD / 2;
            s_clk <= '1'; WAIT FOR CLK_PERIOD / 2;
        END LOOP;
    END PROCESS;

    -- Processo de Estímulo
    stimulus_process : PROCESS
        PROCEDURE spi_write_byte(CONSTANT data : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) IS
        BEGIN
            FOR i IN 7 DOWNTO 0 LOOP
                s_spi_mosi <= data(i); WAIT FOR SPI_CLK_PERIOD / 2;
                s_spi_sck <= '1';      WAIT FOR SPI_CLK_PERIOD / 2;
                s_spi_sck <= '0';
            END LOOP;
        END PROCEDURE;
    BEGIN
        -- === FASE 1: INICIALIZAÇÃO ===
        REPORT "INICIANDO TESTBENCH...";
        s_reset <= '1';     -- Ativa o reset geral
        s_btns  <= "0000"; -- Garante que o botão de programação está solto
        WAIT FOR CLK_PERIOD * 5;
        s_reset <= '0';     -- Libera o reset geral do sistema
        WAIT FOR CLK_PERIOD * 5;

        -- === FASE 2: ENTRAR EM MODO DE PROGRAMAÇÃO E CARREGAR VIA SPI ===
        REPORT "ENTRANDO EM MODO DE PROGRAMACAO (BTN0 pressionado)...";
        s_btns <= "0001";   -- Pressiona o botão para habilitar a gravação
        WAIT FOR CLK_PERIOD * 5; -- Espera para garantir que o reset interno se estabilize

        REPORT "INICIANDO CARGA DO PROGRAMA VIA SPI...";
        s_spi_ss <= '0'; -- Ativa o slave select para iniciar a comunicação
        WAIT FOR CLK_PERIOD;

        -- Envia cada byte do programa, dos NOPs de preenchimento e dos dados
        FOR i IN PROGRAM_DATA'range LOOP
            spi_write_byte(PROGRAM_DATA(i));
        END LOOP;

        WAIT FOR CLK_PERIOD;
        s_spi_ss <= '1'; -- Desativa o slave select
        s_spi_mosi <= '0';
        REPORT "CARGA DO PROGRAMA FINALIZADA.";
        
        -- === FASE 3: SAIR DO MODO DE PROGRAMAÇÃO E EXECUTAR ===
        REPORT "SAINDO DO MODO DE PROGRAMACAO (BTN0 solto)...";
        s_btns <= "0000"; -- Solta o botão, liberando a CPU do reset
        WAIT FOR CLK_PERIOD * 5;

        REPORT "CPU liberada. PROCESSADOR INICIANDO EXECUCAO.";
        
        -- === FASE 4: OBSERVAÇÃO E TÉRMINO ===
        REPORT "SIMULACAO EM ANDAMENTO. OBSERVE AS FORMAS DE ONDA.";
        WAIT FOR 2000 * CLK_PERIOD; -- Aguarda tempo suficiente para a execução
        
        REPORT "FIM DO TEMPO DE SIMULACAO. VERIFIQUE OS RESULTADOS.";
        ASSERT false REPORT "Fim da Simulação" SEVERITY failure;
    END PROCESS;

END ARCHITECTURE;