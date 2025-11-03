library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_loader is
end tb_spi_loader;

architecture sim of tb_spi_loader is
    -- Sinais de teste
    signal clk          : std_logic := '0';
    signal spi_sck      : std_logic := '0';
    signal spi_ss       : std_logic := '1';
    signal spi_mosi     : std_logic := '0';
    signal spi_enable   : std_logic := '1';
    signal spi_data_out : unsigned(7 downto 0);
    signal spi_addr_bus : unsigned(7 downto 0);
    signal spi_mem_write: std_logic;

    constant clk_period : time := 10 ns;
    constant spi_clk_period : time := 200 ns;  -- SPI ~5 MHz
begin

    --------------------------------------------------------------------
    -- DUT (Device Under Test)
    --------------------------------------------------------------------
    uut: entity work.spi_loader
        port map (
            clk          => clk,
            spi_sck      => spi_sck,
            spi_ss       => spi_ss,
            spi_mosi     => spi_mosi,
            spi_enable   => spi_enable,
            spi_data_out => spi_data_out,
            spi_addr_bus => spi_addr_bus,
            spi_mem_write=> spi_mem_write
        );

    --------------------------------------------------------------------
    -- Clock principal do sistema
    --------------------------------------------------------------------
    clk_process : process
    begin
        while now < 3 us loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    --------------------------------------------------------------------
    -- Processo de estímulo SPI
    --------------------------------------------------------------------
    stim_proc : process
        -- Dois bytes de dados a transmitir
        constant packet : std_logic_vector(15 downto 0) := "1010101011110000";
    begin
        wait for 100 ns;
        spi_ss <= '0';  -- habilita o slave

        -- Envia 16 bits (2 bytes)
        for i in 15 downto 0 loop
            spi_mosi <= packet(i);
            spi_sck <= '0';
            wait for spi_clk_period / 2;
            spi_sck <= '1';
            wait for spi_clk_period / 2;
        end loop;

        spi_sck <= '0';
        spi_ss  <= '1';  -- desabilita slave

        wait for 1 us;

        report "Simulação concluída com sucesso." severity note;
        wait;
    end process;

end architecture sim;
