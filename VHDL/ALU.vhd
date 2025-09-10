library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
	PORT
	(
		operacao 	: IN unsigned (3 DOWNTO 0);
		operA		: IN unsigned(7 DOWNTO 0);
		operB		: IN unsigned(7 DOWNTO 0);
		result		: out unsigned(7 DOWNTO 0);	
		Cin			: IN STD_LOGIC; 				-- Carry in
		-- negative , zero, carry, borrow, overflow
		N,Z,C,B,V 	: out STD_LOGIC			
	);
end ALU;

architecture alu of ALU is

-- opcodes
constant ADIC : unsigned(3 DOWNTO 0) 	:= "0001";
constant SUB  : unsigned(3 DOWNTO 0) 	:= "0010";
constant OU   : unsigned(3 DOWNTO 0) 	:= "0011";
constant E    : unsigned(3 DOWNTO 0) 	:= "0100";
constant NAO  : unsigned(3 DOWNTO 0) 	:= "0101";
constant XOU  : unsigned(3 DOWNTO 0)	:= "0110";
constant DLE  : unsigned(3 DOWNTO 0) 	:= "0111";
constant DLD  : unsigned(3 DOWNTO 0) 	:= "1000";
constant DAE  : unsigned(3 DOWNTO 0) 	:= "1001";
constant DAD  : unsigned(3 DOWNTO 0) 	:= "1010";

signal r_bf 	: unsigned(7 downto 0) := (others => '0');

-- Record para organizar as flags
type flags_t is record
	N : std_logic;
	Z : std_logic;
	C : std_logic;
	B : std_logic;
	V : std_logic;
end record;

-- Sinal interno das flags
signal f : flags_t := (
	N => '0',
	Z => '0',
	C => '0',
	B => '0',
	V => '0'
);

begin
	process (operA, operB, operacao,r_bf,Cin)
	variable temp : unsigned(8 DOWNTO 0);
	variable res8 : std_logic;

	begin
		case operacao is

		when ADIC =>
			temp := ('0' & operA) + ('0' & operB);
			r_bf <= temp(7 downto 0);
			f.C <= temp(8);
			f.Z <= '1' when temp(7 downto 0) = "00000000" else '0';
			f.N <= temp(7);

			if operA(7) = operB(7) then
				if operA(7) /= temp(7) then
					f.V <= '1';
				else
					f.V <= '0';
				end if;
			else
				f.V <= '0';
			end if;

		when SUB =>
			temp := ('0' & operA) - ('0' & operB);
			r_bf <= temp(7 downto 0);
			f.B <= temp(8);
			f.Z <= '1' when temp(7 downto 0) = "00000000" else '0';
			f.N <= temp(7);

			if operA(7) /= operB(7) then
				if operA(7) /= temp(7) then
					f.V <= '1';
				else
					f.V <= '0';
				end if;
			else
				f.V <= '0';
			end if;

		when OU =>
			r_bf <= operA or operB;
		
		when E =>
			r_bf <= operA and operB;
		
		when NAO =>
			r_bf <= not operA;
		
		when XOU =>
			r_bf <= operA xor operB;

		--shift aritimetico para esquerda
		when DLE =>
			f.C <= operA(7);
			r_bf(7) <= operA(6);
			r_bf(6) <= operA(5);
			r_bf(5) <= operA(4);
			r_bf(4) <= operA(3);
			r_bf(3) <= operA(2);
			r_bf(2) <= operA(1);
			r_bf(1) <= operA(0);
			r_bf(0) <= Cin;
		
		-- shift aritimetico para esquerda
		when DAE =>
			f.C <= operA(7);
			r_bf(7) <= operA(6);
			r_bf(6) <= operA(5);
			r_bf(5) <= operA(4);
			r_bf(4) <= operA(3);
			r_bf(3) <= operA(2);
			r_bf(2) <= operA(1);
			r_bf(1) <= operA(0);
			r_bf(0) <= '0';
		
		-- shift logico para direita
		when DLD =>
			f.C <= operA(0);
			r_bf(0) <= operA(1);
			r_bf(1) <= operA(2);
			r_bf(2) <= operA(3);
			r_bf(3) <= operA(4);
			r_bf(4) <= operA(5);
			r_bf(5) <= operA(6);
			r_bf(6) <= operA(7);
			r_bf(7) <= Cin;
		
		-- shift aritimetico para direita
		when DAD =>
			f.C <= operA(0);
			r_bf(0) <= operA(1);
			r_bf(1) <= operA(2);
			r_bf(2) <= operA(3);
			r_bf(3) <= operA(4);
			r_bf(4) <= operA(5);
			r_bf(5) <= operA(6);
			r_bf(6) <= operA(7);
			r_bf(7) <= '0';	

		
		when others =>
			r_bf <= (others =>'0');
			f.Z <= '0';
			f.N <= '0';
			f.C <= '0';
			f.V <= '0';
			f.B <= '0';
		end case;
		
		-- when r_bf is zero, FLAG Z = 1
		if temp(7 downto 0) = "00000000" then
			f.Z <= '1'; else f.Z <= '0';
		end if;

		
		f.N <= r_bf(7);

		N <= f.N;
		Z <= f.Z;
		C <= f.C;
		B <= f.B;
		V <= f.V;
		result <= r_bf;
	end process;
end alu;