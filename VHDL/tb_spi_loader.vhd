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

    constant clk_period      : time := 10 ns;
    constant spi_clk_period  : time := 50 ns; 

    -- Vetor de bytes de teste
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant test_bytes : byte_array := (
        "10101010",
        "11001100",
        "11110000"
    );

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
        while now < 5 us loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    --------------------------------------------------------------------
    -- Processo de estímulo SPI com verificação
    --------------------------------------------------------------------
    stim_proc : process
    begin
        wait for 10 ns;
        spi_ss <= '0';  -- habilita slave

        -- Envia todos os bytes de teste
        for i in test_bytes'range loop
            for j in 7 downto 0 loop
                spi_mosi <= test_bytes(i)(j);
                spi_sck <= '0';
                wait for spi_clk_period / 2;
                spi_sck <= '1';
                wait for spi_clk_period / 2;
            end loop;

            -- Aguarda o pulso de escrita do DUT
            wait until rising_edge(clk);
            if spi_mem_write = '1' then
                assert spi_data_out = unsigned(test_bytes(i))
                    report "Erro: byte recebido incorreto!" severity error;
                assert spi_addr_bus = i
                    report "Erro: endereço incorreto!" severity error;
            end if;
        end loop;

        spi_ss <= '1';  -- desabilita slave
        wait for 10 ns;

        report "Simulação concluída com sucesso." severity note;
        wait;
    end process;

end architecture sim;
