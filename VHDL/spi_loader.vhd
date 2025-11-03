library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_loader is
    port (
        clk           : in  std_logic;                     
        spi_sck       : in  std_logic;                     
        spi_ss        : in  std_logic;                     
        spi_mosi      : in  std_logic;                     
        spi_enable    : in  std_logic;                     
        spi_data_out  : out unsigned(7 downto 0);          
        spi_addr_bus  : out unsigned(7 downto 0);          
        spi_mem_write : out std_logic                      
    );
end entity;

architecture rtl of spi_loader is
    signal shift_reg        : unsigned(7 downto 0) := (others => '0');
    signal bit_cnt          : unsigned(2 downto 0) := (others => '0');
    signal spi_data_reg     : unsigned(7 downto 0) := (others => '0');
    signal byte_ready_spi   : std_logic := '0';

    signal byte_ready_sys_0 : std_logic := '0';
    signal byte_ready_sys_1 : std_logic := '0';
    signal byte_ready_sys_2 : std_logic := '0';
    signal addr_cnt         : unsigned(7 downto 0) := (others => '0');
begin

    spi_shift_proc : process(spi_sck, spi_ss)
    begin
        if spi_ss = '1' then
            bit_cnt <= (others => '0');
        elsif rising_edge(spi_sck) then
            shift_reg <= shift_reg(6 downto 0) & spi_mosi;

            if bit_cnt = "111" then
                spi_data_reg   <= shift_reg(6 downto 0) & spi_mosi;
                byte_ready_spi <= not byte_ready_spi;  
                bit_cnt        <= (others => '0');
            else
                bit_cnt <= bit_cnt + 1;
            end if;
        end if;
    end process;

    sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            byte_ready_sys_0 <= byte_ready_spi;
            byte_ready_sys_1 <= byte_ready_sys_0;
            byte_ready_sys_2 <= byte_ready_sys_1;

            spi_mem_write <= '0';

            if spi_enable = '1' then
                if byte_ready_sys_2 /= byte_ready_sys_1 then
                    spi_data_out  <= spi_data_reg;
                    spi_addr_bus  <= addr_cnt;
                    spi_mem_write <= '1';
                    addr_cnt      <= addr_cnt + 1;
                end if;
            end if;

            if spi_ss = '1' then
                addr_cnt <= (others => '0');
            end if;
        end if;
    end process;

end architecture;
