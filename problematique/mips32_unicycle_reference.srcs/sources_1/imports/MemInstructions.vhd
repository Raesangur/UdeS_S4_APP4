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
-- Ins�rez votre code ici
------------------------
--  TestMirroir
X"20100002", -- 20100024
X"3c011001",
X"00300821",
X"70310000", -- lwv
X"7431000c", -- swv
X"02208021", -- addu $s0 $s1 $zero
X"0004c820",
X"0c100007",
X"08100015",
X"00805020",
X"00001020",
X"200cffff",
X"340b8000",
X"000b5c00",
X"20090020",
X"11200006",
X"00021042",
X"014b4024",
X"00481025",
X"000a5040",
X"2129ffff",
X"0810000d",
X"03e00008",
X"00402820",
X"22100004",
X"3c011001",
X"00300821",
X"ac220000",
X"2002000a",
X"0000000c",


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

