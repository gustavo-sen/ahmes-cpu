ARCHITECTURE MEMO OF memoria IS
    -- (constantes e declarações permanecem as mesmas)
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0); [cite: 32]
    signal data_array_sig : data_array_type; [cite: 33]

BEGIN
    process (rst, clk)
    begin
        IF (rst = '1') THEN
            -- Durante o reset, a memória é apenas limpa com zeros.
            -- O programa principal será carregado externamente via SPI.
            data_array_sig <= (others => (others => '0'));
            
        ELSIF (rising_edge(clk)) THEN
            if mem_write = '1' then
                data_array_sig(to_integer(address_bus)) <= data_in;
            end if; 
        END IF;     
    end process;
    
    data_out <= (others => '0') when rst = '1' else data_array_sig(to_integer(address_bus));
END MEMO;