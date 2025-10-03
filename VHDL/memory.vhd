LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria IS
    PORT (
        address_bus : IN INTEGER RANGE 0 TO 255;
        data_in     : IN INTEGER RANGE 0 TO 255;
        data_out    : OUT INTEGER RANGE 0 TO 255;
        mem_write   : IN std_logic;
        clk         : IN std_logic;
        rst         : IN std_logic
    );
END memoria;

ARCHITECTURE MEMO OF memoria IS
    -- Constantes de instruções
    constant NOP  : INTEGER := 0;
    constant STA  : INTEGER := 16;
    constant IXOR : INTEGER := 24;
    constant LDA  : INTEGER := 32;
    constant ADD  : INTEGER := 48;
    constant IOR  : INTEGER := 64;
    constant IAND : INTEGER := 80;
    constant INOT : INTEGER := 96;
    constant SUB  : INTEGER := 112;
    constant JMP  : INTEGER := 128;
    constant JN   : INTEGER := 144;
    constant JP   : INTEGER := 148;
    constant JV   : INTEGER := 152;
    constant JNV  : INTEGER := 156;
    constant JZ   : INTEGER := 160;
    constant JNZ  : INTEGER := 164;
    constant JC   : INTEGER := 176;
    constant JNC  : INTEGER := 180;
    constant JB   : INTEGER := 184;
    constant JNB  : INTEGER := 188;
    constant SHR  : INTEGER := 224;
    constant SHL  : INTEGER := 225;
    constant IROR : INTEGER := 226;
    constant IROL : INTEGER := 227;
    constant HLT  : INTEGER := 240;
    constant ADDR_LED : INTEGER := 248;
    constant ADDR_BTN : INTEGER := 254;

    TYPE data_array_type IS ARRAY (0 TO 255) OF INTEGER;
    signal data_array_sig : data_array_type;
BEGIN

    process(rst, clk)
        variable data_array : data_array_type;
    BEGIN
        if rst = '1' then
            -- Inicializa memória
            data_array(0)  := LDA; data_array(1)  := 130;
            data_array(2)  := SUB; data_array(3)  := 132;
            data_array(4)  := JZ;  data_array(5)  := 8;
            data_array(6)  := JMP; data_array(7)  := 2;
            data_array(8)  := LDA; data_array(9)  := 130;
            data_array(10) := ADD; data_array(11) := 131;
            data_array(12) := STA; data_array(13) := 128;
            data_array(14) := LDA; data_array(15) := 129;
            data_array(16) := SHL; data_array(17) := SHL;
            data_array(18) := SHL; data_array(19) := SHL;
            data_array(20) := IOR; data_array(21) := 128;
            data_array(22) := STA; data_array(23) := 133;
            data_array(24) := HLT;
            -- Dados
            data_array(128) := 0;
            data_array(129) := 5;
            data_array(130) := 10;
            data_array(131) := 18;
            data_array(132) := 1;

        elsif rising_edge(clk) then
            if mem_write = '1' then
                data_array(address_bus) := data_in;
            end if;
        end if;

        data_array_sig <= data_array;
    end process;

    data_out <= data_array_sig(address_bus);

END MEMO;
