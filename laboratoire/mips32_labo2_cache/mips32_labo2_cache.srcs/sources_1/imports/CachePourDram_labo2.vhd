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

Library UNISIM;           
use UNISIM.vcomponents.all; -- requis pour le buffer/Fifo

entity CachePourDram is
Port ( 
	clk 				: in std_ulogic;
	reset 				: in std_ulogic;
	i_cpu_ReadRequest 	: in std_ulogic;
	i_cpu_WriteRequest 	: in std_ulogic;
	o_cpu_ReadAckow		: out std_ulogic;
	o_cpu_WriteAckow	: out std_ulogic;
    i_cpu_Addresse		: in std_ulogic_vector (31 downto 0);
	i_cpu_WriteData		: in std_ulogic_vector (31 downto 0);
    o_cpu_ReadData		: out std_ulogic_vector (31 downto 0);
	
	-- vers le controlleur de mémoire
	o_dram_ReadDataAddress	: out std_ulogic_vector(31 downto 2);
	o_dram_ReadRequest	: out std_ulogic;
	o_dram_WriteRequest	: out std_ulogic;
	i_dram_WordIndexSel : in std_ulogic_vector(2 downto 0);
	i_dram_ReadAck 		: in std_ulogic;
	i_dram_WriteAck 	: in std_ulogic;
	i_dram_ReadDone		: in std_ulogic;
	i_dram_ReadData		: in std_ulogic_vector (31 downto 0);
	o_dram_WriteDataAddress	: out std_ulogic_vector(31 downto 0);
	o_dram_WriteData	: out std_ulogic_vector (31 downto 0)
);
end CachePourDram;


