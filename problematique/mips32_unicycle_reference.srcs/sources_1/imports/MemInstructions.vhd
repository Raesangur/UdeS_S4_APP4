---------------------------------------------------------------------------------------------
--
--	Universit� de Sherbrooke 
--  D�partement de g�nie �lectrique et g�nie informatique
--
--	S4i - APP4 
--	
--
--	Auteur: 		Marc-Andr� T�trault
--					Daniel Dalle
--					S�bastien Roy
-- 
---------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; -- requis pour la fonction "to_integer"
use work.MIPS32_package.all;

entity MemInstructions is
Port ( 
    i_addresse 		: in std_ulogic_vector (31 downto 0);
    o_instruction 	: out std_ulogic_vector (31 downto 0)
);
end MemInstructions;

architecture Behavioral of MemInstructions is
    signal ram_Instructions : RAM(0 to 255) := (
------------------------
-- Inserez votre code ici


-- main
x"3c011001",    -- la       $a0    met
x"34240020",
x"3c011001",    -- la       $a1    si
x"34250000",
x"3c011001",    -- la       $a2    so
x"34260010",
x"0c100009",    -- jal      calcul_survivant
x"2402000a",    -- li       $v0    10
x"0000000c",    -- syscall

-- calcul_survivant
x"3c011001",    -- lui      $at    0x00001001
x"34280060",    -- ori      $t0    $at      0x60
x"71100000",    -- lwv      $s0    0($t0)               8d100000    100011(01)  011100(01)      71100000
x"74d00000",    -- swv      $s0    0($a2)               acd00000    101011      011101          74d00000  
x"20010004",    -- addi     $at    $zero    4
x"03a1e822",    -- sub      $sp    $sp      $at
x"afbf0000",    -- sw       $ra    0($sp)
x"0c100014",    -- jal      acs
x"8fbf0000",    -- lw       $ra    0(sp)
x"27bd0004",    -- addi     $sp    4
x"03e00008",    -- jr       $ra

-- acs
x"24080004",    -- li       $t0    4
x"24090000",    -- li       $t1    0
x"70b10000",    -- lwv      $s1     0($a1)              8cb10000    100011      011100          70b10000
x"0128082b",    -- sltu     
x"10200008",    -- beq
x"70900000",    -- lwv      $s0     0($a0)              8c900000    100011      011100          70900000
x"02118021",    -- addu     $s0     $s0     $s1         02118021    000000
x"7e0a0000",    -- sml      $t2     $s0     0           8e0a0000    100011(10)  011111          7e0a0000
x"acca0000",    -- sw       $t2     0($a2)
--x"74d20000",    -- swv      $s2     0($a2)              acd20000    101011      011101          74d20000
x"24840010",    -- addiu    $a0     $a0     16
x"24c60004",    -- addiu    $a2     $a2     4
x"25290001",    -- addiu    $t1     $t1     1
x"08100017",    -- j        loop
x"03e00008",    -- jr       $ra


---- main
--x"3c011001",
--x"34240020",
--x"3c011001",
--x"34250000",
--x"3c011001",
--x"34260010",
--x"0c100018",
--x"2402000a",
--x"0000000c",

---- acs
--x"24080004",    -- li       $t0    4
--x"24090000",    -- li       $t1    0
--x"0128082b",    -- sltu     $at    $t1      $t0
--x"1020000a",    -- beq      $at    $zero    0x0b

--x"70900000",    -- lwv      $s0     0($a0)              8c900000    100011      011100          70900000
--x"70b10000",    -- lwv      $s1     0($a1)              8cb10000    100011      011100          70b10000 
--x"02118021",    -- addu     $s0     $s0     $s1         02118021    000000
--x"70d20000",    -- lwv      $s2     0($a2)              8cd20000    100011      011100          70d20000
--x"0212882a",    -- slt      $s1     $s0     $s2         0212882a    000000
--x"7a119010",    -- movn     $s2     $s0     $s1         0211900b    000000      011110 - 10000  7a119010
--x"74d20000",    -- swv      $s2     0($a2)              acd20000    101011      011101          74d20000

--x"24840010",    -- addiu    $a0     $a0     16
--x"25290001",    -- addiu    $t1     $t1     1
--x"0810000b",    -- j        loop
--x"03e00008",    -- jr       $ra

---- calcul_survivant
--x"3c011001",    -- lui      $at    0x00001001
--x"34280060",    -- ori      $t0    $at      0x60
--x"71100000",    -- lwv      $s0    0($t0)               8d100000    100011(01)  011100(01)      71100000
--x"74d00000",    -- swv      $s0    0($a2)               acd00000    101011      011101          74d00000  
--x"20010004",    -- addi     $at    $zero    4
--x"03a1e822",    -- sub      $sp    $sp      $at
--x"afbf0000",    -- sw       $ra    0($sp)
--x"0c100009",    -- jal      acs
--x"8fbf0000",    -- lw       $ra    0(sp)
--x"27bd0004",    -- addi     $sp    4
--x"03e00008",    -- jr       $ra

------------------------
-- Code sans SIMD
------------------------

--x"3c011001",
--x"34240020",
--x"3c011001",
--x"34250000",
--x"3c011001",
--x"34260010",
--x"0c100019",
--x"2402000a",
--x"0000000c",
--x"24080004",
--x"24090000",
--x"0128082b",
--x"1020000b",
--x"8c8a0000",
--x"8cab0000",
--x"014b5021",
--x"8ccb0000",
--x"014b082b",
--x"10200001",
--x"acca0000",
--x"24840004",
--x"24a50004",
--x"25290001",
--x"0810000b",
--x"03e00008",
--x"00806021",
--x"00a06821",
--x"00c07021",
--x"24080004",
--x"24090000",
--x"0128082b",
--x"10200014",
--x"240a00fa",
--x"adca0000",
--x"01805021",
--x"00095900",
--x"014b2021",
--x"2001000c",
--x"03a1e822",
--x"afa80000",
--x"afa90004",
--x"afbf0008",
--x"01a02821",
--x"01c03021",
--x"0c100009",
--x"8fbf0008",
--x"8fa90004",
--x"8fa80000",
--x"27bd000c",
--x"25ce0004",
--x"25290001",
--x"0810001e",
--x"03e00008",

------------------------
-- Code de validation
------------------------

--X"3c011001", -- la    $t0 data
--X"34280000",
--X"71100010", -- lw    $s0 16($t0)
--X"71110020", -- lw    $s1 32($t0)
--X"02119821", -- add   $s3 $s0 $s1
--X"75130000", -- sw    $s3 0($t0) 
--X"0211a02a", -- slt   $s4 $s0 $s1
--X"7a34980b", -- movnv $s3 $s1 $s4

------------------------
-- Fin de votre code
------------------------
    others => X"00000000"); --> SLL $zero, $zero, 0  

    signal s_MemoryIndex : integer range 0 to 255;

begin
    -- Conserver seulement l'indexage des mots de 32-bit/4 octets
    s_MemoryIndex <= to_integer(unsigned(i_addresse(9 downto 2)));

    -- Si PC vaut moins de 127, pr�senter l'instruction en m�moire
    o_instruction <= ram_Instructions(s_MemoryIndex) when i_addresse(31 downto 10) = (X"00400" & "00")
                    -- Sinon, retourner l'instruction nop X"00000000": --> AND $zero, $zero, $zero  
                    else (others => '0');

end Behavioral;

