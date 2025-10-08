LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY spi_loader IS
    PORT (
        -- Clock principal do sistema
        clk           : IN  STD_LOGIC;
        
        -- Sinais da interface SPI (entradas)
        spi_sck       : IN  STD_LOGIC; -- Clock do SPI
        spi_ss        : IN  STD_LOGIC; -- Slave Select (ativo em '0')
        spi_mosi      : IN  STD_LOGIC; -- Master Out, Slave In
        
        -- Sinais de controle para o barramento da memória (saídas)
        spi_addr_bus  : OUT unsigned(7 downto 0);
        spi_data_out  : OUT unsigned(7 downto 0);
        spi_mem_write : OUT STD_LOGIC
    );
END ENTITY spi_loader;

ARCHITECTURE rtl OF spi_loader IS
    signal bit_counter   : unsigned(2 downto 0);
    signal shift_reg     : unsigned(7 downto 0);
    signal addr_counter  : unsigned(7 downto 0) := (others => '0');
    signal sck_old       : STD_LOGIC := '0';
BEGIN

    process(clk)
    begin
        if rising_edge(clk) then
            sck_old <= spi_sck;
            spi_mem_write <= '0'; -- mem_write é um pulso, o padrão é '0'

            if spi_ss = '1' then -- Se não estiver selecionado, reseta os contadores
                bit_counter  <= (others => '0');
                addr_counter <= (others => '0');
            else -- Modo de carregamento ativo (spi_ss = '0')
                -- Detecta borda de subida do clock SPI
                if spi_sck = '1' and sck_old = '0' then
                    shift_reg <= shift_reg(6 downto 0) & spi_mosi;
                    bit_counter <= bit_counter + 1;

                    if bit_counter = "111" then -- Após 8 bits (1 byte)
                        spi_mem_write <= '1'; -- Gera o pulso de escrita
                        spi_data_out  <= shift_reg; -- Coloca o byte no barramento de dados
                        spi_addr_bus  <= addr_counter; -- Coloca o endereço atual no barramento
                        addr_counter  <= addr_counter + 1; -- Prepara o endereço para o próximo byte
                    end if;
                end if;
            end if;
        end if;
    end process;

END ARCHITECTURE rtl;