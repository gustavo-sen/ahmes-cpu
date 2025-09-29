LIBRARY ieee;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;

ENTITY ahmes_uc IS
    PORT
    (
        -- Barramento de endereços (8 bits)
        -- Address bus (8 bits)
        address_bus : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- Barramentos de dados unidirecionais (DATA_IN e DATA_OUT) de 8 bits
        -- Unidirectional Data buses (DATA_IN and DATA_OUT) (8 bits)
        data_in     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        mem_write   : OUT std_logic;      -- Sinal de escrita na memória (memory write signal)
        clk         : IN std_logic;       -- Clock principal (main clock)
        reset       : IN std_logic;       -- Reset da CPU (CPU reset)
        ERROR       : OUT STD_LOGIC;      -- Error (opcode ilegal) (illegal opcode error)
        -- Entrada dos botões
        btns : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- Saida dos leds
        leds : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- Barramentos de dados para interface com a ULA
        -- ALU interfacing data buses
        OPERACAO    : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);    -- Seleção da operação da ULA (ULA's operation select)
        OPER_A      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);     -- operando A (operand A)
        OPER_B      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);     -- operando B (operand B)
        RESULT      : IN STD_LOGIC_VECTOR(7 DOWNTO 0);      -- resultado (result)
        Cout        : OUT STD_LOGIC;                        -- Saída de Carry (Carry out)
        N,Z,C,B,V   : IN STD_LOGIC                          -- flags da ALU (ALU's flags)
    );
END ahmes_uc;

ARCHITECTURE cpu OF ahmes_uc IS
-- Constantes com as instruções do processador
-- Processor's instruction-constants
constant NOP : STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000";
constant STA : STD_LOGIC_VECTOR(7 DOWNTO 0):="00010000";
constant LDA : STD_LOGIC_VECTOR(7 DOWNTO 0):="00100000";
constant ADD : STD_LOGIC_VECTOR(7 DOWNTO 0):="00110000";
constant IOR : STD_LOGIC_VECTOR(7 DOWNTO 0):="01000000";
constant IAND: STD_LOGIC_VECTOR(7 DOWNTO 0):="01010000";
constant IXOR: STD_LOGIC_VECTOR(7 DOWNTO 0):="00011000";
constant INOT: STD_LOGIC_VECTOR(7 DOWNTO 0):="01100000";
constant SUB : STD_LOGIC_VECTOR(7 DOWNTO 0):="01110000";
constant JMP : STD_LOGIC_VECTOR(7 DOWNTO 0):="10000000";
constant JN  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10010000";
constant JP  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10010100";
constant JV  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10011000";
constant JNV : STD_LOGIC_VECTOR(7 DOWNTO 0):="10011100";
constant JZ  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10100000";
constant JNZ : STD_LOGIC_VECTOR(7 DOWNTO 0):="10100100";
constant JC  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10110000";
constant JNC : STD_LOGIC_VECTOR(7 DOWNTO 0):="10110100";
constant JB  : STD_LOGIC_VECTOR(7 DOWNTO 0):="10111000";
constant JNB : STD_LOGIC_VECTOR(7 DOWNTO 0):="10111100";
constant SHR : STD_LOGIC_VECTOR(7 DOWNTO 0):="11100000";
constant SHL : STD_LOGIC_VECTOR(7 DOWNTO 0):="11100001";
constant IROR: STD_LOGIC_VECTOR(7 DOWNTO 0):="11100010";
constant IROL: STD_LOGIC_VECTOR(7 DOWNTO 0):="11100011";
constant HLT : STD_LOGIC_VECTOR(7 DOWNTO 0):="11110000";
constant ADDR_BTN : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111110"; -- botão
constant ADDR_LED : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111000"; -- LED


