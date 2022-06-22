---------------------------------------------------------------------------------------------
--
--	Université de Sherbrooke 
--  Département de génie électrique et génie informatique
--
--	S4i - APP4 
--	
--
--	Auteur: 		Marc-André Tétrault
--					Daniel Dalle
--					Sébastien Roy
-- 
---------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS32_package.all;

library std;
use std.env.stop;

entity cache_testbench is
end cache_testbench;

architecture Behavioral of cache_testbench is


	component Dram_ModeleControlleurInterne is
	generic (
		g_BurstSize	: integer := 2
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

		o_bram_MemRead 		: out std_ulogic;
		o_bram_MemWrite 	: out std_ulogic;
		o_bram_Addresse 	: out std_ulogic_vector (31 downto 0);
		o_bram_WriteData	: out std_ulogic_vector (31 downto 0);
		i_bram_ReadData 	: in std_ulogic_vector (31 downto 0)
	);
	end component;
	
	component CachePourDram is
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
		i_dram_WordIndexSel : in std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
		i_dram_ReadAck 		: in std_ulogic;
        i_dram_WriteAck 	: in std_ulogic;
		i_dram_ReadDone		: in std_ulogic;
		i_dram_ReadData		: in std_ulogic_vector (31 downto 0);
        o_dram_WriteDataAddress	: out std_ulogic_vector(31 downto 0);
		o_dram_WriteData	: out std_ulogic_vector (31 downto 0)
	);
	end component;
	
	component MemDonnees is
	Port ( 
		clk 		: in std_ulogic;
		reset 		: in std_ulogic;
		i_MemRead 	: in std_ulogic;
		i_MemWrite 	: in std_ulogic;
		i_Addresse 	: in std_ulogic_vector (31 downto 0);
		i_WriteData : in std_ulogic_vector (31 downto 0);
		o_ReadData 	: out std_ulogic_vector (31 downto 0)
	);
	end component;
	
	type t_sequence_cache_element is record
		mode     : std_ulogic;
		adresse  : std_ulogic_vector (31 downto 0);
		data     : std_ulogic_vector (31 downto 0);
		pause    : natural;
	end record t_sequence_cache_element;
	type t_sequence_cache_liste is array (natural range <>) of t_sequence_cache_element;
	type t_sequence_message is (
		c_idle, c_write, c_read
	);
	
    constant clk_cycle : time := 10 ns;
	
    signal clk : std_ulogic;
    signal reset : std_ulogic;
    signal numero_access_memoire : integer;
	
	signal s_cpu_ReadRequest 	: std_ulogic := '0';
	signal s_cpu_WriteRequest 	: std_ulogic := '0';
	signal s_cpu_ReadAckow		: std_ulogic;
	signal s_cpu_WriteAckow		: std_ulogic;
	signal s_cpu_Addresse		: std_ulogic_vector (31 downto 0);
	signal s_cpu_WriteData		: std_ulogic_vector (31 downto 0);
	signal s_cpu_ReadData		: std_ulogic_vector (31 downto 0);
	
	signal s_dram_ReadDataAddress	: std_ulogic_vector(31 downto 2);
	signal s_dram_ReadRequest	: std_ulogic;
	signal s_dram_WriteRequest	: std_ulogic;
	signal s_dram_WordIndexSel 	: std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	signal s_dram_ReadAck 		: std_ulogic;
    signal s_dram_writeack      : std_ulogic;
	signal s_dram_ReadDone		: std_ulogic;
	signal s_dram_ReadData		: std_ulogic_vector (31 downto 0);
	signal s_dram_WriteDataAddress	: std_ulogic_vector(31 downto 0);
	signal s_dram_WriteData		: std_ulogic_vector (31 downto 0);
	
	signal s_bram_MemRead 	: std_ulogic;
	signal s_bram_MemWrite 	: std_ulogic;
	signal s_bram_Addresse 	: std_ulogic_vector (31 downto 0);
	signal s_bram_WriteData	: std_ulogic_vector (31 downto 0);
	signal s_bram_ReadData 	: std_ulogic_vector (31 downto 0);
	
	
	
	------------------------------------------------------------------------
    -- Laboratoire 2 - partie à modifier
	-- Séquence de test pour votre cache
	------------------------------------------------------------------------
    constant maxLongueur            : integer := 127;
	signal sequence_message : t_sequence_message := c_idle;
    constant sequenceAdressesTest : t_sequence_cache_liste(0 to maxLongueur) := ( -- type défini plus haut
    --
	------------------------------------------------
	-- Format du fecteur de tests
	------------------------------------------------
    -- (mode, adresse, donnee, pause avant accès suivant)
    --
    -- Mode (0 = r/ 1 = w)
    -- Notes: 
    --      Le banc de test présume une plage mémoire valide seulement   
    --      entre 0x10010000 et 0x10010080.
    --
	------------------------------------------------
	
	
	------------------------------------------------
	-- Tests pour le plan de vérification en lecture
	------------------------------------------------
	
	-- Test L1 - lire les blocs vides - il doit y avoir 4 échecs
	('0', X"10010000", X"00000000", 0), 
	('0', X"10010008", X"00000000", 0),
	('0', X"10010010", X"00000000", 0),
	('0', X"10010018", X"00000000", 0),
	('0', X"10010020", X"00000000", 0), 
	('0', X"10010028", X"00000000", 0),
	('0', X"10010030", X"00000000", 0),
	('0', X"10010038", X"00000000", 4), -- cmpt = 8 accès
	
	-- Test L2 - lire bloc avec données valides, mais à une 
	--          adresse différente de ce que contient la cache
	('0', X"10010080", X"00000000", 0), 
	('0', X"10010088", X"00000000", 0),
	('0', X"10010090", X"00000000", 0),
	('0', X"10010098", X"00000000", 0),
	('0', X"100100A0", X"00000000", 0), 
	('0', X"100100A8", X"00000000", 0),
	('0', X"100100B0", X"00000000", 0),
	('0', X"100100B8", X"00000000", 4), -- cmpt = 8 accès
	
	-- Test L3 - demander des données déjà disponibles en cache
	('0', X"10010084", X"00000000", 0),
	('0', X"1001008C", X"00000000", 0),
	('0', X"10010094", X"00000000", 0),
	('0', X"1001009C", X"00000000", 0),
	('0', X"100100A4", X"00000000", 0),
	('0', X"100100AC", X"00000000", 0),
	('0', X"100100B4", X"00000000", 0),
	('0', X"100100BC", X"00000000", 4), -- cmpt = 8 accès
	
	-- Test P1 - 34 lectures séquentielles, puis
	--          relecture du 32e et du 1er mot.
	('0', X"10010000", X"00000000", 0), 
	('0', X"10010004", X"00000000", 0),
	('0', X"10010008", X"00000000", 0),
	('0', X"1001000C", X"00000000", 0),
	('0', X"10010010", X"00000000", 0), 
	('0', X"10010014", X"00000000", 0),
	('0', X"10010018", X"00000000", 0),
	('0', X"1001001C", X"00000000", 0),
	('0', X"10010020", X"00000000", 0), 
	('0', X"10010024", X"00000000", 0),
	('0', X"10010028", X"00000000", 0),
	('0', X"1001002C", X"00000000", 0),
	('0', X"10010030", X"00000000", 0), 
	('0', X"10010034", X"00000000", 0),
	('0', X"10010038", X"00000000", 0),
	('0', X"1001003C", X"00000000", 0),
	
	('0', X"10010040", X"00000000", 0), 
	('0', X"10010044", X"00000000", 0),
	('0', X"10010048", X"00000000", 0),
	('0', X"1001004C", X"00000000", 0),
	('0', X"10010050", X"00000000", 0), 
	('0', X"10010054", X"00000000", 0),
	('0', X"10010058", X"00000000", 0),
	('0', X"1001005C", X"00000000", 0),
	('0', X"10010060", X"00000000", 0), 
	('0', X"10010064", X"00000000", 0),
	('0', X"10010068", X"00000000", 0),
	('0', X"1001006C", X"00000000", 0),
	('0', X"10010070", X"00000000", 0), 
	('0', X"10010074", X"00000000", 0),
	('0', X"10010078", X"00000000", 0),
	('0', X"1001007C", X"00000000", 0),
	
	('0', X"10010080", X"00000000", 0), 
	('0', X"10010084", X"00000000", 0),
	
	('0', X"1001007C", X"00000000", 0),
	('0', X"10010000", X"00000000", 16), -- cmpt = 32 + 2 + 2 = 36 accès.
	
	------------------------------------------------
	-- Tests pour le plan de vérification en écriture
	------------------------------------------------
	-- Format du fecteur de tests
	------------------------------------------------
    -- (mode, adresse, donnee, pause avant accès suivant)
    --
    -- Mode (0 = r/ 1 = w)
    -- Notes: 
    --      Le banc de test présume une plage mémoire valide seulement   
    --      entre 0x10010000 et 0x10010080.
    -- En écriture, exemple:
    --  ('1', X"10010048", X"B4B46969", 4) --> écrire à l'adresse 0x10010048 la valeur 0xB4B46969, puis attendre 4 coups d'horloge
    -- Si vous ajoutez plus de 20 vecteurs de tests, augmenter "maxLongueur" à la ligne 142
	------------------------------------------------
	
	-- Test E2 - Écrire un mot dans un bloc garni d'une 
	--           plage mémoire différente de la destination 
	--           d'écriture. 

	-- Test L5 - Lire une adresse liée à un bloc garni, 
	--           mais différent de la plage mémoire enregistrée 
	--           dans le bloc.


	-- Test E3 - Écrire à une adresse accessible en cache.


	------------------------
	-- Fin de votre séquence
	------------------------
	others => ('0', X"FFFFFFFF", X"FFFFFFFF", 64)); -- for loop looks for this to call "stop"
    
    ------------------------------------------------------------------------
    -- Fin section à modifier pour laboratoire 2
	------------------------------------------------------------------------
	
