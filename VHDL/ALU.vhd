library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
	PORT
	(
		operacao 	: IN unsigned (3 DOWNTO 0);
		operA		: IN unsigned(7 DOWNTO 0);
		operB		: IN unsigned(7 DOWNTO 0);
		Result		: buffer unsigned(7 DOWNTO 0);
		Cin			: IN STD_LOGIC; 			-- Carry in
		N,Z,C,B,V 	: buffer STD_LOGIC		
	);
end ALU;

architecture alu of ALU is
constant ADIC : unsigned(3 DOWNTO 0):="0001";
constant SUB  : unsigned(3 DOWNTO 0):="0010";
constant OU   : unsigned(3 DOWNTO 0):="0011";
constant E    : unsigned(3 DOWNTO 0):="0100";
constant NAO  : unsigned(3 DOWNTO 0):="0101";
constant DLE  : unsigned(3 DOWNTO 0):="0110";
constant DLD  : unsigned(3 DOWNTO 0):="0111";
constant DAE  : unsigned(3 DOWNTO 0):="1000";
constant DAD  : unsigned(3 DOWNTO 0):="1001";
constant X_OR  : unsigned(3 DOWNTO 0):="1010";

begin
	process (operA, operB, operacao,result,Cin)
	variable temp : unsigned(8 DOWNTO 0);
	begin
		case operacao is
		
		when ADIC =>
			temp := ('0'&operA) + ('0'&operB);
			result <= temp(7 DOWNTO 0);
			C <= temp(8);
			if (operA(7)=operB(7)) then
				if (operA(7) /= result(7)) then V <= '1';
					else V <= '0';
				end if;
			else V <= '0';
			end if;
		
		when SUB =>
			temp := ('0'&operA) - ('0'&operB);
			result <= temp(7 DOWNTO 0);
			B <= temp(8);
			if (operA(7) /= operB(7)) then
				if (operA(7) /= result(7)) then V <= '1';
					else V <= '0';
				end if;
			else V <= '0';
			end if;
		
		when OU =>
			result <= operA or operB;
		
		when E =>
			result <= operA and operB;
		
		when NAO =>
			result <= not operA;
		
		--shift aritimetico para esquerda
		when DLE =>
			C <= operA(7);
			result(7) <= operA(6);
			result(6) <= operA(5);
			result(5) <= operA(4);
			result(4) <= operA(3);
			result(3) <= operA(2);
			result(2) <= operA(1);
			result(1) <= operA(0);
			result(0) <= Cin;
		
		-- shift aritimetico para esquerda
		when DAE =>
			C <= operA(7);
			result(7) <= operA(6);
			result(6) <= operA(5);
			result(5) <= operA(4);
			result(4) <= operA(3);
			result(3) <= operA(2);
			result(2) <= operA(1);
			result(1) <= operA(0);
			result(0) <= '0';
		
		-- shift logico para direita
		when DLD =>
			C <= operA(0);
			result(0) <= operA(1);
			result(1) <= operA(2);
			result(2) <= operA(3);
			result(3) <= operA(4);
			result(4) <= operA(5);
			result(5) <= operA(6);
			result(6) <= operA(7);
			result(7) <= Cin;
		
		-- shift aritimetico para direita
		when DAD =>
			C <= operA(0);
			result(0) <= operA(1);
			result(1) <= operA(2);
			result(2) <= operA(3);
			result(3) <= operA(4);
			result(4) <= operA(5);
			result(5) <= operA(6);
			result(6) <= operA(7);
			result(7) <= '0';	

		when X_OR =>
			result <= operA xor operB;
		
		when others =>
			result <= (others =>'0');
			Z <= '0';
			N <= '0';
			C <= '0';
			V <= '0';
			B <= '0';
		end case;
		
		-- when result is zero, FLAG Z = 1
		if (result = 0) then 
			Z <= '1'; else Z <= '0';
		end if;
		
		N <= result(7);
	end process;

end alu;