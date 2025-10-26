LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY spi_loader IS
    PORT (
        clk           : IN  STD_LOGIC; 
        spi_sck       : IN  STD_LOGIC;  
        spi_ss        : IN  STD_LOGIC;  
        spi_mosi      : IN  STD_LOGIC;
		  spi_data_out  : OUT unsigned(7 downto 0);
		  spi_addr_bus  : OUT unsigned(7 downto 0);
        spi_mem_write : OUT STD_LOGIC
    );
END ENTITY spi_loader;

ARCHITECTURE rtl OF spi_loader IS

    SIGNAL spi_domain_shift_reg : unsigned(7 downto 0) := (others => '0');
    SIGNAL spi_domain_bit_cnt   : unsigned(2 downto 0) := (others => '0');

    SIGNAL addr_counter         : unsigned(7 downto 0) := (others => '0');
    
    SIGNAL data_valid           : STD_LOGIC := '0';
    SIGNAL disable_spi          : STD_LOGIC := '0'; 

    SIGNAL spi_ss_sync_p        : STD_LOGIC;
    SIGNAL spi_ss_sync          : STD_LOGIC;

BEGIN


    spi_capture_proc : PROCESS(spi_sck, spi_ss)
    BEGIN
        IF spi_ss = '1' THEN 
            spi_domain_bit_cnt <= (others => '0');
            data_valid         <= '0';
        ELSIF rising_edge(spi_sck) THEN
            IF spi_ss = '0' AND disable_spi = '0' THEN 
                spi_domain_shift_reg <= spi_domain_shift_reg(6 downto 0) & spi_mosi;
                
                IF spi_domain_bit_cnt = "111" THEN
                    data_valid         <= '1'; 
                    spi_domain_bit_cnt <= (others => '0');
                ELSE
                    spi_domain_bit_cnt <= spi_domain_bit_cnt + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS spi_capture_proc;

    spi_ss_sync_proc : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            spi_ss_sync_p <= spi_ss;
            spi_ss_sync   <= spi_ss_sync_p;
        END IF;
    END PROCESS spi_ss_sync_proc;

    system_clock_proc : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            spi_mem_write <= '0';

            IF spi_ss_sync = '1' THEN
                addr_counter <= (others => '0');
                disable_spi  <= '0'; 

            ELSE
                IF disable_spi = '1' THEN
                    disable_spi <= '0'; 
                ELSIF data_valid = '1' THEN 
                    spi_data_out  <= spi_domain_shift_reg; 
                    
                    spi_addr_bus  <= addr_counter;
                    spi_mem_write <= '1';
                    
                    addr_counter  <= addr_counter + 1;
                    
                    disable_spi   <= '1'; 
                END IF;
            END IF;
        END IF;
    END PROCESS system_clock_proc;

END ARCHITECTURE rtl;