begin

------------------------------------------------------------------------
-- Boucle d'exécution de la séquence
-- immite le CPU
------------------------------------------------------------------------
process
begin
	-- boucle d'e
    numero_access_memoire <= 0;
	sequence_message	<= c_idle;
	s_cpu_ReadRequest	<= '0'; 	
	s_cpu_WriteRequest 	<= '0';
	s_cpu_Addresse		<= X"00000000"; -- data memory address
	s_cpu_WriteData		<= (others => '0');
    wait for clk_cycle * 20;
	
	-- lecture avec pauses (mémoire de données)
	for x in 0 to maxLongueur-1 loop
        numero_access_memoire <= x;
		s_cpu_Addresse		<= sequenceAdressesTest(x).adresse;
		
		if(sequenceAdressesTest(x).mode = '0') then
			s_cpu_ReadRequest	<= '1'; 
			s_cpu_WriteRequest 	<= '0';	
			sequence_message	<= c_read;
		else
			s_cpu_ReadRequest	<= '0'; 
			s_cpu_WriteRequest 	<= '1';
			sequence_message	<= c_write;
			s_cpu_WriteData		<= sequenceAdressesTest(x).data;
		end if;
		
		wait for clk_cycle / 2;
		while (s_cpu_ReadAckow = '0' and s_cpu_WriteAckow = '0') loop
			wait for clk_cycle * 1;
		end loop;
		wait until clk'event and clk = '1';
		
		if(sequenceAdressesTest(x).adresse = X"FFFFFFFF" and sequenceAdressesTest(x).data = X"FFFFFFFF") then
		  wait for clk_cycle * 1;
		  stop;
		end if;
		
		if(sequenceAdressesTest(x).pause /= 0) then
			s_cpu_ReadRequest	<= '0'; 
			s_cpu_WriteRequest 	<= '0';	
			sequence_message	<= c_idle;
			wait for clk_cycle * sequenceAdressesTest(x).pause; 
		end if;
	end loop;
	
	s_cpu_ReadRequest	<= '0'; 
	s_cpu_WriteRequest 	<= '0';	
	sequence_message	<= c_idle;
	
	wait;
