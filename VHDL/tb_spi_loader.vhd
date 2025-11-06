library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_loader is
end tb_spi_loader;

architecture sim of tb_spi_loader is
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal spi_sck      : std_logic := '0';
    signal spi_ss       : std_logic := '1';
    signal spi_mosi     : std_logic := '0';
    signal spi_enable   : std_logic := '0';
    signal spi_data_out : unsigned(7 downto 0);
    signal spi_addr_bus : unsigned(7 downto 0);
    signal spi_mem_write: std_logic := '0';

    constant clk_period      : time := 10 ns;
    constant spi_clk_period  : time := 50 ns; 

    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant test_bytes : byte_array := (
        x"AA",
        x"CC",
        x"F0",
        x"C0",
        x"3C",
        x"0F",
        x"55",
        x"FF"
    );

begin
    uut: entity work.spi_loader
        port map (
            clk           => clk,
            reset         => reset,
            spi_sck       => spi_sck,
            spi_ss        => spi_ss,
            spi_mosi      => spi_mosi,
            spi_enable    => spi_enable,
            spi_data_out  => spi_data_out,
            spi_addr_bus  => spi_addr_bus,
            spi_mem_write => spi_mem_write
        );

    clk_process : process
    begin
        loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    stim_proc : process
    begin
        spi_ss     <= '1';
        spi_enable <= '0';
        reset      <= '1';
        wait for 20 ns;
        reset      <= '0';
        wait for 20 ns;
        spi_enable <= '1';

        for i in test_bytes'range loop
            spi_ss <= not spi_ss;
            wait for 10 ns;

            for j in 7 downto 0 loop
                spi_mosi <= test_bytes(i)(j);
                spi_sck  <= '0';
                wait for spi_clk_period / 2;
                spi_sck  <= '1';
                wait for spi_clk_period / 2;
            end loop;

            spi_ss <= not spi_ss;
            wait for 10 ns;

            assert spi_data_out = unsigned(test_bytes(i))
                report "Erro: byte recebido incorreto no índice " & integer'image(i)
                severity error;

            assert spi_addr_bus = i
                report "Erro: endereço incorreto no índice " & integer'image(i)
                severity error;

            report "Byte " & integer'image(i) & " transmitido com sucesso." severity note;
        end loop;

        spi_enable <= '0';
        report "Simulação concluída com sucesso." severity note;

        wait for 10 ns; 
        assert false report "Fim da simulação." severity failure;
    end process;

end architecture sim;
