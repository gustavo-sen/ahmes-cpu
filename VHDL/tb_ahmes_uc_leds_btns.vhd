library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ahmes_uc is
end tb_ahmes_uc;

architecture tb of tb_ahmes_uc is

    -- (As declarações dos componentes permanecem as mesmas)
    component ahmes_uc port ( address_bus : out unsigned(7 downto 0); data_in : in unsigned(7 downto 0); data_out : out unsigned(7 downto 0); mem_write : out std_logic; clk : in std_logic; reset : in std_logic; ERROR : out std_logic; btns : in unsigned(3 downto 0); leds : out unsigned(3 downto 0); OPERACAO : out unsigned(3 downto 0); OPER_A : out unsigned(7 downto 0); OPER_B : out unsigned(7 downto 0); RESULT : in unsigned(7 downto 0); Cout : out std_logic; N, Z, C, B, V : in std_logic ); end component;
    component memoria port ( address_bus : in unsigned(7 downto 0); data_in : in unsigned(7 downto 0); data_out : out unsigned(7 downto 0); mem_write : in std_logic; clk : in std_logic; rst : in std_logic ); end component;
    component memoria_led port ( address_bus : in unsigned(7 downto 0); data_in : in unsigned(7 downto 0); data_out : out unsigned(7 downto 0); mem_write : in std_logic; clk : in std_logic; rst : in std_logic ); end component;
    component ALU port ( operacao : in std_logic_vector(3 downto 0); operA : in std_logic_vector(7 downto 0); operB : in std_logic_vector(7 downto 0); Result : out std_logic_vector(7 downto 0); Cin : in std_logic; N, Z, C, B, V : out std_logic ); end component;


    -- Sinais para conectar os componentes
    signal s_address_bus   : unsigned (7 downto 0);
    signal s_data_uc_mem   : unsigned (7 downto 0);
    signal s_data_mem_uc   : unsigned (7 downto 0);
    signal s_mem_write     : std_logic;
    signal s_clk           : std_logic := '0';
    signal s_reset         : std_logic;
    signal s_error         : std_logic;
    signal s_btns          : unsigned (3 downto 0) := (others => '0');
    signal s_leds          : unsigned (3 downto 0);
    signal s_operacao      : unsigned (3 downto 0);
    signal s_oper_a        : unsigned (7 downto 0);
    signal s_oper_b        : unsigned (7 downto 0);
    signal s_result        : unsigned (7 downto 0);
    signal s_cout, s_n, s_z, s_c, s_b, s_v : std_logic;
    
    -- =========================================================
    -- == ALTERAÇÃO 1: Sinal intermediário para a saída da ALU ==
    -- =========================================================
    signal s_alu_result_slv : std_logic_vector(7 downto 0);

    -- Constantes do clock
    constant CLK_PERIOD : time := 100 ns;

begin

    UUT : ahmes_uc port map ( address_bus => s_address_bus, data_in => s_data_mem_uc, data_out => s_data_uc_mem, mem_write => s_mem_write, clk => s_clk, reset => s_reset, ERROR => s_error, btns => s_btns, leds => s_leds, OPERACAO => s_operacao, OPER_A => s_oper_a, OPER_B => s_oper_b, RESULT => s_result, Cout => s_cout, N => s_n, Z => s_z, C => s_c, B => s_b, V => s_v );

    -- Instanciação da Memória
    MEM : memoria port map ( address_bus => s_address_bus, data_in => s_data_uc_mem, data_out => s_data_mem_uc, mem_write => s_mem_write, clk => s_clk, rst => s_reset );
    --MEM : memoria_led port map ( address_bus => s_address_bus, data_in => s_data_uc_mem, data_out => s_data_mem_uc, mem_write => s_mem_write, clk => s_clk, rst => s_reset );

    -- Instanciação da ALU
    ULA : ALU
        port map (
            operacao => std_logic_vector(s_operacao),
            operA    => std_logic_vector(s_oper_a),
            operB    => std_logic_vector(s_oper_b),
            -- ==============================================================
            -- == ALTERAÇÃO 2: Conecta a saída Result ao novo sinal        ==
            -- ==============================================================
            Result   => s_alu_result_slv,
            Cin      => '0',
            N        => s_n, Z           => s_z,
            C        => s_c, B           => s_b,
            V        => s_v
        );
        
    
    s_result <= unsigned(s_alu_result_slv);

    -- Geração do Clock
    s_clk <= not s_clk after CLK_PERIOD / 2;

    -- Geração de estímulos
    stimuli : process
    begin
        -- 1. Inicia o sistema em reset
        s_reset <= '1';
        s_btns  <= "0000"; -- Botões em estado inicial (nenhum pressionado)
        wait for CLK_PERIOD * 2;
        
        -- 2. Libera o reset para o programa começar a rodar
        s_reset <= '0';
        report "Reset liberado. Programa em execucao.";
        wait for CLK_PERIOD * 20; -- Espera um tempo para o loop estabilizar

        -- 3. Simula o pressionamento do botão 0
        report "Simulando BTN0 pressionado.";
        s_btns <= "0001";
        wait for CLK_PERIOD * 20; -- Espera o processador ler e atualizar os LEDs

        -- 4. Simula o pressionamento dos botões 1 e 3
        report "Simulando BTN1 e BTN3 pressionados.";
        s_btns <= "1010"; -- Valor 10 em decimal
        wait for CLK_PERIOD * 20;

        -- 5. Simula o pressionamento de todos os botões
        report "Simulando todos os botoes pressionados.";
        s_btns <= "1111";
        wait for CLK_PERIOD * 20;
        
        -- 6. Simula a liberação de todos os botões
        report "Simulando todos os botoes liberados.";
        s_btns <= "0000";
        wait for CLK_PERIOD * 20;

        -- 7. Finaliza a simulação
        report "Simulacao finalizada com sucesso." severity failure;
        wait;
    end process;



end tb;