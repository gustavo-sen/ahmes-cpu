LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY top_ahmes IS
    PORT (
        clk   : IN  STD_LOGIC;
        reset : IN  STD_LOGIC;
        btns  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        leds  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY top_ahmes;

ARCHITECTURE structural OF top_ahmes IS

    -- Component Declaration for the Control Unit (ahmes_uc)
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
            N, Z, C, B, V : IN STD_LOGIC
        );
    END COMPONENT ahmes_uc;

    -- Component Declaration for Memory (memoria)
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

    -- Component Declaration for the ALU
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

    -- Interconnection Signals
    SIGNAL s_address_bus : unsigned(7 DOWNTO 0);
    SIGNAL s_data_to_uc  : unsigned(7 DOWNTO 0);
    SIGNAL s_data_from_uc: unsigned(7 DOWNTO 0);
    SIGNAL s_mem_write   : std_logic;
    SIGNAL s_operacao    : unsigned(3 DOWNTO 0);
    SIGNAL s_oper_a      : unsigned(7 DOWNTO 0);
    SIGNAL s_oper_b      : unsigned(7 DOWNTO 0);
    SIGNAL s_result_alu  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_n, s_z, s_c, s_b, s_v : std_logic;
    SIGNAL s_leds        : unsigned(3 DOWNTO 0);

BEGIN

    -- Instantiation of the Control Unit
    uc_inst : ahmes_uc
        PORT MAP (
            address_bus => s_address_bus,
            data_in     => s_data_to_uc,
            data_out    => s_data_from_uc,
            mem_write   => s_mem_write,
            clk         => clk,
            reset       => reset,
            ERROR       => OPEN, -- Not connected externally
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

    -- Instantiation of the Memory
    mem_inst : memoria
        PORT MAP (
            address_bus => s_address_bus,
            data_in     => s_data_from_uc,
            data_out    => s_data_to_uc,
            mem_write   => s_mem_write,
            clk         => clk,
            rst         => reset
        );

    -- Instantiation of the ALU
    alu_inst : ALU
        PORT MAP (
            operacao => std_logic_vector(s_operacao),
            operA    => std_logic_vector(s_oper_a),
            operB    => std_logic_vector(s_oper_b),
            Result   => s_result_alu,
            Cin      => '0', -- Cin not used, connected to '0'
            N        => s_n,
            Z        => s_z,
            C        => s_c,
            B        => s_b,
            V        => s_v
        );

    -- Connect internal leds signal to the top-level output port
    leds <= std_logic_vector(s_leds);

END ARCHITECTURE structural;