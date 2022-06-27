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

entity MemDonnees is
Port ( 
	clk 		: in std_ulogic;
	reset 		: in std_ulogic;
	i_MemRead 	: in std_ulogic;
	i_MemWrite 	: in std_ulogic;
	i_vect      : in std_ulogic;
    i_Addresse 	: in std_ulogic_vector (31 downto 0);
	i_WriteData : in std_ulogic_vector (127 downto 0);
    o_ReadData 	: out std_ulogic_vector (127 downto 0)
);
end MemDonnees;

architecture Behavioral of MemDonnees is
    signal ram_DataMemory : RAM(0 to 255) := ( -- type d�fini dans le package
------------------------
-- Ins�rez vos donnees ici
------------------------
--  TestMirroir_data
X"12345678",
X"87654321",
X"bad0face",
X"00000001",
X"00000002",
X"00000003",
X"00000004",
X"00000005",
X"00000006",
X"5555cccc",
------------------------
-- Fin de votre code
------------------------
    others => X"00000000");

    signal s_MemoryIndex 	    : integer range 0 to 255; -- 0-127
	signal s_MemoryRangeValid 	: std_ulogic;

begin
    -- Transformation de l'adresse en entier � interval fix�s
    s_MemoryIndex 	<= to_integer(unsigned(i_Addresse(9 downto 2)));
	s_MemoryRangeValid <= '1' when i_Addresse(31 downto 10) = (X"10010" & "00") else '0'; 
	
	
	-- Partie pour l'�criture
	process( clk )
    begin
        if clk='1' and clk'event then
            if i_MemWrite = '1' and reset = '0' and s_MemoryRangeValid = '1' then
                if (i_vect = '0') then
                    ram_DataMemory(s_MemoryIndex) <= i_WriteData(31 downto 0);
                else
                    ram_DataMemory(s_MemoryIndex)     <= i_WriteData(31 downto 0);
                    ram_DataMemory(s_MemoryIndex + 1) <= i_WriteData(63 downto 32);
                    ram_DataMemory(s_MemoryIndex + 2) <= i_WriteData(95 downto 64);
                    ram_DataMemory(s_MemoryIndex + 3) <= i_WriteData(127 downto 96);
                end if;
            end if;
        end if;
    end process;

    -- Valider que nous sommes dans le segment de memoire, avec 256 addresses valides
    o_ReadData(31 downto 0)   <= ram_DataMemory(s_MemoryIndex)     when (s_MemoryRangeValid = '1' and i_MemRead = '1')
                                 else (others => '0');
    o_ReadData(63 downto 32)  <= ram_DataMemory(s_MemoryIndex + 1) when (s_MemoryRangeValid = '1' and i_MemRead = '1' and i_vect = '1')
                                 else (others => '0');
    o_ReadData(95 downto 64)  <= ram_DataMemory(s_MemoryIndex + 2) when (s_MemoryRangeValid = '1' and i_MemRead = '1' and i_vect = '1')
                                 else (others => '0');
    o_ReadData(127 downto 96) <= ram_DataMemory(s_MemoryIndex + 3) when (s_MemoryRangeValid = '1' and i_MemRead = '1' and i_vect = '1')
                                 else (others => '0');

end Behavioral;

