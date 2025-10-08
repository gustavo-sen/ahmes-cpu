LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; -- Biblioteca padrão, já estava correta

ENTITY ahmes_uc IS
    PORT (
        -- ========================================================================
        -- MUDANÇA PRINCIPAL: Todas as portas que representam números ou barramentos
        -- foram trocadas de STD_LOGIC_VECTOR para unsigned.
        -- ========================================================================
        address_bus : OUT unsigned(7 DOWNTO 0);
        data_in     : IN  unsigned(7 DOWNTO 0);
        data_out    : OUT unsigned(7 DOWNTO 0);
        mem_write   : OUT std_logic;
        clk         : IN  std_logic;
        reset       : IN  std_logic;
        ERROR       : OUT STD_LOGIC;
        btns        : IN  unsigned(3 DOWNTO 0);
        leds        : OUT unsigned(3 DOWNTO 0);
        OPERACAO    : OUT unsigned(3 DOWNTO 0);
        OPER_A      : OUT unsigned(7 DOWNTO 0);
        OPER_B      : OUT unsigned(7 DOWNTO 0);
        RESULT      : IN  unsigned(7 DOWNTO 0);
        Cout        : OUT STD_LOGIC;
        N, Z, C, B, V : IN STD_LOGIC
    );
END ENTITY ahmes_uc;

ARCHITECTURE cpu OF ahmes_uc IS
    -- As constantes precisam ser convertidas para o tipo unsigned para comparação
    constant NOP : unsigned(7 DOWNTO 0) := "00000000";
    constant STA : unsigned(7 DOWNTO 0) := "00010000";
    constant LDA : unsigned(7 DOWNTO 0) := "00100000";
    constant ADD : unsigned(7 DOWNTO 0) := "00110000";
    constant IOR : unsigned(7 DOWNTO 0) := "01000000";
    constant IAND: unsigned(7 DOWNTO 0) := "01010000";
    constant IXOR: unsigned(7 DOWNTO 0) := "00011000";
    constant INOT: unsigned(7 DOWNTO 0) := "01100000";
    constant SUB : unsigned(7 DOWNTO 0) := "01110000";
    constant JMP : unsigned(7 DOWNTO 0) := "10000000";
    constant JN  : unsigned(7 DOWNTO 0) := "10010000";
    constant JP  : unsigned(7 DOWNTO 0) := "10010100";
    constant JV  : unsigned(7 DOWNTO 0) := "10011000";
    constant JNV : unsigned(7 DOWNTO 0) := "10011100";
    constant JZ  : unsigned(7 DOWNTO 0) := "10100000";
    constant JNZ : unsigned(7 DOWNTO 0) := "10100100";
    constant JC  : unsigned(7 DOWNTO 0) := "10110000";
    constant JNC : unsigned(7 DOWNTO 0) := "10110100";
    constant JB  : unsigned(7 DOWNTO 0) := "10111000";
    constant JNB : unsigned(7 DOWNTO 0) := "10111100";
    constant SHR : unsigned(7 DOWNTO 0) := "11100000";
    constant SHL : unsigned(7 DOWNTO 0) := "11100001";
    constant IROR: unsigned(7 DOWNTO 0) := "11100010";
    constant IROL: unsigned(7 DOWNTO 0) := "11100011";
    constant HLT : unsigned(7 DOWNTO 0) := "11110000";
    constant ADDR_BTN : unsigned(7 DOWNTO 0) := "11111110";
    constant ADDR_LED : unsigned(7 DOWNTO 0) := "11111000";

    constant ULA_ADD : unsigned(3 DOWNTO 0) := "0001";
    constant ULA_SUB : unsigned(3 DOWNTO 0) := "0010";
    constant ULA_OU  : unsigned(3 DOWNTO 0) := "0011";
    constant ULA_XOU : unsigned(3 DOWNTO 0) := "0110";
    constant ULA_E   : unsigned(3 DOWNTO 0) := "0100";
    constant ULA_NAO : unsigned(3 DOWNTO 0) := "0101";
    constant ULA_DLE : unsigned(3 DOWNTO 0) := "0111";
    constant ULA_DLD : unsigned(3 DOWNTO 0) := "1000";
    constant ULA_DAE : unsigned(3 DOWNTO 0) := "1001";
    constant ULA_DAD : unsigned(3 DOWNTO 0) := "1010";

