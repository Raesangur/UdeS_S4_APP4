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

entity Dram_ControleExterne is
Port ( 
	clk 				: in std_ulogic;
	i_cpu_ReadRequest 	: in std_ulogic;
	i_cpu_WriteRequest 	: in std_ulogic;
	o_cpu_ReadAckow		: out std_ulogic; -- sortie MEF
	o_cpu_WriteAckow	: out std_ulogic; -- sortie MEF
    i_cpu_Addresse		: in std_ulogic_vector (31 downto 0);
	i_cpu_WriteData		: in std_ulogic_vector (31 downto 0);
    o_cpu_ReadData		: out std_ulogic_vector (31 downto 0);
	
	-- vers le controlleur de mémoire
	o_dram_ReadDataAddress	: out std_ulogic_vector(31 downto 2);
	o_dram_ReadRequest	: out std_ulogic;
	o_dram_WriteRequest	: out std_ulogic;
	i_dram_WordIndexSel : in std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	i_dram_ReadAck 		: in std_ulogic;
    i_dram_WriteAck     : in std_ulogic;
	i_dram_ReadDone		: in std_ulogic;
	i_dram_ReadData		: in std_ulogic_vector (31 downto 0);
	o_dram_WriteDataAddress	: out std_ulogic_vector(31 downto 0);
	o_dram_WriteData	: out std_ulogic_vector (31 downto 0)
);
end Dram_ControleExterne;



architecture Behavioral of Dram_ControleExterne is

	
	constant c_BlockSizeBits : integer := 3; 
	
	-- MEF Moore
	type t_mef_cacheController is (
		etat_Idle,
		etat_ReadFetch,
		etat_ReadComplete
		--etat_WriteComplete -- pas requis au labo
	);
	
	signal mef_cacheController		: t_mef_cacheController := etat_Idle;
	signal mef_cacheController_next : t_mef_cacheController := etat_Idle;

	
	signal s_CacheMiss			: std_ulogic;
	signal s_RequestedBlockValid     : std_ulogic;
	signal s_RequestedBlockTagMatch  : std_ulogic;
	
	
	signal r_RequestedWord  : std_ulogic_vector(31 downto 0);
	

begin

-- Changement d'état
process(clk)
begin
	if (clk'event and clk = '1') then 
		mef_cacheController <= mef_cacheController_next;
	end if; 
end process;

-- Transitions

process(mef_cacheController, s_CacheMiss, i_dram_ReadDone, i_cpu_ReadRequest, i_cpu_WriteRequest)
begin
	case mef_cacheController is
		when etat_Idle =>
			if(i_cpu_ReadRequest = '1') then
				mef_cacheController_next <= etat_ReadFetch;
			--elsif(i_cpu_WriteRequest = '1') then
			--	mef_cacheController_next <= etat_WriteComplete;
			else
				mef_cacheController_next <= etat_Idle;
			end if;
			
		when etat_ReadFetch =>
			if(i_dram_ReadDone = '1') then
				mef_cacheController_next <= etat_ReadComplete;
			else
				mef_cacheController_next <= etat_ReadFetch;
			end if;
		
		when etat_ReadComplete =>
			mef_cacheController_next <= etat_Idle;
			
		--when etat_WriteComplete =>
		--	mef_cacheController_next <= etat_Idle;
			
	end case;
end process;


-- Sorties de la MEF en lecture
o_dram_ReadRequest <= '1' when mef_cacheController = etat_ReadFetch     else '0';
o_cpu_ReadAckow	   <= '1' when mef_cacheController = etat_ReadComplete  else '0';
----------------------------------------------------------------------


----------------------------------------------------------------------
-- Buffer de lecture (prendre le bon mot dans le burst de lecture
----------------------------------------------------------------------
process(clk)
begin
	if (clk'event and clk = '1') then
		-- writing from dram (write to all words in the block)
		if(i_dram_ReadAck = '1' and i_dram_WordIndexSel(c_BlockSizeBits - 3 downto 0) = i_cpu_Addresse(c_BlockSizeBits - 1 downto 2)) then
			r_RequestedWord <= i_dram_ReadData;
		end if;
	end if; 
end process;

o_cpu_ReadData 		 <= r_RequestedWord;

-- Aligner l'accès à la DRAM avec la taille du bloc en mode lecture
o_dram_ReadDataAddress(31 downto c_BlockSizeBits)	 <= i_cpu_Addresse(31 downto c_BlockSizeBits);
o_dram_ReadDataAddress(c_BlockSizeBits - 1 downto 2) <= i_cpu_Addresse(c_BlockSizeBits - 1 downto 2) when i_cpu_WriteRequest = '1' else (others => '0');
o_dram_WriteDataAddress <= i_cpu_Addresse;

----------------------------------------------------------------------
-- Écriture - pas requis au labo
----------------------------------------------------------------------
-- Sorties de la MEF en écriture
o_cpu_WriteAckow    <= '0';
o_dram_WriteRequest <= '0';
o_dram_WriteData    <= (others => '0');

end Behavioral;