end process;


------------------------------------------------
-- Reset, horloge, modules et branchements
------------------------------------------------
	
-- Signal de reset
process
begin
    reset <= '1';
    wait for clk_cycle * 4;
    wait for clk_cycle / 5; -- optionnel: relâcher le reset juste après le front d'horloge
    reset <= '0';
    wait;
end process;

-- horloge
process
begin
    clk <= '1';
    loop
        wait for clk_cycle/2;
        clk <= not clk;
    end loop;
end process;


cacheLayer : CachePourDram
	Port map ( 
		clk 				=> clk,
		reset               => reset,
		i_cpu_ReadRequest 	=> s_cpu_ReadRequest,
		i_cpu_WriteRequest 	=> s_cpu_WriteRequest,
		o_cpu_ReadAckow		=> s_cpu_ReadAckow,
		o_cpu_WriteAckow	=> s_cpu_WriteAckow,
		i_cpu_Addresse		=> s_cpu_Addresse,
		i_cpu_WriteData		=> s_cpu_WriteData,
		o_cpu_ReadData		=> s_cpu_ReadData,
		
		o_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
		o_dram_ReadRequest	=> s_dram_ReadRequest,
		o_dram_WriteRequest	=> s_dram_WriteRequest,
		i_dram_WordIndexSel => s_dram_WordIndexSel,
		i_dram_ReadAck 		=> s_dram_ReadAck,
        i_dram_WriteAck 	=> s_dram_WriteAck,
		i_dram_ReadDone		=> s_dram_ReadDone,
		i_dram_ReadData		=> s_dram_ReadData,
        o_dram_WriteDataAddress	 => s_dram_WriteDataAddress,
		o_dram_WriteData	=> s_dram_WriteData
	);
	
	dramController : Dram_ModeleControlleurInterne
	generic map(
		g_BurstSize			=> 2
	)
	Port map ( 
		clk 				=> clk,
		
		i_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
        i_dram_WriteDataAddress => s_dram_WriteDataAddress,
		i_dram_ReadRequest	=> s_dram_ReadRequest,
		i_dram_WriteRequest	=> s_dram_WriteRequest,
		o_dram_WordIndexSel => s_dram_WordIndexSel,
		o_dram_ReadAck 		=> s_dram_ReadAck,
        o_dram_WriteAck 	=> s_dram_WriteAck,
		o_dram_ReadDone		=> s_dram_ReadDone,
		o_dram_ReadData		=> s_dram_ReadData,
		i_dram_WriteData	=> s_dram_WriteData,
		
		o_bram_MemRead 		=> s_bram_MemRead,
		o_bram_MemWrite 	=> s_bram_MemWrite,
		o_bram_Addresse 	=> s_bram_Addresse,
		o_bram_WriteData	=> s_bram_WriteData,
		i_bram_ReadData 	=> s_bram_ReadData 
	);
	
	memory : MemDonnees
	Port map( 
		clk 		=> clk,
		reset 		=> reset,
		i_MemRead 	=> s_bram_MemRead,
		i_MemWrite 	=> s_bram_MemWrite,
		i_Addresse 	=> s_bram_Addresse,
		i_WriteData => s_bram_WriteData,
		o_ReadData 	=> s_bram_ReadData
	);

end Behavioral;