BEGIN
    process (clk, reset)
        variable PC    : unsigned(7 DOWNTO 0);
        variable AC    : unsigned(7 DOWNTO 0);
        variable TEMP  : unsigned(7 DOWNTO 0);
        variable INSTR : unsigned(7 DOWNTO 0);

        type Tcpu_state is (
            BUSCA, BUSCA1, DECOD,
            DECOD_STA1, DECOD_STA2, DECOD_STA3, DECOD_STA4,
            DECOD_LDA1, DECOD_LDA2, DECOD_LDA3,
            DECOD_ADD1, DECOD_ADD2, DECOD_ADD3,
            DECOD_SUB1, DECOD_SUB2, DECOD_SUB3,
            DECOD_IOR1, DECOD_IOR2, DECOD_IOR3,
            DECOD_IAND1, DECOD_IAND2, DECOD_IAND3,
            DECOD_IXOR1, DECOD_IXOR2, DECOD_IXOR3,
            DECOD_JMP,
            DECOD_SHR1, DECOD_SHL1, DECOD_IROR1, DECOD_IROL1,
            DECOD_STORE
        );
        variable CPU_STATE : Tcpu_state;
    begin
        if (reset = '1') then
            CPU_STATE   := BUSCA;
            PC          := (OTHERS => '0');
            MEM_WRITE   <= '0';
            ADDRESS_BUS <= (OTHERS => '0');
            DATA_OUT    <= (OTHERS => '0');
            OPERACAO    <= (OTHERS => '0');

        elsif (clk'event and clk = '1') then
            case CPU_STATE is
                when BUSCA =>
                    ADDRESS_BUS <= PC;
                    ERROR       <= '0';
                    CPU_STATE   := BUSCA1;

                when BUSCA1 =>
                    INSTR     := DATA_IN;
                    CPU_STATE := DECOD;

                when DECOD =>
                    case INSTR is
                        when NOP =>
                            PC := PC + 1;
                            CPU_STATE := BUSCA;

                        when STA =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_STA1;

                        when LDA =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_LDA1;

                        when ADD =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_ADD1;

                        when SUB =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_SUB1;

                        when IOR =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_IOR1;

                        when IAND =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_IAND1;
                            
                        when IXOR =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_IXOR1;

                        when INOT =>
                            OPER_A    <= AC;
                            OPERACAO  <= ULA_NAO;
                            PC        := PC + 1;
                            CPU_STATE := DECOD_STORE;

                        when JMP =>
                            ADDRESS_BUS <= PC + 1;
                            CPU_STATE   := DECOD_JMP;

                        when JN =>
                            if (N = '1') then
                                ADDRESS_BUS <= PC + 1;
                                CPU_STATE   := DECOD_JMP;
                            else
                                PC        := PC + 2;
                                CPU_STATE := BUSCA;
                            end if;

                        when JP =>
                            if (N = '0') then
                                ADDRESS_BUS <= PC + 1;
                                CPU_STATE   := DECOD_JMP;
                            else
                                PC        := PC + 2;
                                CPU_STATE := BUSCA;
                            end if;
                        
                        -- ... (demais saltos condicionais são similares) ...
                        
                        when JZ =>
                            if (Z = '1') then
                                ADDRESS_BUS <= PC + 1;
                                CPU_STATE   := DECOD_JMP;
                            else
                                PC        := PC + 2;
                                CPU_STATE := BUSCA;
                            end if;
                            
                        when HLT =>
                            null; -- Para a máquina de estados

                        when others =>
                            PC        := PC + 1;
                            ERROR     <= '1';
                            CPU_STATE := BUSCA;
                    end case;
                    
                when DECOD_STA1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_STA2;
                    
                when DECOD_STA2 =>
                    ADDRESS_BUS <= TEMP;
                    if TEMP = ADDR_LED then
                         leds <= AC(3 downto 0);
                    else
                         DATA_OUT <= AC;
                    end if;
                    PC := PC + 1;
                    CPU_STATE := DECOD_STA3;
                    
                when DECOD_STA3 =>
                    MEM_WRITE <= '1';
                    PC := PC + 1;
                    CPU_STATE := DECOD_STA4;

                when DECOD_STA4 =>
                    MEM_WRITE <= '0';
                    CPU_STATE := BUSCA;

                when DECOD_LDA1 =>
                    TEMP      := DATA_IN;
                    CPU_STATE := DECOD_LDA2;

                when DECOD_LDA2 =>
                    ADDRESS_BUS <= TEMP;
                    PC        := PC + 1;
                    CPU_STATE := DECOD_LDA3;

                when DECOD_LDA3 =>
                    if TEMP = ADDR_BTN then
                        AC := "0000" & btns;
                    else
                        AC := DATA_IN;
                    end if;
                    PC        := PC + 1;
                    CPU_STATE := BUSCA;

                when DECOD_ADD1 =>
                    TEMP      := DATA_IN;
                    CPU_STATE := DECOD_ADD2;

                when DECOD_ADD2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_ADD3;

                when DECOD_ADD3 =>
                    -- MUDANÇA LÓGICA: Ordem dos operandos corrigida para consistência
                    OPER_A    <= AC;       -- Operando A é o acumulador
                    OPER_B    <= DATA_IN;  -- Operando B é o da memória
                    OPERACAO  <= ULA_ADD;
                    PC        := PC + 2; -- Incrementa PC em 2 para pular opcode e operando
                    CPU_STATE := DECOD_STORE;

                when DECOD_SUB1 =>
                    TEMP      := DATA_IN;
                    CPU_STATE := DECOD_SUB2;

                when DECOD_SUB2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_SUB3;

                when DECOD_SUB3 =>
                    OPER_A    <= AC;
                    OPER_B    <= DATA_IN;
                    OPERACAO  <= ULA_SUB;
                    PC        := PC + 2;
                    CPU_STATE := DECOD_STORE;

                when DECOD_JMP =>
                    PC        := DATA_IN;
                    CPU_STATE := BUSCA;

                when DECOD_STORE =>
                    AC        := RESULT;
                    CPU_STATE := BUSCA;
                    
                when others =>
                    CPU_STATE := BUSCA;
            end case;
        end if;
    end process;
END ARCHITECTURE cpu;