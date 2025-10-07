LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memoria_led IS
    PORT (
        address_bus : IN  unsigned(7 downto 0);
        data_in     : IN  unsigned(7 downto 0);
        data_out    : OUT unsigned(7 downto 0);
        mem_write   : IN  std_logic;
        clk         : IN  std_logic;
        rst         : IN  std_logic
    );
END memoria_led;

ARCHITECTURE MEMO OF memoria_led IS
    -- Opcodes
    constant STA    : unsigned(7 downto 0) := x"10";
    constant LDA    : unsigned(7 downto 0) := x"20";
    constant ADD    : unsigned(7 downto 0) := x"30";
    constant HLT    : unsigned(7 downto 0) := x"F0";

    -- Tipo da memória
    TYPE data_array_type IS ARRAY (0 TO 255) OF unsigned(7 downto 0);
    signal data_array_sig : data_array_type;

BEGIN
    process (rst,clk)
    VARIABLE DATA_ARRAY: DATA;
        BEGIN
            IF (RST='1') THEN
                -- Program to select dataset based on button input
                -- 1. Read button state
                DATA_ARRAY(0) := LDA;       -- Load accumulator from button address
                DATA_ARRAY(1) := ADDR_BTN;  -- Special address for buttons (254)
                
                -- 2. Test if buttons are zero by updating ALU flags
                DATA_ARRAY(2) := ADD;       -- Add content of address 132 (which is 0) to AC
                DATA_ARRAY(3) := 132;       -- AC = AC + 0. This sets Z flag if AC is 0.
                
                -- 3. Conditional Jump
                DATA_ARRAY(4) := JZ;        -- If Z=1 (no buttons pressed), Jump to Dataset A code
                DATA_ARRAY(5) := 10;        -- Target address for jump (start of Dataset A)
                
                -- 4. Code for Dataset B (if buttons were pressed, fall-through here)
                DATA_ARRAY(6) := LDA;       -- Load AC with value from address 129 (5)
                DATA_ARRAY(7) := 129;
                DATA_ARRAY(8) := ADD;       -- Add value from address 133 (1)
                DATA_ARRAY(9) := 133;
                DATA_ARRAY(10) := JMP;      -- Jump to the end to store the result
                DATA_ARRAY(11) := 16;       -- Target address for jump (STA instruction)

                -- 5. Code for Dataset A (starts at address 10)
                DATA_ARRAY(12) := LDA;      -- Load AC with value from address 130 (10)
                DATA_ARRAY(13) := 130;
                DATA_ARRAY(14) := ADD;      -- Add value from address 131 (18)
                DATA_ARRAY(15) := 131;
                
                -- 6. Store the result from either dataset and halt
                DATA_ARRAY(16) := STA;      -- Store the result of the ADD in address 128
                DATA_ARRAY(17) := 128;
                DATA_ARRAY(18) := HLT;      -- Halt processor
                
                -- Initialize memory with data values (our "datasets")
                DATA_ARRAY(128) := 0;       -- Result storage
                DATA_ARRAY(129) := 5;       -- Dataset B, value 1
                DATA_ARRAY(130) := 10;      -- Dataset A, value 1
                DATA_ARRAY(131) := 18;      -- Dataset A, value 2
                DATA_ARRAY(132) := 0;       -- Constant 0 for testing flags
                DATA_ARRAY(133) := 1;       -- Dataset B, value 2

            ELSIF (RISING_EDGE(clk)) THEN
                if mem_write = '1' then
                    DATA_ARRAY(ADDRESS_BUS) := DATA_IN;
                else
                    DATA_ARRAY := DATA_ARRAY;
                end if;	
            END IF;		
            data_array_sig <= data_ARRAY;
    end process;

END MEMO;