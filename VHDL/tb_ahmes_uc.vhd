library ieee;
use ieee.std_logic_1164.all;

entity tb_ahmes_uc is
end tb_ahmes_uc;

architecture tb of tb_ahmes_uc is

    component ahmes_uc
        port (address_bus : out std_logic_vector (7 downto 0);
              data_in     : in std_logic_vector (7 downto 0);
              data_out    : out std_logic_vector (7 downto 0);
              mem_write   : out std_logic;
              clk         : in std_logic;
              reset       : in std_logic;
              ERROR       : out std_logic;
              btns        : in std_logic_vector (3 downto 0);
              leds        : out std_logic_vector (3 downto 0);
              OPERACAO    : out std_logic_vector (3 downto 0);
              OPER_A      : out std_logic_vector (7 downto 0);
              OPER_B      : out std_logic_vector (7 downto 0);
              RESULT      : in std_logic_vector (7 downto 0);
              Cout        : out std_logic;
              N           : in std_logic;
              Z           : in std_logic;
              C           : in std_logic;
              B           : in std_logic;
              V           : in std_logic);
    end component;

    signal address_bus : std_logic_vector (7 downto 0);
    signal data_in     : std_logic_vector (7 downto 0);
    signal data_out    : std_logic_vector (7 downto 0);
    signal mem_write   : std_logic;
    signal clk         : std_logic;
    signal reset       : std_logic;
    signal ERROR       : std_logic;
    signal btns        : std_logic_vector (3 downto 0);
    signal leds        : std_logic_vector (3 downto 0);
    signal OPERACAO    : std_logic_vector (3 downto 0);
    signal OPER_A      : std_logic_vector (7 downto 0);
    signal OPER_B      : std_logic_vector (7 downto 0);
    signal RESULT      : std_logic_vector (7 downto 0);
    signal Cout        : std_logic;
    signal N           : std_logic;
    signal Z           : std_logic;
    signal C           : std_logic;
    signal B           : std_logic;
    signal V           : std_logic;

    constant TbPeriod : time := 1000 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : ahmes_uc
    port map (address_bus => address_bus,
              data_in     => data_in,
              data_out    => data_out,
              mem_write   => mem_write,
              clk         => clk,
              reset       => reset,
              ERROR       => ERROR,
              btns        => btns,
              leds        => leds,
              OPERACAO    => OPERACAO,
              OPER_A      => OPER_A,
              OPER_B      => OPER_B,
              RESULT      => RESULT,
              Cout        => Cout,
              N           => N,
              Z           => Z,
              C           => C,
              B           => B,
              V           => V);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
        data_in <= (others => '0');
        btns <= (others => '0');
        RESULT <= (others => '0');
        N <= '0';
        Z <= '0';
        C <= '0';
        B <= '0';
        V <= '0';

        -- Reset generation
        -- ***EDIT*** Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- ***EDIT*** Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;