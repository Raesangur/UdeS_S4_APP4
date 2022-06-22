---------------------------------------------------------------------------------------------
--
--	Université de Sherbrooke 
--  Département de génie électrique et génie informatique
--
--	S4i - APP4 
--	
--
--	Auteur: 		Marc-André Tétrault
-- 
---------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; -- requis pour la fonction "to_integer"
use work.MIPS32_package.all;

entity Dram_ModeleControlleurInterne is
generic(
	g_BurstSize	: natural := 2;
	g_TotalDelay : natural := 5
);
Port ( 
	clk 				: in std_ulogic;
	
	-- vers le controlleur de cache
	i_dram_ReadDataAddress	: in std_ulogic_vector(31 downto 2);
	i_dram_WriteDataAddress	: in std_ulogic_vector(31 downto 0);
	i_dram_ReadRequest	: in std_ulogic;
	i_dram_WriteRequest	: in std_ulogic;
	o_dram_WordIndexSel : out std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	o_dram_ReadAck 		: out std_ulogic;
    o_dram_WriteAck 	: out std_ulogic;
	o_dram_ReadDone		: out std_ulogic;
	o_dram_ReadData		: out std_ulogic_vector (31 downto 0);
	i_dram_WriteData	: in std_ulogic_vector (31 downto 0);

	-- vers la mémoire "normale"
	o_bram_MemRead 		: out std_ulogic;
	o_bram_MemWrite 	: out std_ulogic;
    o_bram_Addresse 	: out std_ulogic_vector (31 downto 0);
	o_bram_WriteData	: out std_ulogic_vector (31 downto 0);
    i_bram_ReadData 	: in std_ulogic_vector (31 downto 0)
);
end Dram_ModeleControlleurInterne;

architecture Behavioral of Dram_ModeleControlleurInterne is
    
	signal r_CompteurDelais	: unsigned(3 downto 0) := X"F";
	signal r_CompteurMots	: unsigned(3 downto 0) := X"F";

	signal r_dram_ReadRequest	: std_ulogic;
	signal s_bram_MemRead       : std_ulogic;
    
    
    signal r_CompteurWriteDelais	: unsigned(3 downto 0) := X"F";
	signal r_CompteurWriteMots	: unsigned(3 downto 0) := X"F";

	signal r_dram_WriteRequest	: std_ulogic;
    signal s_Write_ack : std_ulogic;

begin

-- add asserts for burst mode


s_bram_MemRead	<= '1' when (r_CompteurMots < g_BurstSize) and r_CompteurDelais = g_TotalDelay else '0'; 

process(clk)
begin
	if (clk'event and clk = '1') then 
		r_dram_ReadRequest <= i_dram_ReadRequest;
		if(i_dram_ReadRequest = '1' and r_dram_ReadRequest = '0') then
			r_CompteurDelais <= X"0";
		elsif(r_CompteurDelais < g_TotalDelay) then
			r_CompteurDelais <= r_CompteurDelais + 1;
		end if;
	end if; 
end process;

process(clk)
begin
	if (clk'event and clk = '1') then 
		if(i_dram_ReadRequest = '1' and r_dram_ReadRequest = '0') then
			r_CompteurMots <= X"0";
		elsif(r_CompteurDelais = g_TotalDelay and r_CompteurMots < 15) then
			r_CompteurMots <= r_CompteurMots + 1;
		end if;
	end if; 
end process;

o_dram_ReadDone <= '1' when r_CompteurMots = unsigned(to_unsigned(g_BurstSize, 4)) else '0';
o_dram_WordIndexSel	<= std_ulogic_vector(r_CompteurMots(2 downto 0));
o_dram_ReadAck	<= s_bram_MemRead;
o_dram_ReadData <= i_bram_ReadData;


o_bram_MemRead		<= s_bram_MemRead;
o_bram_Addresse 	<= std_ulogic_vector(unsigned(i_dram_ReadDataAddress) + r_CompteurMots) & "00" when s_bram_MemRead = '1' else -- read mode
					   i_dram_WriteDataAddress; -- else in write mode

-- no need to model burse mode
process(clk)
begin
	if (clk'event and clk = '1') then 
		r_dram_WriteRequest <= i_dram_WriteRequest;
		if(i_dram_WriteRequest = '1' and r_dram_WriteRequest = '0') then
			r_CompteurWriteDelais <= X"0";
		elsif(r_CompteurWriteDelais <= g_TotalDelay) then
			r_CompteurWriteDelais <= r_CompteurWriteDelais + 1;
		end if;
	end if; 
end process;

s_Write_ack         <= '1' when r_CompteurWriteDelais = g_TotalDelay else '0'; 
o_dram_WriteAck     <= s_Write_ack;
o_bram_MemWrite 	<= s_Write_ack;
o_bram_WriteData	<= i_dram_WriteData;


process(clk)
begin
	if (clk'event and clk = '1') then
        ASSERT not(i_dram_ReadRequest = '1' and i_dram_WriteRequest = '1') REPORT "simultaneous read and write request at dram" SEVERITY ERROR;
	end if; 
end process;

end Behavioral;

