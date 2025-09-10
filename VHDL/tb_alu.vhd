library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_alu is
end tb_alu;

architecture test of tb_alu is

    signal operacao : unsigned(3 downto 0) := (others => '0');
    signal operA    : unsigned(7 downto 0) := (others => '0');
    signal operB    : unsigned(7 downto 0) := (others => '0');
    signal Result   : unsigned(7 downto 0);
    signal Cin      : std_logic := '0';
    signal N, Z, C, B, V : std_logic;

begin

    uut: entity work.ALU
        port map (
            operacao => operacao,
            operA    => operA,
            operB    => operB,
            Result   => Result,
            Cin      => Cin,
            N        => N,
            Z        => Z,
            C        => C,
            B        => B,
            V        => V
        );

    stim_proc: process
        variable actual_res : integer;
        variable all_passed : boolean := true;
        
        procedure check_test(
            name            : in string;
            expected_result : in integer;
            actual_result   : in integer;
            expected_N      : in std_logic := '0'; actual_N : in std_logic := '0';
            expected_Z      : in std_logic := '0'; actual_Z : in std_logic := '0';
            expected_C      : in std_logic := '0'; actual_C : in std_logic := '0';
            expected_B      : in std_logic := '0'; actual_B : in std_logic := '0';
            expected_V      : in std_logic := '0'; actual_V : in std_logic := '0'
        ) is
        begin
            if (expected_result = actual_result) and
               (expected_N = actual_N) and (expected_Z = actual_Z) and
               (expected_C = actual_C) and (expected_B = actual_B) and
               (expected_V = actual_V) then
                report "TEST PASSED: " & name severity note;
            else
                report "TEST FAILED: " & name severity error;
                report "  Expected Result: " & integer'image(expected_result) &
                       ", Actual Result: " & integer'image(actual_result) severity error;
                report "  Expected N: " & std_logic'image(expected_N) &
                       ", Actual N: " & std_logic'image(actual_N) severity error;
                report "  Expected Z: " & std_logic'image(expected_Z) &
                       ", Actual Z: " & std_logic'image(actual_Z) severity error;
                report "  Expected C: " & std_logic'image(expected_C) &
                       ", Actual C: " & std_logic'image(actual_C) severity error;
                report "  Expected B: " & std_logic'image(expected_B) &
                       ", Actual B: " & std_logic'image(actual_B) severity error;
                report "  Expected V: " & std_logic'image(expected_V) &
                       ", Actual V: " & std_logic'image(actual_V) severity error;
                all_passed := false;
            end if;
        end procedure;

    begin
        report "Inicio da simulacao" severity note;

        wait for 20 ns;

        -- TEST 1: 5 + 10 = 15
        operA <= to_unsigned(5,8);
        operB <= to_unsigned(10,8);
        operacao <= "0001";  -- ADIC (soma)
        wait for 40 ns;
        actual_res := to_integer(Result);
        check_test(
            name            => "Soma 5 + 10",
            expected_result => 15,
            actual_result   => actual_res,
            expected_N      => '0', actual_N => N,
            expected_Z      => '0', actual_Z => Z,
            expected_C      => '0', actual_C => C,
            expected_B      => '0', actual_B => B,
            expected_V      => '0', actual_V => V
        );

        -- TEST 2: 15 - 5 = 10
        operA <= to_unsigned(15,8);
        operB <= to_unsigned(5,8);
        operacao <= "0010";  -- SUB
        wait for 40 ns;
        actual_res := to_integer(Result);
        check_test(
            name            => "Sub 15 - 5",
            expected_result => 10,
            actual_result   => actual_res,
            expected_N      => '0', actual_N => N,
            expected_Z      => '0', actual_Z => Z,
            expected_C      => '0', actual_C => C,
            expected_B      => '0', actual_B => B,
            expected_V      => '0', actual_V => V
        );

        -- TEST 3: 255 + 1 => wrap to 0, carry out = 1, zero = 1
        operA <= to_unsigned(255,8);
        operB <= to_unsigned(1,8);
        operacao <= "0001"; -- ADIC
        wait for 40 ns;
        actual_res := to_integer(Result);
        check_test(
            name            => "Soma 255 + 1 (carry)",
            expected_result => 0,
            actual_result   => actual_res,
            expected_N      => '0', actual_N => N,
            expected_Z      => '1', actual_Z => Z,
            expected_C      => '1', actual_C => C,
            expected_B      => '0', actual_B => B,
            expected_V      => '0', actual_V => V
        );

        -- TEST 4: 100 + 50 = 150 (note: signed overflow occurs: V = 1; result MSB = 1 -> N = 1)
        operA <= to_unsigned(100,8);
        operB <= to_unsigned(50,8);
        operacao <= "0001"; -- ADIC
        wait for 40 ns;
        actual_res := to_integer(Result);
        check_test(
            name            => "Overflow soma 100 + 50",
            expected_result => 150,
            actual_result   => actual_res,
            expected_N      => '1', actual_N => N,   -- MSB of 150 is 1
            expected_Z      => '0', actual_Z => Z,
            expected_C      => '0', actual_C => C,   -- unsigned carry out = 0 (150 fits in 8 bits)
            expected_B      => '0', actual_B => B,
            expected_V      => '1', actual_V => V    -- signed overflow (100 + 50 > +127)
        );

        -- TEST 5:
        operA <= to_unsigned(128,8);
        operB <= to_unsigned(1,8);
        operacao <= "0010"; -- SUB
        wait for 40 ns;
        actual_res := to_integer(Result);
        check_test(
            name            => "Overflow negativo sub 0 - 1",
            expected_result => 0,
            actual_result   => actual_res,
            expected_N      => '0', actual_N => N,   -- MSB of 127 is 0
            expected_Z      => '0', actual_Z => Z,
            expected_C      => '1', actual_C => C,   -- em sub sem borrow, C geralmente = '1'
            expected_B      => '0', actual_B => B,
            expected_V      => '1', actual_V => V    -- signed overflow: -128 - 1 => +127
        );

        report "== End simulation ==" severity note;

        if all_passed then
            report "TODOS OS TESTES PASSARAM COM SUCESSO!" severity note;
        else
            report "ALGUNS TESTES FALHARAM." severity warning;
        end if;

        wait;
    end process;

end test;
