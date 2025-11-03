LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.all;

ENTITY top_ahmes IS
    PORT (
        clk         : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        btns        : IN  unsigned(3 DOWNTO 0);
        leds        : OUT unsigned(3 DOWNTO 0);
        ERROR       : OUT STD_LOGIC;
        Cout        : OUT STD_LOGIC;
        spi_sck     : IN  STD_LOGIC;
        spi_ss      : IN  STD_LOGIC;
        spi_mosi    : IN  STD_LOGIC
    );
END ENTITY top_ahmes;

ARCHITECTURE structural OF top_ahmes IS

    signal s_address_bus, uc_address_bus : unsigned(7 DOWNTO 0);
    signal s_data_to_mem, uc_data_to_mem : unsigned(7 DOWNTO 0);
    signal s_data_from_mem               : unsigned(7 DOWNTO 0);
    signal s_mem_write, uc_mem_write     : std_logic;

    signal s_operacao    : unsigned(3 DOWNTO 0);
    signal s_oper_a      : unsigned(7 DOWNTO 0);
    signal s_oper_b      : unsigned(7 DOWNTO 0);
    signal s_alu_result  : std_logic_vector(7 DOWNTO 0);
    signal s_cin         : std_logic;
    signal s_n, s_z, s_c, s_b, s_v : std_logic;

    signal spi_loader_data_out   : unsigned(7 DOWNTO 0);
    signal spi_loader_addr_bus   : unsigned(7 DOWNTO 0);
    signal spi_loader_mem_write  : std_logic;

    signal switch_enable : std_logic;

BEGIN

    uc_inst : entity work.ahmes_uc
        PORT MAP(
            address_bus => uc_address_bus,
            data_in     => s_data_from_mem,
            data_out    => uc_data_to_mem,
            mem_write   => uc_mem_write,
            clk         => clk,
            reset       => reset,
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

    alu_inst : entity work.ALU
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

    mem_inst : entity work.memoria
        PORT MAP(
            address_bus => s_address_bus,
            data_in     => s_data_to_mem,
            data_out    => s_data_from_mem,
            mem_write   => s_mem_write,
            clk         => clk
        );

    spi_loader_inst : entity work.spi_loader
        PORT MAP (
            clk           => clk,
            spi_sck       => spi_sck, 
            spi_ss        => spi_ss,   
            spi_mosi      => spi_mosi,
            spi_enable    => switch_enable,
            spi_data_out  => spi_loader_data_out,
            spi_addr_bus  => spi_loader_addr_bus,
            spi_mem_write => spi_loader_mem_write
        );


    switch_enable <= btns(0);

    s_mem_write   <=   spi_loader_mem_write when switch_enable = '1' else uc_mem_write;
    s_address_bus <=   spi_loader_addr_bus when switch_enable = '1' else uc_address_bus;
    s_data_to_mem <= spi_loader_data_out when switch_enable = '1' else uc_data_to_mem;

    Cout <= s_cin;

END ARCHITECTURE structural;
