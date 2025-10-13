LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY spi_loader IS
    PORT (
        clk           : IN  STD_LOGIC;
        
        spi_sck       : IN  STD_LOGIC; -- Clock do SPI
        spi_ss        : IN  STD_LOGIC; -- Slave Select (ativo em '0')
        spi_mosi      : IN  STD_LOGIC; -- Master Out, Slave In
        
        spi_addr_bus  : OUT unsigned(7 downto 0);
        spi_data_out  : OUT unsigned(7 downto 0);
        spi_mem_write : OUT STD_LOGIC
    );
END ENTITY spi_loader;

ARCHITECTURE rtl OF spi_loader IS
    SIGNAL bit_counter   : unsigned(2 downto 0);
    SIGNAL shift_reg     : unsigned(7 downto 0);
    SIGNAL addr_counter  : unsigned(7 downto 0) := (others => '0');
    SIGNAL sck_old       : STD_LOGIC := '0';
BEGIN

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            sck_old <= spi_sck;
            spi_mem_write <= '0'; -- mem_write é um pulso, o padrão é '0'

            IF spi_ss = '1' THEN -- Se não estiver selecionado, reseta os contadores
                bit_counter  <= (others => '0');
                addr_counter <= (others => '0');
            ELSE -- Modo de carregamento ativo (spi_ss = '0')
                -- Detecta borda de subida do clock SPI
                IF spi_sck = '1' AND sck_old = '0' THEN
                    shift_reg <= shift_reg(6 downto 0) & spi_mosi;
                    bit_counter <= bit_counter + 1;

                    IF bit_counter = "111" THEN -- Após 8 bits (1 byte)
                        spi_mem_write <= '1'; -- Gera o pulso de escrita
                        spi_data_out  <= shift_reg; -- Coloca o byte no barramento de dados
                        spi_addr_bus  <= addr_counter; -- Coloca o endereço atual no barramento
                        addr_counter  <= addr_counter + 1; -- Prepara o endereço para o próximo byte
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;
