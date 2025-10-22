LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- =============================================================================
-- == ENTIDADE DE TOPO                                                        ==
-- =============================================================================
ENTITY top_entity IS
    PORT (
        clk          : IN  STD_LOGIC;
        reset        : IN  STD_LOGIC;
        btns         : IN  unsigned(3 DOWNTO 0); -- btns(0) será usado para habilitar/desabilitar gravação
        leds         : OUT unsigned(3 DOWNTO 0);
        ERROR        : OUT STD_LOGIC;
        -- Entradas SPI
        spi_sck      : IN  STD_LOGIC;
        spi_ss       : IN  STD_LOGIC;
        spi_mosi     : IN  STD_LOGIC
    );
END ENTITY top_entity;

ARCHITECTURE structural OF top_entity IS

    -- =========================================================================
    -- == DECLARAÇÃO DOS COMPONENTES                                          ==
    -- =========================================================================

    -- Componente da Unidade de Controle (Processador)
    COMPONENT ahmes_uc IS
        PORT (
            address_bus : OUT unsigned(7 DOWNTO 0);
            data_in     : IN  unsigned(7 DOWNTO 0);
            data_out    : OUT unsigned(7 DOWNTO 0);
            mem_write   : OUT std_logic;
            clk         : IN  std_logic;
            reset       : IN  std_logic;
            ERROR       : OUT STD_LOGIC;
            btns        : IN  unsigned(3 DOWNTO 0);
            leds        : OUT unsigned(3 DOWNTO 0);
            OPERACAO    : OUT unsigned(3 DOWNTO 0);
            OPER_A      : OUT unsigned(7 DOWNTO 0);
            OPER_B      : OUT unsigned(7 DOWNTO 0);
            RESULT      : IN  unsigned(7 DOWNTO 0);
            Cout        : OUT STD_LOGIC;
            N, Z, C, B, V : IN STD_LOGIC
        );
    END COMPONENT ahmes_uc;

    -- Componente da Unidade Lógica e Aritmética
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

    -- Instancia do SPI Loader
    COMPONENT spi_loader IS
        PORT (
            clk            : IN  STD_LOGIC;
            spi_sck        : IN  STD_LOGIC;
            spi_ss         : IN  STD_LOGIC;
            spi_mosi       : IN  STD_LOGIC;
            spi_addr_bus   : OUT unsigned(7 downto 0);
            spi_data_out   : OUT unsigned(7 downto 0);
            spi_mem_write  : OUT STD_LOGIC
        );
    END COMPONENT spi_loader;

    -- =========================================================================
    -- == SINAIS DE INTERLIGAÇÃO                                              ==
    -- =========================================================================

    -- Sinais de comunicação entre UC e Memória
    signal s_address_bus : unsigned(7 DOWNTO 0);
    signal s_data_to_mem : unsigned(7 DOWNTO 0); -- Saída de dados da UC para a Memória
    signal s_data_from_mem : unsigned(7 DOWNTO 0); -- Saída de dados da Memória para a UC
    signal s_mem_write, alu_mem_write   : std_logic;

    -- Sinais de comunicação entre UC e ALU
    signal s_operacao    : unsigned(3 DOWNTO 0);
    signal s_oper_a      : unsigned(7 DOWNTO 0);
    signal s_oper_b      : unsigned(7 DOWNTO 0);
    signal s_alu_result  : std_logic_vector(7 DOWNTO 0);
    signal s_cin         : std_logic; -- Conecta Cout da UC com Cin da ALU
    signal s_n, s_z, s_c, s_b, s_v : std_logic; -- Flags da ALU para a UC

    -- Sinais de SPI Loader
    signal spi_loader_addr_bus : unsigned(7 DOWNTO 0);
    signal spi_loader_data_out : unsigned(7 DOWNTO 0);
    signal spi_loader_mem_write : std_logic;

    -- Sinal do botão (switch) para controle de gravação
    signal switch_enable, s_resdet : std_logic;

BEGIN
    -- =========================================================================
    -- == INSTANCIAÇÃO DOS COMPONENTES                                        ==
    -- =========================================================================

    -- Instancia a Unidade de Controle (UC)
    uc_inst : ahmes_uc
        PORT MAP(
            address_bus => s_address_bus,
            data_in     => s_data_from_mem,
            data_out    => s_data_to_mem,
            mem_write   => alu_mem_write,
            clk         => clk,
            reset       => s_resdet,
            btns        => btns,
            leds        => leds,
            ERROR       => ERROR,
            OPERACAO    => s_operacao,
            OPER_A      => s_oper_a,
            OPER_B      => s_oper_b,
            RESULT      => unsigned(s_alu_result),
            Cout        => s_cin,
            N           => s_n,
            Z           => s_z,
            C           => s_c,
            B           => s_b,
            V           => s_v
        );

    -- Instancia a Unidade Lógica e Aritmética (ALU)
    alu_inst : ALU
        PORT MAP(
            operacao => std_logic_vector(s_operacao),
            operA    => std_logic_vector(s_oper_a),
            operB    => std_logic_vector(s_oper_b),
            Result   => s_alu_result,
            Cin      => s_cin,
            N        => s_n,
            Z        => s_z,
            C        => s_c,
            B        => s_b,
            V        => s_v
        );

    -- Instancia a Memória
    mem_inst : memoria
        PORT MAP(
            address_bus => s_address_bus,
            data_in     => s_data_to_mem,
            data_out    => s_data_from_mem,
            mem_write   => s_mem_write,
            clk         => clk,
            rst         => reset
        );

    -- Instancia o SPI Loader
    spi_loader_inst : spi_loader
        PORT MAP (
            clk            => clk,
            spi_sck        => spi_sck,  -- Conexão direta para SCK SPI
            spi_ss         => spi_ss,   -- Conexão direta para SS SPI
            spi_mosi       => spi_mosi, -- Conexão direta para MOSI SPI
            spi_addr_bus   => spi_loader_addr_bus,
            spi_data_out   => spi_loader_data_out,
            spi_mem_write  => spi_loader_mem_write
        );

    -- =========================================================================
    -- == LÓGICA DE CONTROLE DO BOTÃO PARA GRAVAÇÃO                          ==
    -- =========================================================================
    switch_enable <= btns(0);  
	s_resdet <=switch_enable;
	
    -- =========================================================================
    -- == LÓGICA DE CONTROLE DA GRAVAÇÃO NA MEMÓRIA                          ==
    -- =========================================================================
    -- Gravação na memória é habilitada se o switch estiver ativado e o
    -- SPI Loader tiver sinal de mem_write ativo.
	
    s_mem_write <= alu_mem_write  when switch_enable = '0' else spi_loader_mem_write;

END ARCHITECTURE structural;
