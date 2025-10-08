LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; -- Biblioteca padrão moderna para aritmética

ENTITY ALU IS
    PORT (
        operacao : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        operA    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        operB    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        Result   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- 'buffer' trocado por 'out'
        Cin      : IN  STD_LOGIC;
        N, Z, C, B, V : OUT STD_LOGIC -- 'buffer' trocado por 'out'
    );
END ENTITY ALU;

ARCHITECTURE alu OF ALU IS
    -- As constantes permanecem as mesmas
    constant ADIC : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    constant SUB  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    constant OU   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    constant XOU  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    constant E    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    constant NAO  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    constant DLE  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    constant DLD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    constant DAE  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001";
    constant DAD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";

    -- Sinais internos para substituir a funcionalidade do 'buffer'
    signal result_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal n_s, z_s, c_s, b_s, v_s : STD_LOGIC;

BEGIN
    -- Processo principal da ALU
    process(operA, operB, operacao, Cin)
        -- Variável temporária para operações aritméticas, agora do tipo unsigned
        variable temp : unsigned(8 DOWNTO 0);
    begin
        -- Inicialização padrão dos sinais internos
        result_s <= (others => '0');
        c_s <= '0';
        v_s <= '0';
        b_s <= '0';

        case operacao is
            when ADIC =>
                -- Conversão explícita para unsigned antes da soma
                temp := unsigned('0' & operA) + unsigned('0' & operB);
                result_s <= std_logic_vector(temp(7 DOWNTO 0));
                c_s <= temp(8);
                -- Lógica de Overflow para soma
                if operA(7) = operB(7) and operA(7) /= result_s(7) then
                    v_s <= '1';
                else
                    v_s <= '0';
                end if;

            when SUB =>
                -- Conversão explícita para unsigned antes da subtração
                temp := unsigned('0' & operA) - unsigned('0' & operB);
                result_s <= std_logic_vector(temp(7 DOWNTO 0));
                b_s <= not temp(8); -- Borrow é o inverso do carry da subtração
                -- Lógica de Overflow para subtração
                if operA(7) /= operB(7) and operB(7) = result_s(7) then
                    v_s <= '1';
                else
                    v_s <= '0';
                end if;

            when OU =>
                result_s <= operA or operB;
            when E =>
                result_s <= operA and operB;
            when NAO =>
                result_s <= not operA;
            when XOU =>
                result_s <= operA xor operB;

            -- Operações de deslocamento/rotação refatoradas e mais concisas
            when DLE => -- Rotação para a esquerda
                result_s <= operA(6 DOWNTO 0) & Cin;
                c_s <= operA(7);
            when DAE => -- Deslocamento lógico para a esquerda
                result_s <= operA(6 DOWNTO 0) & '0';
                c_s <= operA(7);
            when DLD => -- Rotação para a direita
                result_s <= Cin & operA(7 DOWNTO 1);
                c_s <= operA(0);
            when DAD => -- Deslocamento lógico para a direita
                result_s <= '0' & operA(7 DOWNTO 1);
                c_s <= operA(0);

            when others =>
                result_s <= (others => '0');
                c_s <= '0';
                v_s <= '0';
                b_s <= '0';
        end case;
    end process;

    -- Processo para calcular as flags N e Z
    process(result_s)
    begin
        if result_s = "00000000" then
            z_s <= '1';
        else
            z_s <= '0';
        end if;
        n_s <= result_s(7);
    end process;

    -- Atribuição final dos sinais internos para as portas de saída
    Result <= result_s;
    N <= n_s;
    Z <= z_s;
    C <= c_s;
    B <= b_s;
    V <= v_s;

END ARCHITECTURE alu;