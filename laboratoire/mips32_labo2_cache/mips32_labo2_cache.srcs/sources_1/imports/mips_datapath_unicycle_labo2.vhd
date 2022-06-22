---------------------------------------------------------------------------------------------
--
--	Université de Sherbrooke 
--  Département de génie électrique et génie informatique
--
--	S4i - APP4 
--	
--
--	Auteurs: 		Marc-André Tétrault
--					Daniel Dalle
--					Sébastien Roy
-- 
---------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS32_package.all;


entity mips_datapath_unicycle is
generic (
	g_useInstructionMem   : boolean := true;
	g_useInstructionDram  : boolean := false;
	g_useInstructionCache : boolean := false;
	g_useDataCache 		  : boolean := false
);
Port ( 
	clk 			: in std_ulogic;
	reset 			: in std_ulogic;

	i_alu_funct   	: in std_ulogic_vector(3 downto 0);
	i_RegWrite    	: in std_ulogic;
	i_RegDst      	: in std_ulogic;
	i_MemtoReg    	: in std_ulogic;
	i_branch      	: in std_ulogic;
	i_ALUSrc      	: in std_ulogic;
	i_MemRead 		: in std_ulogic;
	i_MemWrite	  	: in std_ulogic;

	i_jump   	  	: in std_ulogic;
	i_jump_register : in std_ulogic;
	i_jump_link   	: in std_ulogic;
	i_alu_mult      : in std_ulogic;
	i_mflo          : in std_ulogic;
	i_mfhi          : in std_ulogic;
	i_SignExtend 	: in std_ulogic;

	o_InstrStall	: out std_ulogic;
	o_Instruction 	: out std_ulogic_vector (31 downto 0);
	o_PC		 	: out std_ulogic_vector (31 downto 0)
);
end mips_datapath_unicycle;

