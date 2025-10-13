LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY top_ahmes IS
    PORT (
        clk       : IN  STD_LOGIC;
        reset     : IN  STD_LOGIC; -- Reset geral do sistema
        btns      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        leds      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- Adicionar portas para a interface SPI
        spi_sck   : IN  STD_LOGIC;
        spi_ss    : IN  STD_LOGIC;
        spi_mosi  : IN  STD_LOGIC
    );
END ENTITY top_ahmes;

ARCHITECTURE structural OF top_ahmes IS

    -- Componente da Unidade de Controle
    COMPONENT ahmes_uc IS
        PORT (
            address_bus : OUT unsigned(7 DOWNTO 0);
            data_in     : IN  unsigned(7 DOWNTO 0);
            data_out    : OUT unsigned(7 DOWNTO 0);
            mem_write   : OUT std_logic;
            clk         : IN  std_logic;
            reset       : IN  std_logic;
            ERROR       : OUT STD_LOGIC;
            Cout        : OUT STD_LOGIC;
            btns        : IN  unsigned(3 DOWNTO 0);
            leds        : OUT unsigned(3 DOWNTO 0);
            OPERACAO    : OUT unsigned(3 DOWNTO 0);
            OPER_A      : OUT unsigned(7 DOWNTO 0);
            OPER_B      : OUT unsigned(7 DOWNTO 0);
            RESULT      : IN  unsigned(7 DOWNTO 0);
            N, Z, C, B, V : IN STD_LOGIC
        );
    END COMPONENT ahmes_uc;

    -- Componente da Memória
    COMPONENT memoria IS
        PORT (
            address_bus : IN  unsigned(7 downto 0);
            data_in     : IN  unsigned(7 downto 0);
            data_out    : OUT unsigned(7 downto 0);
            mem_write   : IN  std_logic;
            clk         : IN  std_logic;
            rst         : IN  std_logic
        );
    END COMPONENT memoria;

    -- Componente da ULA
    COMPONENT ALU IS
        PORT (
            operacao : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            operA    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            operB    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            Result   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            Cin      : IN  STD_LOGIC;
            N, Z, C, B, V : OUT STD_LOGIC
        );
    END COMPONENT ALU;

    -- Componente do Carregador SPI
    COMPONENT spi_loader IS
        PORT (
            clk           : IN  STD_LOGIC;
            spi_sck       : IN  STD_LOGIC;
            spi_ss        : IN  STD_LOGIC;
            spi_mosi      : IN  STD_LOGIC;
            spi_addr_bus  : OUT unsigned(7 downto 0);
            spi_data_out  : OUT unsigned(7 downto 0);
            spi_mem_write : OUT STD_LOGIC
        );
    END COMPONENT spi_loader;

    -- Sinais de Interconexão
    SIGNAL s_uc_address_bus  : unsigned(7 DOWNTO 0);
    SIGNAL s_uc_data_out     : unsigned(7 DOWNTO 0);
    SIGNAL s_uc_mem_write    : std_logic;
    SIGNAL s_spi_address_bus : unsigned(7 DOWNTO 0);
    SIGNAL s_spi_data_out    : unsigned(7 DOWNTO 0);
    SIGNAL s_spi_mem_write   : std_logic;
    SIGNAL s_mem_address_bus : unsigned(7 DOWNTO 0);
    SIGNAL s_mem_data_in     : unsigned(7 DOWNTO 0);
    SIGNAL s_mem_write       : std_logic;
    SIGNAL s_data_to_uc      : unsigned(7 DOWNTO 0);
    SIGNAL s_operacao        : unsigned(3 DOWNTO 0);
    SIGNAL s_oper_a          : unsigned(7 DOWNTO 0);
    SIGNAL s_oper_b          : unsigned(7 DOWNTO 0);
    SIGNAL s_result_alu      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_n, s_z, s_c, s_b, s_v : std_logic;
    SIGNAL s_leds            : unsigned(3 DOWNTO 0);

    -- Sinal de reset interno para a CPU e Memória
    -- Ativo se o reset geral estiver ativo OU se o botão de programação (btns(0)) estiver pressionado.
    SIGNAL s_internal_reset  : std_logic;

BEGIN

    -- Lógica para o reset interno
    s_internal_reset <= reset OR btns(0);

    -- Lógica de Multiplexação para acesso à memória
    -- O spi_loader controla os barramentos se o botão de programação (btns(0))
    -- estiver pressionado E o slave select (spi_ss) estiver ativo ('0').
    s_mem_address_bus <= s_spi_address_bus WHEN (spi_ss = '0' AND btns(0) = '1') ELSE s_uc_address_bus;
    s_mem_data_in     <= s_spi_data_out    WHEN (spi_ss = '0' AND btns(0) = '1') ELSE s_uc_data_out;
    s_mem_write       <= s_spi_mem_write   WHEN (spi_ss = '0' AND btns(0) = '1') ELSE s_uc_mem_write;

    -- Instanciação da Unidade de Controle
    uc_inst : ahmes_uc
        PORT MAP (
            address_bus => s_uc_address_bus,
            data_in     => s_data_to_uc,
            data_out    => s_uc_data_out,
            mem_write   => s_uc_mem_write,
            clk         => clk,
            reset       => s_internal_reset, -- Usa o reset interno
            ERROR       => OPEN,
            Cout        => OPEN,
            btns        => unsigned(btns),
            leds        => s_leds,
            OPERACAO    => s_operacao,
            OPER_A      => s_oper_a,
            OPER_B      => s_oper_b,
            RESULT      => unsigned(s_result_alu),
            N           => s_n,
            Z           => s_z,
            C           => s_c,
            B           => s_b,
            V           => s_v
        );

    -- Instanciação da Memória
    mem_inst : memoria
        PORT MAP (
            address_bus => s_mem_address_bus,
            data_in     => s_mem_data_in,
            data_out    => s_data_to_uc,
            mem_write   => s_mem_write,
            clk         => clk,
            rst         => s_internal_reset -- Usa o reset interno
        );

    -- Instanciação da ULA
    alu_inst : ALU
        PORT MAP (
            operacao => std_logic_vector(s_operacao),
            operA    => std_logic_vector(s_oper_a),
            operB    => std_logic_vector(s_oper_b),
            Result   => s_result_alu,
            Cin      => '0',
            N        => s_n,
            Z        => s_z,
            C        => s_c,
            B        => s_b,
            V        => s_v
        );

    -- Instanciação do SPI Loader
    spi_inst : spi_loader
        PORT MAP (
            clk           => clk,
            spi_sck       => spi_sck,
            spi_ss        => spi_ss,
            spi_mosi      => spi_mosi,
            spi_addr_bus  => s_spi_address_bus,
            spi_data_out  => s_spi_data_out,
            spi_mem_write => s_spi_mem_write
        );

    -- Conexão da saída de LEDs
    leds <= std_logic_vector(s_leds);

END ARCHITECTURE structural;