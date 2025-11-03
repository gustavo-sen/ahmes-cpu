library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_loader is
    port (
        clk          : in  std_logic;
        spi_sck      : in  std_logic;
        spi_ss       : in  std_logic;
        spi_mosi     : in  std_logic;
        spi_enable   : in  std_logic;
        spi_data_out : out unsigned(7 downto 0);
        spi_addr_bus : out unsigned(7 downto 0);
        spi_mem_write: out std_logic
    );
end entity spi_loader;

architecture rtl of spi_loader is
    signal shift_reg   : unsigned(7 downto 0) := (others => '0');
    signal bit_cnt     : unsigned(2 downto 0) := (others => '0');
    signal addr_cnt    : unsigned(7 downto 0) := (others => '0');
    signal data_valid  : std_logic := '0';
    signal disable_spi : std_logic := '0';

    signal sck_sync0, sck_sync1, sck_prev : std_logic := '0';
    signal ss_sync0, ss_sync : std_logic := '0';
begin

    ss_sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            ss_sync0 <= spi_ss;
            ss_sync  <= ss_sync0;
        end if;
    end process;

    spi_capture_proc : process(clk)
    begin
        if rising_edge(clk) then
            sck_sync0 <= spi_sck;
            sck_sync1 <= sck_sync0;

            if sck_prev = '0' and sck_sync1 = '1' then
                if spi_ss = '0' and disable_spi = '0' then
                    shift_reg <= shift_reg(6 downto 0) & spi_mosi;

                    if bit_cnt = "111" then
                        data_valid <= '1';
                        bit_cnt    <= (others => '0');
                    else
                        bit_cnt <= bit_cnt + 1;
                    end if;
                end if;
            end if;

            sck_prev <= sck_sync1;

            if spi_ss = '1' then
                bit_cnt    <= (others => '0');
                data_valid <= '0';
            end if;
        end if;
    end process;

    system_proc : process(clk)
    begin
        if rising_edge(clk) then
            spi_mem_write <= '0';

            if ss_sync = '1' then
                addr_cnt   <= (others => '0');
                disable_spi <= '0';
            else
                if disable_spi = '1' then
                    disable_spi <= '0';
                elsif data_valid = '1' then
                    spi_data_out  <= shift_reg;
                    spi_addr_bus  <= addr_cnt;
                    spi_mem_write <= '1';
                    addr_cnt      <= addr_cnt + 1;
                    disable_spi   <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