architecture Behavioral of mips_datapath_unicycle is


    component MemInstructions is
        Port ( i_addresse : in std_ulogic_vector (31 downto 0);
               o_instruction : out std_ulogic_vector (31 downto 0));
    end component;

    component MemDonnees is
    Port ( 
        clk : in std_ulogic;
        reset : in std_ulogic;
        i_MemRead 	: in std_ulogic;
        i_MemWrite : in std_ulogic;
        i_Addresse : in std_ulogic_vector (31 downto 0);
        i_WriteData : in std_ulogic_vector (31 downto 0);
        o_ReadData : out std_ulogic_vector (31 downto 0)
    );
    end component;

	component BancRegistres is
	Port ( 
		clk : in std_ulogic;
		reset : in std_ulogic;
		i_RS1 : in std_ulogic_vector (4 downto 0);
		i_RS2 : in std_ulogic_vector (4 downto 0);
		i_Wr_DAT : in std_ulogic_vector (31 downto 0);
		i_WDest : in std_ulogic_vector (4 downto 0);
		i_WE : in std_ulogic;
		o_RS1_DAT : out std_ulogic_vector (31 downto 0);
		o_RS2_DAT : out std_ulogic_vector (31 downto 0)
		);
	end component;

	component alu is
	Port ( 
		i_a			: in std_ulogic_vector (31 downto 0);
		i_b			: in std_ulogic_vector (31 downto 0);
		i_alu_funct	: in std_ulogic_vector (3 downto 0);
		i_shamt		: in std_ulogic_vector (4 downto 0);
		o_result	: out std_ulogic_vector (31 downto 0);
	    o_multRes    : out std_ulogic_vector (63 downto 0);
		o_zero		: out std_ulogic
		);
	end component;

    component Dram_ModeleControlleurInterne is
	generic (
		g_BurstSize	: integer := 2;
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
        o_dram_WriteAck     : out std_ulogic;
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
	
	component Dram_ControleExterne is
	Port ( 
		clk 				: in std_ulogic;
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
        o_dram_WriteDataAddress : out std_ulogic_vector (31 downto 0);
		o_dram_WriteData	: out std_ulogic_vector (31 downto 0)
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

	constant c_Registre31		 : std_ulogic_vector(4 downto 0) := "11111";
	signal s_zero        : std_ulogic;
	
    signal s_WriteRegDest_muxout: std_ulogic_vector(4 downto 0);
	
    signal r_PC                    : std_ulogic_vector(31 downto 0);
    signal s_PC_Suivant            : std_ulogic_vector(31 downto 0);
    signal s_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
    signal s_adresse_jump          : std_ulogic_vector(31 downto 0);
    signal s_adresse_branche       : std_ulogic_vector(31 downto 0);
    
    signal s_Instruction : std_ulogic_vector(31 downto 0);

    signal s_opcode      : std_ulogic_vector( 5 downto 0);
    signal s_RS          : std_ulogic_vector( 4 downto 0);
    signal s_RT          : std_ulogic_vector( 4 downto 0);
    signal s_RD          : std_ulogic_vector( 4 downto 0);
    signal s_shamt       : std_ulogic_vector( 4 downto 0);
    signal s_instr_funct : std_ulogic_vector( 5 downto 0);
    signal s_imm16       : std_ulogic_vector(15 downto 0);
    signal s_jump_field  : std_ulogic_vector(25 downto 0);
    signal s_reg_data1        : std_ulogic_vector(31 downto 0);
    signal s_reg_data2        : std_ulogic_vector(31 downto 0);
    signal s_AluResult             : std_ulogic_vector(31 downto 0);
    signal s_AluMultResult          : std_ulogic_vector(63 downto 0);
    
    signal s_Data2Reg_muxout       : std_ulogic_vector(31 downto 0);
    
    signal s_imm_extended          : std_ulogic_vector(31 downto 0);
    signal s_imm_extended_shifted  : std_ulogic_vector(31 downto 0);
	
    signal s_Reg_Wr_Data           : std_ulogic_vector(31 downto 0);
    signal s_MemoryReadData        : std_ulogic_vector(31 downto 0);
    signal s_AluB_data             : std_ulogic_vector(31 downto 0);
    
    -- registres spéciaux pour la multiplication
    signal r_HI             : std_ulogic_vector(31 downto 0);
    signal r_LO             : std_ulogic_vector(31 downto 0);
	
	signal s_InstructionStall	: std_ulogic;
	signal s_DataStall          : std_ulogic;
	

begin

o_PC	<= r_PC; -- permet au synthétiseur de sortir de la logique. Sinon, il enlève tout...

------------------------------------------------------------------------
-- simplification des noms de signaux et transformation des types
------------------------------------------------------------------------
s_opcode        <= s_Instruction(31 downto 26);
s_RS            <= s_Instruction(25 downto 21);
s_RT            <= s_Instruction(20 downto 16);
s_RD            <= s_Instruction(15 downto 11);
s_shamt         <= s_Instruction(10 downto  6);
s_instr_funct   <= s_Instruction( 5 downto  0);
s_imm16         <= s_Instruction(15 downto  0);
s_jump_field	<= s_Instruction(25 downto  0);
------------------------------------------------------------------------


------------------------------------------------------------------------
-- Compteur de programme et mise à jour de valeur
-- il faudra repenser comment le gérer avec s_InstructionStall et s_DataStall
------------------------------------------------------------------------
process(clk)
begin
    if(clk'event and clk = '1') then
        if(reset = '1') then
            r_PC <= X"00400000";
        else
            r_PC <= s_PC_Suivant;
        end if;
    end if;
end process;


s_adresse_PC_plus_4				<= std_ulogic_vector(unsigned(r_PC) + 4);
s_adresse_jump					<= s_adresse_PC_plus_4(31 downto 28) & s_jump_field & "00";
s_imm_extended_shifted			<= s_imm_extended(29 downto 0) & "00";
s_adresse_branche				<= std_ulogic_vector(unsigned(s_imm_extended_shifted) + unsigned(s_adresse_PC_plus_4));

-- note, "i_jump_register" n'est pas dans les figures de COD5
s_PC_Suivant		<= r_PC              when s_InstructionStall = '1' else
                       s_adresse_jump    when i_jump = '1' else
                       s_reg_data1       when i_jump_register = '1' else
					   s_adresse_branche when (i_branch = '1' and s_zero = '1') else
					   s_adresse_PC_plus_4;
					   

------------------------------------------------------------------------
-- Mémoire d'instructions
------------------------------------------------------------------------
o_InstrStall <= s_InstructionStall;

MemInstructionsSRAM: if (g_useInstructionMem = true) generate
begin
	inst_MemInstr: MemInstructions
	Port map ( 
		i_addresse => r_PC,
		o_instruction => s_Instruction
		);
		
	s_InstructionStall <= '0';
end generate;


MemInstructionsDRAM: if (g_useInstructionDram = true) generate
	signal s_dram_ReadDataAddress	: std_ulogic_vector(31 downto 2);
	signal s_dram_WriteDataAddress	: std_ulogic_vector(31 downto 0);
	signal s_dram_ReadRequest	: std_ulogic;
	signal s_dram_WriteRequest	: std_ulogic;
	signal s_dram_WordIndexSel 	: std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	signal s_dram_ReadAck 		: std_ulogic;
	signal s_dram_WriteAck 		: std_ulogic;
	signal s_dram_ReadDone		: std_ulogic;
	signal s_dram_ReadData		: std_ulogic_vector (31 downto 0);
	signal s_dram_WriteData		: std_ulogic_vector (31 downto 0);
	
	signal s_bram_MemRead 	: std_ulogic;
	signal s_bram_MemWrite 	: std_ulogic;
	signal s_bram_Addresse 	: std_ulogic_vector (31 downto 0);
	signal s_bram_WriteData	: std_ulogic_vector (31 downto 0);
	signal s_bram_ReadData 	: std_ulogic_vector (31 downto 0);
		
	signal s_cpu_ReadAckow	: std_ulogic;
begin
	inst_DramControl : Dram_ControleExterne
	Port map ( 
		clk 				=> clk,
		i_cpu_ReadRequest 	=> '1',
		i_cpu_WriteRequest 	=> '0',
		o_cpu_ReadAckow		=> s_cpu_ReadAckow,
		o_cpu_WriteAckow	=> open,
		i_cpu_Addresse		=> r_PC,
		i_cpu_WriteData		=> (others => '0'),
		o_cpu_ReadData		=> s_Instruction,
		
		o_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
		o_dram_ReadRequest	    => s_dram_ReadRequest,
		o_dram_WriteRequest	    => s_dram_WriteRequest,
		i_dram_WordIndexSel     => s_dram_WordIndexSel,
		i_dram_ReadAck 		    => s_dram_ReadAck,
        i_dram_WriteAck         => s_dram_WriteAck,
		i_dram_ReadDone		    => s_dram_ReadDone,
		i_dram_ReadData		    => s_dram_ReadData,
        o_dram_WriteDataAddress => s_dram_WriteDataAddress,
		o_dram_WriteData	    => s_dram_WriteData
	);
	
	s_InstructionStall <= not s_cpu_ReadAckow;
	
	inst_DramModel : Dram_ModeleControlleurInterne
	generic map(
		g_BurstSize			=> 2,
	    g_TotalDelay        => 5
	)
	Port map ( 
		clk 				=> clk,
		
		i_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
        i_dram_WriteDataAddress	=> s_dram_WriteDataAddress,
		i_dram_ReadRequest	    => s_dram_ReadRequest,
		i_dram_WriteRequest	    => s_dram_WriteRequest,
		o_dram_WordIndexSel     => s_dram_WordIndexSel,
		o_dram_ReadAck 		    => s_dram_ReadAck,
        o_dram_WriteAck         => s_dram_WriteAck,
		o_dram_ReadDone		    => s_dram_ReadDone,
		o_dram_ReadData		    => s_dram_ReadData,
		i_dram_WriteData	    => s_dram_WriteData,
		
		o_bram_MemRead 		=> s_bram_MemRead,
		o_bram_MemWrite 	=> s_bram_MemWrite,
		o_bram_Addresse 	=> s_bram_Addresse,
		o_bram_WriteData	=> s_bram_WriteData,
		i_bram_ReadData 	=> s_bram_ReadData 
	);
	
	inst_MemInstr: MemInstructions
	Port map ( 
		i_addresse => s_bram_Addresse,
		o_instruction => s_bram_ReadData
		);
end generate;


MemInstructionsCache: if (g_useInstructionCache = true) generate	
	signal s_dram_ReadDataAddress	: std_ulogic_vector(31 downto 2);
	signal s_dram_WriteDataAddress	: std_ulogic_vector(31 downto 0);
	signal s_dram_ReadRequest	: std_ulogic;
	signal s_dram_WriteRequest	: std_ulogic;
	signal s_dram_WordIndexSel 	: std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	signal s_dram_ReadAck 		: std_ulogic;
	signal s_dram_WriteAck 		: std_ulogic;
	signal s_dram_ReadDone		: std_ulogic;
	signal s_dram_ReadData		: std_ulogic_vector (31 downto 0);
	signal s_dram_WriteData		: std_ulogic_vector (31 downto 0);
	
	signal s_bram_MemRead 	: std_ulogic;
	signal s_bram_MemWrite 	: std_ulogic;
	signal s_bram_Addresse 	: std_ulogic_vector (31 downto 0);
	signal s_bram_WriteData	: std_ulogic_vector (31 downto 0);
	signal s_bram_ReadData 	: std_ulogic_vector (31 downto 0);
	
	signal s_cpu_ReadAckow	: std_ulogic;
begin
	inst_CachePourDram : CachePourDram
	Port map ( 
		clk 				=> clk,
		reset 				=> reset,
		i_cpu_ReadRequest 	=> '1',
		i_cpu_WriteRequest 	=> '0',
		o_cpu_ReadAckow		=> s_cpu_ReadAckow,
		o_cpu_WriteAckow	=> open,
		i_cpu_Addresse		=> r_PC,
		i_cpu_WriteData		=> (others => '0'),
		o_cpu_ReadData		=> s_Instruction,
		
		o_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
		o_dram_ReadRequest	    => s_dram_ReadRequest,
		o_dram_WriteRequest	    => s_dram_WriteRequest,
		i_dram_WordIndexSel     => s_dram_WordIndexSel,
		i_dram_ReadAck 		    => s_dram_ReadAck,
        i_dram_WriteAck 	    => s_dram_WriteAck,
		i_dram_ReadDone		    => s_dram_ReadDone,
		i_dram_ReadData		    => s_dram_ReadData,
        o_dram_WriteDataAddress => s_dram_WriteDataAddress,
		o_dram_WriteData	    => s_dram_WriteData
	);
	
	s_InstructionStall <= not s_cpu_ReadAckow;
	
	inst_DramModel : Dram_ModeleControlleurInterne
	generic map(
		g_BurstSize			=> 2,
	    g_TotalDelay        => 5
	)
	Port map ( 
		clk 				=> clk,
        
		i_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
        i_dram_WriteDataAddress	=> s_dram_WriteDataAddress,
		i_dram_ReadRequest	    => s_dram_ReadRequest,
		i_dram_WriteRequest	    => s_dram_WriteRequest,
		o_dram_WordIndexSel     => s_dram_WordIndexSel,
		o_dram_ReadAck 		    => s_dram_ReadAck,
        o_dram_WriteAck 	    => s_dram_WriteAck,
		o_dram_ReadDone		    => s_dram_ReadDone,
		o_dram_ReadData		    => s_dram_ReadData,
		i_dram_WriteData	    => s_dram_WriteData,
		
		o_bram_MemRead 		=> s_bram_MemRead,
		o_bram_MemWrite 	=> s_bram_MemWrite,
		o_bram_Addresse 	=> s_bram_Addresse,
		o_bram_WriteData	=> s_bram_WriteData,
		i_bram_ReadData 	=> s_bram_ReadData 
	);
	
	inst_MemInstr: MemInstructions
	Port map ( 
		i_addresse => s_bram_Addresse,
		o_instruction => s_bram_ReadData
		);
end generate;


-- branchement vers le décodeur d'instructions
o_instruction <= s_Instruction;
	
------------------------------------------------------------------------
-- Banc de Registres
------------------------------------------------------------------------
-- Multiplexeur pour le registre en écriture
s_WriteRegDest_muxout <= c_Registre31 when i_jump_link = '1' else 
                         s_rt         when i_RegDst = '0' else 
						 s_rd;
       
inst_Registres: BancRegistres 
port map ( 
	clk          => clk,
	reset        => reset,
	i_RS1        => s_rs,
	i_RS2        => s_rt,
	i_Wr_DAT     => s_Data2Reg_muxout,
	i_WDest      => s_WriteRegDest_muxout,
	i_WE         => i_RegWrite,
	o_RS1_DAT    => s_reg_data1,
	o_RS2_DAT    => s_reg_data2
	);
	

------------------------------------------------------------------------
-- ALU (instance, extension de signe et mux d'entrée pour les immédiats)
------------------------------------------------------------------------
-- extension de signe
s_imm_extended <= std_ulogic_vector(resize(  signed(s_imm16),32)) when i_SignExtend = '1' else -- extension de signe à 32 bits
				  std_ulogic_vector(resize(unsigned(s_imm16),32)); 

-- Mux pour immédiats
s_AluB_data <= s_reg_data2 when i_ALUSrc = '0' else s_imm_extended;

inst_Alu: alu 
port map( 
	i_a         => s_reg_data1,
	i_b         => s_AluB_data,
	i_alu_funct => i_alu_funct,
	i_shamt     => s_shamt,
	o_result    => s_AluResult,
	o_multRes   => s_AluMultResult,
	o_zero      => s_zero
	);

------------------------------------------------------------------------
-- Mémoire de données
------------------------------------------------------------------------
MemDonneesSRAM: if (g_useDataCache = false) generate
begin
	inst_MemDonnees : MemDonnees
    Port map( 
        clk 		=> clk,
        reset 		=> reset,
        i_MemRead	=> i_MemRead,
        i_MemWrite	=> i_MemWrite,
        i_Addresse	=> s_AluResult,
        i_WriteData => s_reg_data2,
        o_ReadData	=> s_MemoryReadData
        );
        
    s_DataStall <= '0';
end generate;

MemDonneesCache: if (g_useDataCache = true) generate
	signal s_dram_ReadDataAddress	: std_ulogic_vector(31 downto 2);
	signal s_dram_WriteDataAddress	: std_ulogic_vector(31 downto 0);
	signal s_dram_ReadRequest	: std_ulogic;
	signal s_dram_WriteRequest	: std_ulogic;
	signal s_dram_WordIndexSel 	: std_ulogic_vector(2 downto 0); -- supports bursts of 2, 4 and 8 words, and single words
	signal s_dram_ReadAck 		: std_ulogic;
	signal s_dram_WriteAck 		: std_ulogic;
	signal s_dram_ReadDone		: std_ulogic;
	signal s_dram_ReadData		: std_ulogic_vector (31 downto 0);
	signal s_dram_WriteData		: std_ulogic_vector (31 downto 0);
	
	signal s_bram_MemRead 	: std_ulogic;
	signal s_bram_MemWrite 	: std_ulogic;
	signal s_bram_Addresse 	: std_ulogic_vector (31 downto 0);
	signal s_bram_WriteData	: std_ulogic_vector (31 downto 0);
	signal s_bram_ReadData 	: std_ulogic_vector (31 downto 0);
	
	signal s_cpu_ReadAckow	: std_ulogic;
	signal s_cpu_WriteAckow	: std_ulogic;
begin

    s_DataStall <= (i_MemRead and not s_cpu_ReadAckow) or (i_MemWrite and not s_cpu_WriteAckow);
        
	inst_CachePourDram : CachePourDram
	Port map ( 
		clk 				=> clk,
		reset               => reset,
		i_cpu_ReadRequest 	=> i_MemRead,
		i_cpu_WriteRequest 	=> i_MemWrite,
		o_cpu_ReadAckow		=> s_cpu_ReadAckow,
		o_cpu_WriteAckow	=> s_cpu_WriteAckow,
		i_cpu_Addresse		=> s_AluResult,
		i_cpu_WriteData		=> s_reg_data2,
		o_cpu_ReadData		=> s_MemoryReadData,
		
		o_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
		o_dram_ReadRequest	    => s_dram_ReadRequest,
		o_dram_WriteRequest	    => s_dram_WriteRequest,
		i_dram_WordIndexSel     => s_dram_WordIndexSel,
		i_dram_ReadAck 		    => s_dram_ReadAck,
        i_dram_WriteAck 	    => s_dram_WriteAck,
		i_dram_ReadDone		    => s_dram_ReadDone,
		i_dram_ReadData		    => s_dram_ReadData,
        o_dram_WriteDataAddress => s_dram_WriteDataAddress,
		o_dram_WriteData	    => s_dram_WriteData
	);
	
	inst_DramModel : Dram_ModeleControlleurInterne
	generic map(
		g_BurstSize			=> 2,
	    g_TotalDelay        => 5
	)
	Port map ( 
		clk 				=> clk,
		
		i_dram_ReadDataAddress	=> s_dram_ReadDataAddress,
        i_dram_WriteDataAddress	=> s_dram_WriteDataAddress,
		i_dram_ReadRequest	    => s_dram_ReadRequest,
		i_dram_WriteRequest	    => s_dram_WriteRequest,
		o_dram_WordIndexSel     => s_dram_WordIndexSel,
		o_dram_ReadAck 		    => s_dram_ReadAck,
        o_dram_WriteAck 	    => s_dram_WriteAck,
		o_dram_ReadDone		    => s_dram_ReadDone,
		o_dram_ReadData		    => s_dram_ReadData,
		i_dram_WriteData	    => s_dram_WriteData,
		
		o_bram_MemRead 		=> s_bram_MemRead,
		o_bram_MemWrite 	=> s_bram_MemWrite,
		o_bram_Addresse 	=> s_bram_Addresse,
		o_bram_WriteData	=> s_bram_WriteData,
		i_bram_ReadData 	=> s_bram_ReadData 
	);
	
	inst_MemDonnees : MemDonnees
    Port map( 
        clk 		=> clk,
        reset 		=> reset,
        i_MemRead	=> s_bram_MemRead,
        i_MemWrite	=> s_bram_MemWrite,
        i_Addresse	=> s_bram_Addresse,
        i_WriteData => s_bram_WriteData,
        o_ReadData	=> s_bram_ReadData
        );
end generate;

------------------------------------------------------------------------
-- Mux d'écriture vers le banc de registres
------------------------------------------------------------------------

s_Data2Reg_muxout    <= s_adresse_PC_plus_4 when i_jump_link = '1' else
					    r_HI                when i_mfhi = '1' else 
					    r_LO                when i_mflo = '1' else
					    s_AluResult         when i_MemtoReg = '0' else 
						s_MemoryReadData;


		
------------------------------------------------------------------------
-- Registres spéciaux pour la multiplication
------------------------------------------------------------------------				
process(clk)
begin
    if(clk'event and clk = '1') then
        if(i_alu_mult = '1') then
            r_HI <= s_AluMultResult(63 downto 32);
            r_LO <= s_AluMultResult(31 downto 0);
        end if;
    end if;
end process;
        
end Behavioral;