-- Constantes que definem as operações da ULA
-- ALU operation's constants
constant ULA_ADD : STD_LOGIC_VECTOR(3 DOWNTO 0):="0001";
constant ULA_SUB : STD_LOGIC_VECTOR(3 DOWNTO 0):="0010";
constant ULA_OU  : STD_LOGIC_VECTOR(3 DOWNTO 0):="0011";
constant ULA_XOU : STD_LOGIC_VECTOR(3 DOWNTO 0):="0110";
constant ULA_E   : STD_LOGIC_VECTOR(3 DOWNTO 0):="0100";
constant ULA_NAO : STD_LOGIC_VECTOR(3 DOWNTO 0):="0101";
constant ULA_DLE : STD_LOGIC_VECTOR(3 DOWNTO 0):="0111";
constant ULA_DLD : STD_LOGIC_VECTOR(3 DOWNTO 0):="1000";
constant ULA_DAE : STD_LOGIC_VECTOR(3 DOWNTO 0):="1001";
constant ULA_DAD : STD_LOGIC_VECTOR(3 DOWNTO 0):="1010";

BEGIN
    -- sensibilidade nas bordas do sinal de clock e reset
    -- sensibility on clk and reset edges
    process (clk,reset)
    variable PC : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Contador de programa (program counter)
    variable AC : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Acumulador (accumulator)
    VARIABLE TEMP: STD_LOGIC_VECTOR(7 DOWNTO 0);    -- registrador temporário (temporary register)
    VARIABLE INSTR: STD_LOGIC_VECTOR(7 DOWNTO 0);   -- instrução atual (current instruction)
    -- Máquina de estados da CPU (CPU state machine)
    type Tcpu_state is (
        BUSCA, BUSCA1, DECOD,   -- estados básicos de busca e decodificação (basic fetch and decode states)
        DECOD_STA1, DECOD_STA2, DECOD_STA3, DECOD_STA4,     -- decodificação da instrução STA (STA decode)
        DECOD_LDA1, DECOD_LDA2, DECOD_LDA3,                 -- decodificação da instrução LDA (LDA decode)
        DECOD_ADD1, DECOD_ADD2, DECOD_ADD3,                 -- decodificação da instrução ADD (ADD decode)
        DECOD_SUB1, DECOD_SUB2, DECOD_SUB3,                 -- decodificação da instrução SUB (SUB decode)
        DECOD_IOR1, DECOD_IOR2, DECOD_IOR3,
        DECOD_IAND1, DECOD_IAND2, DECOD_IAND3, 
        DECOD_IXOR1, DECOD_IXOR2, DECOD_IXOR3,              -- decodificação da instrução OR (OR decode) -- decodificação da instrução AND (AND decode)
        DECOD_JMP,                                         -- decodificação da instrução JMP (JMP decode)
        DECOD_SHR1,                                        -- decodificação da instrução SHR (SHR decode)
        DECOD_SHL1,                                        -- decodificação da instrução SHL (SHL decode)
        DECOD_IROR1,                                       -- decodificação da instrução IROR (IROR decode)
        DECOD_IROL1,                                       -- decodificação da instrução IROL (IROL decode)
        DECOD_STORE
        );
    VARIABLE CPU_STATE : TCPU_STATE;  -- variável de estado da CPU (CPU state variable)
    begin
        if (reset='1') then
            -- Operações em caso de reset (reset operations)
            CPU_STATE := BUSCA; -- configura a máquina de estados para BUSCA (set CPU state machine to fetch)
            PC := (OTHERS => '0');   -- Inicializa o PC em zero (set PC to zero)
            MEM_WRITE <= '0';   -- desativa a linha de escrita na memória (disable memory write signal)
            ADDRESS_BUS <= (OTHERS => '0');  -- coloca zero no barramento de endereços (set the address bus to zero)
            DATA_OUT <= (OTHERS => '0');     -- coloca zero no barramento de dados (set the DATA_OUT bus to zero)
            OPERACAO <= (OTHERS => '0');     -- nenhuma operação na ULA (no operation on ALU)
        ELSIF ((clk'event and clk='1')) THEN    -- se for uma borda de subida do clock (if it's a clock rising edge)
            CASE CPU_STATE IS   -- verifica o estado atual da máquina de estados (select the current state of the CPU's state machine)
                WHEN BUSCA =>   -- primeiro ciclo da busca de instrução (first fetch cycle)
                    ADDRESS_BUS <= PC;      -- carrega o barramento de endereços com o PC (load address bus with the PC content)
                    ERROR <= '0';           -- força a saída de erros para zero (disable the error output)
                    CPU_STATE := BUSCA1;    -- avança para o estado BUSCA1 (next state = BUSCA1)
                WHEN BUSCA1 =>  -- segundo ciclo da busca de instrução (second fetch cycle)
                    INSTR := DATA_IN;       -- lê a instrução e armazena em INSTR (read the instruction and store into INSTR)
                    CPU_STATE := DECOD;     -- avança para o próximo estágio (next state = DECOD)
                WHEN DECOD =>   -- início da decodificação de instrução (now we will start decoding the instruction)
                    CASE INSTR IS          -- decod the INSTR content
                        -- NOP - não faz nada, apenas avança o PC
                        -- NOP - no operation, only increment PC
                        WHEN NOP =>
                            -- Conversão para unsigned, soma e conversão de volta para std_logic_vector
                            PC := std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := BUSCA;
                        -- STA - armazena o AC no endereço especificado pelo operando
                        -- STA - store the AC into the specified memory
                        WHEN STA =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_STA1;
                        -- LDA - carrega o acumulador com o conteúdo do endereço especificado pelo operando
                        -- LDA - load AC with the contents of the specified memory address
                        WHEN LDA =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_LDA1;
                        -- ADD - soma o acumulador com o conteúdo do endereço especificado pelo operando
                        -- ADD - add the contents of the specified memory address to the accumulator (AC)
                        WHEN ADD =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_ADD1;
                        -- SUB - subtrai o conteúdo do endereço especificado do conteúdo do acumulador
                        -- SUB - subtract the contents of the specified address from the current content of the accumulator
                        WHEN SUB =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_SUB1;
                        -- OR - operação lógica OU entre o acumulador e o conteúdo do endereço especificado pelo operando
                        -- OR - logic OR operation between the accumulator and the content of the specified address
                        WHEN IOR =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_IOR1;
                        -- AND - operação lógica E entre o acumulador e o conteúdo do endereço especificado pelo operando 
                        -- AND - logic AND operation between the accumulator and the content of the specified address
                        WHEN IAND =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_IAND1;
                        WHEN IXOR =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_IXOR1;
                        -- NOT - operação lógica NÃO do acumulador
                        -- NOT - logic NOT operation of the accumulator
                        WHEN INOT =>
                            OPER_A <= AC;
                            OPERACAO <= ULA_NAO;
                            PC := std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_STORE;
                        -- JMP - desvia para o endereço indicado após a instrução  
                        -- JMP - jumps to the specified address
                        WHEN JMP =>
                            ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                            CPU_STATE := DECOD_JMP;
                        -- JN - desvia para o endereço se N=1
                        -- JN - jump to the address if N = 1
                        WHEN JN =>
                            IF (N='1') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        -- JP - desvia para o endereço se N=0
                        -- JP - jump to the address if N=0
                        WHEN JP =>
                            IF (N='0') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        -- JV - desvia para o endereço se V=1
                        -- JV - jump to the address if V=1
                        WHEN JV =>
                            IF (V='1') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        -- JNV - desvia para o endereço se V=0
                        -- JNV - jump to the address if V=0
                        WHEN JNV =>
                            IF (V='0') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JZ =>
                            IF (Z='1') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JNZ =>
                            IF (Z='0') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JC =>
                            IF (C='1') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JNC =>
                            IF (C='0') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JB =>
                            IF (B='1') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN JNB =>
                            IF (B='0') THEN
                                ADDRESS_BUS <= std_logic_vector(unsigned(PC) + 1);
                                CPU_STATE := DECOD_JMP;
                            ELSE
                                PC := std_logic_vector(unsigned(PC) + 2);
                                CPU_STATE := BUSCA;
                            END IF;
                        WHEN SHR =>
                            CPU_STATE := DECOD_SHR1;
                        WHEN SHL =>
                            CPU_STATE := DECOD_SHL1;
                        WHEN IROR =>
                            Cout <= C;
                            CPU_STATE := DECOD_IROR1;
                        WHEN IROL =>
                            Cout <= C;
                            CPU_STATE := DECOD_IROL1;
                        WHEN HLT =>
                            NULL; -- HLT para o processamento, então não fazemos nada.
                        WHEN OTHERS =>
                            PC := std_logic_vector(unsigned(PC) + 1);
                            ERROR <= '1';
                            CPU_STATE := BUSCA;
                    END CASE;

                WHEN DECOD_STA1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_STA2;
                WHEN DECOD_STA2 =>
                    ADDRESS_BUS <= TEMP;
                    IF TEMP = ADDR_LED THEN
                        leds <= AC(3 DOWNTO 0);
                    ELSE
                        DATA_OUT <= AC;
                    END IF;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STA3;
                WHEN DECOD_STA3 =>
                    MEM_WRITE <= '1';
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STA4;
                WHEN DECOD_STA4 =>
                    MEM_WRITE <= '0';
                    CPU_STATE := BUSCA;
                WHEN DECOD_LDA1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_LDA2;
                WHEN DECOD_LDA2 =>
                    ADDRESS_BUS <= TEMP;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_LDA3;
                WHEN DECOD_LDA3 =>
                    IF TEMP = ADDR_BTN THEN
                        AC := "0000" & btns;
                    ELSE
                        AC := DATA_IN;
                    END IF;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := BUSCA;
                WHEN DECOD_ADD1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_ADD2;
                WHEN DECOD_ADD2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_ADD3;
                WHEN DECOD_ADD3 =>
                    OPER_A <= DATA_IN;
                    OPER_B <= AC;
                    OPERACAO <= ULA_ADD;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_SUB1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_SUB2;
                WHEN DECOD_SUB2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_SUB3;
                WHEN DECOD_SUB3 =>
                    OPER_A <= AC;
                    OPER_B <= DATA_IN;
                    OPERACAO <= ULA_SUB;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_IOR1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_IOR2;
                WHEN DECOD_IOR2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_IOR3;
                WHEN DECOD_IOR3 =>
                    OPER_A <= AC;
                    OPER_B <= DATA_IN;
                    OPERACAO <= ULA_OU;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_IAND1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_IAND2;
                WHEN DECOD_IAND2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_IAND3;
                WHEN DECOD_IAND3 =>
                    OPER_A <= AC;
                    OPER_B <= DATA_IN;
                    OPERACAO <= ULA_E;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_IXOR1 =>
                    TEMP := DATA_IN;
                    CPU_STATE := DECOD_IXOR2;
                WHEN DECOD_IXOR2 =>
                    ADDRESS_BUS <= TEMP;
                    CPU_STATE := DECOD_IXOR3;
                WHEN DECOD_IXOR3 =>
                    OPER_A <= AC;
                    OPER_B <= DATA_IN;
                    OPERACAO <= ULA_XOU;
                    PC := std_logic_vector(unsigned(PC) + 1);
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_JMP =>
                    PC := DATA_IN;
                    CPU_STATE := BUSCA;
                WHEN DECOD_SHR1 =>
                    OPER_A <= AC;
                    OPERACAO <= ULA_DAD;
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_SHL1 =>
                    OPER_A <= AC;
                    OPERACAO <= ULA_DAE;
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_IROR1 =>
                    OPER_A <= AC;
                    OPERACAO <= ULA_DLD;
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_IROL1 =>
                    OPER_A <= AC;
                    OPERACAO <= ULA_DLE;
                    CPU_STATE := DECOD_STORE;
                WHEN DECOD_STORE =>
                    AC := RESULT;
                    -- O incremento do PC já foi feito no estado de decodificação da instrução
                    -- PC increment was already done in the instruction decode state
                    CPU_STATE := BUSCA;
                WHEN OTHERS => NULL;
            END CASE;
        END IF;
    end process;
END CPU;