architecture Behavioral of CachePourDram is

	
	-- description de la cache	
	-- On souhaite obtenir la configuration suivante:
	constant c_BlockCount	 : integer := 16; 
	constant c_WordsPerBlock : integer := 2; 
	
	
	
    -- Déterminez le découpage requis des champs pour une cache direct, avec les 
	-- champs ci bas présentement incorrects. Voir COD5-fig 5.12 pour des indices.	
	constant c_Tag_BitCount	   : integer := 10; --???
	constant c_BlockIndex_BitCount   : integer := 9;--???
	constant c_BlockOffset_BitCount   : integer := 9;--???
	constant c_ByteOffset_BitCount   : integer := 4;--???
	-- les valeurs ci-haut, avant modification, donne : tttttttttt_iiiiiiiii_mmmmmmmmm_oooo
	
	---------------------------------------------------------------------------------------------------------
	-- Génération automatique des bus en fonction des valeurs ci-haut.
	constant c_TagPlusIndex    : integer := c_Tag_BitCount + c_BlockIndex_BitCount;
	constant c_TagPlusIndexLsb : integer := 32 - c_TagPlusIndex;

	-- types "maison". Tableau 2D pour la cache (nombre de blocs, nombre de mots/bloc)
    type t_cache_data is array (natural range <>, natural range <>) of std_ulogic_vector(31 downto 0);
	type t_ram_tag    is array (natural range <>) of std_ulogic_vector (c_Tag_BitCount - 1 downto 0);
	
	-- mémoire interne de la cache (bit de validité, étiquette et mémoire de données
	signal cache_validity_array			: std_ulogic_vector(c_BlockCount - 1 downto 0) := (others => '0');
    signal cache_tag_array 				: t_ram_tag(c_BlockCount - 1 downto 0) 		:= (others => (others => '0'));
    signal cache_userData_array 			: t_cache_data(c_BlockCount - 1 downto 0, c_WordsPerBlock - 1 downto 0) := (others => (others => (others => 'U')));
	
	signal s_cache_BlockIndex	    : integer range 0 to c_BlockCount - 1;
	signal s_cache_BlockOffset      : integer range 0 to c_WordsPerBlock - 1;

	signal s_addr_tag_bits			: std_ulogic_vector(c_Tag_BitCount - 1 downto 0);
	signal s_addr_BlockIndex_bits		: std_ulogic_vector(c_BlockIndex_BitCount - 1 downto 0);
	signal s_addr_BlockOffset_bits	: std_ulogic_vector(c_BlockOffset_BitCount - 1 downto 0);
	signal s_addr_ByteOffset_bits	: std_ulogic_vector(c_ByteOffset_BitCount - 1 downto 0);
	---------------------------------------------------------------------------------------------------------
	
	signal s_CacheMiss			: std_ulogic;
	signal s_RequestedBlockValid     : std_ulogic;
	signal s_RequestedBlockTagMatch  : std_ulogic;
	
	
	signal s_LocalCacheWrite			: std_ulogic;
	signal s_buffer_write_enable   : std_ulogic;
	signal s_buffer_empty          : std_ulogic;
	signal s_buffer_full           : std_ulogic; -- max 16 mots    
	signal s_dram_WordIndex			: integer range 0 to c_WordsPerBlock - 1;
	
	-- MEF Mealy pour la cache
	type t_mef_cacheController is (
		etat_Wait_Or_CacheReadHit_Or_Write,
		etat_ReadMiss_FlushWriteBuffer,
		etat_ReadMiss_FetchWait,
		etat_WriteBufferFull_Wait
	);
	
	signal mef_cacheController		: t_mef_cacheController := etat_Wait_Or_CacheReadHit_Or_Write;
	signal mef_cacheController_next : t_mef_cacheController := etat_Wait_Or_CacheReadHit_Or_Write;
	
	component BasicFifo is
      generic (
        g_WIDTH : natural := 8;
        g_DEPTH : integer := 32
        );
      port (
        i_rst_sync : in std_logic;
        i_clk      : in std_logic;
     
        -- FIFO Write Interface
        i_wr_en   : in  std_logic;
        i_wr_data : in  std_logic_vector(g_WIDTH-1 downto 0);
        o_full    : out std_logic;
     
        -- FIFO Read Interface
        i_rd_en   : in  std_logic;
        o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
        o_empty   : out std_logic
        );
        end component;
	

begin


-- Configuration/assignations --??? remplacer par les lignes plus bas
s_addr_tag_bits			<= (others => '0');
s_addr_BlockIndex_bits	<= (others => '0');
s_addr_BlockOffset_bits	<= (others => '0');
s_addr_ByteOffset_bits	<= (others => '0');

--s_addr_tag_bits			<= i_cpu_Addresse(?? downto ??);
--s_addr_BlockIndex_bits	<= i_cpu_Addresse(?? downto ??);
--s_addr_BlockOffset_bits	<= i_cpu_Addresse(?? downto ??);
--s_addr_ByteOffset_bits	<= i_cpu_Addresse(?? downto ??);





----------------------------------------------------------------------
-- MEF Mealy : 1- si échec, attendre la mémoire principale et remplacer
--                le bloc (lecture et écriture)
--             2- si réussite, immédiatement envoyer au cpu la donnée
--			       contenue dans la cache.
----------------------------------------------------------------------

-- Changement d'état
process(clk)
begin
	if (clk'event and clk = '1') then
	    if(reset = '1') then
	        mef_cacheController <= etat_Wait_Or_CacheReadHit_Or_Write;
	    else 
		    mef_cacheController <= mef_cacheController_next;
	    end if;
	end if; 
end process;

-- Transitions de la MEF
process(mef_cacheController, s_CacheMiss, i_dram_ReadDone, i_cpu_ReadRequest, i_cpu_WriteRequest, s_buffer_empty, s_buffer_full)
begin
	case mef_cacheController is
        -- en attente, ou sur un hit, rester à l'état en cours
		when etat_Wait_Or_CacheReadHit_Or_Write =>
			if(i_cpu_ReadRequest = '1' and s_CacheMiss = '1') then
                if(s_buffer_empty = '0') then
                    mef_cacheController_next <= etat_ReadMiss_FlushWriteBuffer;
                else
                    mef_cacheController_next <= etat_ReadMiss_FetchWait;
                end if;
			elsif(i_cpu_WriteRequest = '1' and s_buffer_full = '1') then
				mef_cacheController_next <= etat_WriteBufferFull_Wait;
			else
				mef_cacheController_next <= etat_Wait_Or_CacheReadHit_Or_Write;
			end if;
        
        -- sur un miss en lecture, et si le buffer n'est pas vide, attendre que le buffer se vide
        when etat_ReadMiss_FlushWriteBuffer =>
            if(s_buffer_empty = '0') then
                mef_cacheController_next <= etat_ReadMiss_FlushWriteBuffer;
            else
                mef_cacheController_next <= etat_ReadMiss_FetchWait;
            end if;
        
        -- sur un miss en lecture, attendre le délai d'accès de lecture de la DRAM
		when etat_ReadMiss_FetchWait =>
			if(i_dram_ReadDone = '1') then
				mef_cacheController_next <= etat_Wait_Or_CacheReadHit_Or_Write;
			else
				mef_cacheController_next <= etat_ReadMiss_FetchWait;
			end if;
		
        -- En écriture, si le buffer est plein (16 mots), attendre d'en enlever au moins 1.
        -- (full va retomber à 0)
		when etat_WriteBufferFull_Wait =>
			if(s_buffer_full = '1') then
				mef_cacheController_next <= etat_WriteBufferFull_Wait;
			else
				mef_cacheController_next <= etat_Wait_Or_CacheReadHit_Or_Write;
			end if;
			
	end case;
end process;


-- Sorties de la MEF
o_dram_ReadRequest <= '1' when mef_cacheController = etat_ReadMiss_FetchWait and s_buffer_empty = '1' else '0';
o_cpu_ReadAckow	   <= '1' when i_cpu_ReadRequest  = '1' and s_CacheMiss = '0' and mef_cacheController = etat_Wait_Or_CacheReadHit_Or_Write      else '0';
o_cpu_WriteAckow   <= '1' when i_cpu_WriteRequest = '1' and s_buffer_full = '0' else '0';
----------------------------------------------------------------------


----------------------------------------------------------------------
-- Mux pour choisir le bon mot dans la cache (accès en lecture)
-- indice : similaire à la nomenclature du procédural 2  tttttbbbbmmmoooo
-- note: (0 downto 0) est un std_ulogic_vector de 1 bit
----------------------------------------------------------------------
s_cache_BlockIndex	    <= 0; --??? effacer et remplacer par ligne ci-bas avec le bon signal (lignes 125-128)
s_cache_BlockOffset	    <= 0; --??? effacer et remplacer par ligne ci-bas avec le bon signal (lignes 125-128)
--s_cache_BlockIndex	<= to_integer(unsigned(s_addr_???_bits));
--s_cache_BlockOffset	<= to_integer(unsigned(s_addr_???_bits));
o_cpu_ReadData 		<= cache_userData_array(s_cache_BlockIndex, s_cache_BlockOffset);


-- Aligner l'accès à la DRAM avec la taille du bloc en mode lecture
o_dram_ReadDataAddress(31 downto c_TagPlusIndexLsb)	 <= i_cpu_Addresse(31 downto c_TagPlusIndexLsb);
o_dram_ReadDataAddress(c_TagPlusIndexLsb - 1 downto 2) <= i_cpu_Addresse(c_TagPlusIndexLsb - 1 downto 2) when i_cpu_WriteRequest = '1' else (others => '0');

----------------------------------------------------------------------
-- Écriture dans la cache
--		  1- Quand une donnée vient du cpu, le cpu contrôle la destination
--           dans le bloc (idem à la lecture, o_cpu_ReadData ci haut). 
--           L'écriture est faite seulement si on a un hit. 
--        2- Quand les données arrivent de la mémoire dram principale,
--			 la dram contrôle la destination dans le bloc. Le # du bloc
--			 est déterminé par l'adresse demandée par le cpu, mais l'index
--           du mot (s_dram_WordIndex) dépend si on est au premier ou deuxième
--           mot de l'accès en séquence (i_dram_WordIndexSel)
----------------------------------------------------------------------
s_LocalCacheWrite <= '1' when mef_cacheController = etat_Wait_Or_CacheReadHit_Or_Write and i_cpu_WriteRequest = '1' and s_CacheMiss = '0' else
					 '0';
                     
s_dram_WordIndex <= to_integer(unsigned(i_dram_WordIndexSel));

process(clk)
begin
	if (clk'event and clk = '1') then
		-- écriture dans la cache par le cpu (sw), 
		if(s_LocalCacheWrite = '1') then
			cache_userData_array(s_cache_BlockIndex, s_cache_BlockOffset) 	<= i_cpu_WriteData;
            
        -- writing from dram (write to all words in the block)
		elsif(i_dram_ReadAck = '1') then
			cache_validity_array(s_cache_BlockIndex)	<= '1';
			cache_tag_array     (s_cache_BlockIndex)	<= (others => '0');--??? effacer et remplacer par ligne ci-bas
			--cache_tag_array     (s_cache_BlockIndex)	<= s_addr_???_bits;
			cache_userData_array(s_cache_BlockIndex, s_dram_WordIndex) 	<= i_dram_ReadData;			
			
		end if;
	end if; 
end process;

----------------------------------------------------------------------
-- Vérification hit/miss checks
----------------------------------------------------------------------
s_RequestedBlockValid		<= cache_validity_array(s_cache_BlockIndex);
s_RequestedBlockTagMatch	<= '0'; --??? effacer et remplacer par ligne ci-bas
--s_RequestedBlockTagMatch	<= '1' when cache_tag_array(s_cache_BlockIndex) = s_addr_???_bits else '0';
s_CacheMiss					<= '1'; --??? remplacer par logique combinatoire pour déterminer si il y a un miss. Forme libre.
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Tampon d'écriture (cache en mode "Write buffer")
-- Discussion des modes d'écriture dans COD5 section 5.3
-- Note: le almost full permet de dépasser de 1, ensuite géré par la MEF
-- qui tombe en attente.
----------------------------------------------------------------------
o_dram_WriteRequest <= not s_buffer_empty and not i_dram_WriteAck;
s_buffer_write_enable <= '1' when i_cpu_WriteRequest = '1' and mef_cacheController = etat_Wait_Or_CacheReadHit_Or_Write else '0';


   
   inst_WriteBuff : BasicFifo
      generic map(
        g_WIDTH => 64,
        g_DEPTH => 32
        )
      port map(
        i_rst_sync => reset,
        i_clk      => clk,
     
        -- FIFO Write Interface
        i_wr_en   => s_buffer_write_enable,
        i_wr_data(31 downto 0) => i_cpu_WriteData,
        i_wr_data(63 downto 32) => i_cpu_Addresse,
        o_full    => s_buffer_full,
     
        -- FIFO Read Interface
        i_rd_en   => i_dram_WriteAck,
        o_rd_data(31 downto 0) => o_dram_WriteData,
        o_rd_data(63 downto 32) => o_dram_WriteDataAddress,
        o_empty   => s_buffer_empty
        );
   

-- vérification d'erreur automatisée + reset de la fifo
process(clk)
begin
	if (clk'event and clk = '1') then
        ASSERT not (i_cpu_ReadRequest = '1' and i_cpu_WriteRequest = '1') 
            REPORT "simultaneous read and write request" SEVERITY ERROR;
	end if; 
end process;


end Behavioral;

