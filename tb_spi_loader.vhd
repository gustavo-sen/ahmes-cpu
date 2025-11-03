library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_loader is
end entity tb_spi_loader;

architecture sim of tb_spi_loader is
    signal clk          : std_logic := '0';
    signal spi_sck      : std_logic := '0';
    signal spi_ss       : std_logic := '1';
    signal spi_mosi     : std_logic := '0';
    signal spi_enable   : std_logic := '1';
    signal spi_data_out : unsigned(7 downto 0);
    signal spi_addr_bus : unsigned(7 downto 0);
    signal spi_mem_write: std_logic;

    -- Sinal de teste
    signal test_byte    : unsigned(7 downto 0) := "10101010"; -- byte que queremos enviar
begin

    -- Instancia o DUT (Device Under Test)
    uut: entity work.spi_loader
        port map(
            clk => clk,
            spi_sck => spi_sck,
            spi_ss => spi_ss,
            spi_mosi => spi_mosi,
            spi_enable => spi_enable,
            spi_data_out => spi_data_out,
            spi_addr_bus => spi_addr_bus,
            spi_mem_write => spi_mem_write
        );

    -- Clock principal
    clk_proc: process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    -- SPI stimulus
    spi_proc: process
    begin
        -- Ativa SPI
        spi_ss <= '0';
        wait for 20 ns;

        -- Envia byte bit a bit (MSB first)
        for i in 7 downto 0 loop
            spi_mosi <= test_byte(i);
            spi_sck <= '0'; wait for 10 ns;
            spi_sck <= '1'; wait for 10 ns;
        end loop;

        -- Desativa SPI
        spi_ss <= '1';
        wait for 50 ns;

        -- Envia outro byte se quiser
        test_byte <= "11001100";
        spi_ss <= '0'; wait for 20 ns;
        for i in 7 downto 0 loop
            spi_mosi <= test_byte(i);
            spi_sck <= '0'; wait for 10 ns;
            spi_sck <= '1'; wait for 10 ns;
        end loop;
        spi_ss <= '1';
        
        wait;
    end process;

end architecture sim;
