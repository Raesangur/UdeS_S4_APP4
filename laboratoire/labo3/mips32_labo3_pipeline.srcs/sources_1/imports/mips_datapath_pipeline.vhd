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


entity mips_datapath_pipeline is
Port ( 
	clk 			: in std_ulogic;
	reset 			: in std_ulogic;

	i_alu_funct   	: in std_ulogic_vector(3 downto 0);
	i_RegWrite    	: in std_ulogic;
	i_RegDst      	: in std_ulogic;
	i_MemtoReg    	: in std_ulogic;
	i_branch      	: in std_ulogic;
	i_ALUSrc      	: in std_ulogic;
	i_MemRead		: in std_ulogic;
	i_MemWrite	  	: in std_ulogic;

	i_jump   	  	: in std_ulogic;
	i_jump_register : in std_ulogic;
	i_jump_link   	: in std_ulogic;
	i_SignExtend 	: in std_ulogic;

	o_Instruction 		: out std_ulogic_vector (31 downto 0);
	o_PC		 		: out std_ulogic_vector (31 downto 0)
);
end mips_datapath_pipeline;

architecture Behavioral of mips_datapath_pipeline is


	component MemInstructions is
		Port ( i_addresse : in std_ulogic_vector (31 downto 0);
			   o_instruction : out std_ulogic_vector (31 downto 0));
	end component;

	component MemDonnees is
	Port ( 
		clk			: in std_ulogic;
		reset		: in std_ulogic;
		i_MemRead	: in std_ulogic;
		i_MemWrite	: in std_ulogic;
		i_Addresse	: in std_ulogic_vector (31 downto 0);
		i_WriteData	: in std_ulogic_vector (31 downto 0);
		o_ReadData	: out std_ulogic_vector (31 downto 0)
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
		o_zero		: out std_ulogic
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
    signal r_IF_ID_Instruction    : std_ulogic_vector(31 downto 0);
    signal r_IF_ID_opcode         : std_ulogic_vector( 5 downto 0);
    signal r_IF_ID_rs             : std_ulogic_vector( 4 downto 0);
    signal r_IF_ID_rt             : std_ulogic_vector( 4 downto 0);
    signal r_IF_ID_rd             : std_ulogic_vector( 4 downto 0);
    signal r_IF_ID_shamt          : std_ulogic_vector( 4 downto 0);
    signal r_IF_ID_instr_funct    : std_ulogic_vector( 5 downto 0);
    signal r_IF_ID_imm16          : std_ulogic_vector(15 downto 0);
    signal r_IF_ID_jump_field     : std_ulogic_vector(25 downto 0);
    signal s_reg_data1        : std_ulogic_vector(31 downto 0);
    signal s_reg_data2        : std_ulogic_vector(31 downto 0);
    signal s_AluResult             : std_ulogic_vector(31 downto 0);
    
    signal s_Data2Reg_muxout       : std_ulogic_vector(31 downto 0);
    
    signal s_IF_ID_imm_extended          : std_ulogic_vector(31 downto 0);
    signal s_EX_MEM_imm_extended_shifted  : std_ulogic_vector(31 downto 0);
	
    signal s_Reg_Wr_Data           : std_ulogic_vector(31 downto 0);
    signal s_MemoryReadData        : std_ulogic_vector(31 downto 0);
    signal s_AluA_data             : std_ulogic_vector(31 downto 0);
    signal s_AluB_data             : std_ulogic_vector(31 downto 0);
	
	
	
	
	signal s_Flush					  : std_ulogic; 
	signal s_InsertBubble			  : std_ulogic;
	
	-- Registres étage EX
	-- Contrôles
	-- ID stage
	signal r_IF_ID_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
	-- EX stage endpoint
	signal r_ID_EX_alu_funct   	: std_ulogic_vector(3 downto 0);
	signal r_ID_EX_ALUSrc      	: std_ulogic;
	signal r_ID_EX_RegDst      	: std_ulogic;
	-- MEM stage endpoint
	signal r_ID_EX_branch      	: std_ulogic;
	signal r_ID_EX_MemRead		  	: std_ulogic;
	signal r_ID_EX_MemWrite	  	: std_ulogic;
	signal r_ID_EX_jump   	  		: std_ulogic;
	signal r_ID_EX_jump_register 	: std_ulogic;
    signal r_ID_EX_jump_field      : std_ulogic_vector(25 downto 0);
	-- WB stage endpoint
	signal r_ID_EX_jump_link   	: std_ulogic;
	signal r_ID_EX_RegWrite    	: std_ulogic;
	signal r_ID_EX_MemtoReg    	: std_ulogic;
    signal r_ID_EX_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
	
	-- Signaux générés
    signal r_ID_EX_imm_extended    : std_ulogic_vector(31 downto 0);
	signal r_ID_EX_reg_data1		: std_ulogic_vector(31 downto 0);
	signal r_ID_EX_reg_data2		: std_ulogic_vector(31 downto 0);
	signal r_ID_EX_rs				: std_ulogic_vector(4 downto 0);
	signal r_ID_EX_rt				: std_ulogic_vector(4 downto 0);
	signal r_ID_EX_rd				: std_ulogic_vector(4 downto 0);
	signal r_ID_EX_shamt			: std_ulogic_vector(4 downto 0);
	
	-- Registres étage MEM
	-- MEM stage endpoint
	signal r_EX_MEM_branch      	: std_ulogic;
	signal r_EX_MEM_MemRead	  	: std_ulogic;
	signal r_EX_MEM_MemWrite	  	: std_ulogic;
	signal r_EX_MEM_jump   	  	: std_ulogic;
	signal r_EX_MEM_jump_register 	: std_ulogic;
    signal r_EX_MEM_jump_field     : std_ulogic_vector(25 downto 0);
	-- WB stage endpoint
	signal r_EX_MEM_jump_link   	: std_ulogic;
	signal r_EX_MEM_RegWrite    	: std_ulogic;
	signal r_EX_MEM_MemtoReg    	: std_ulogic;
    signal r_EX_MEM_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
	
	
	-- Signaux générés
    signal r_EX_MEM_imm_extended          : std_ulogic_vector(31 downto 0);
    signal r_EX_MEM_imm_extended_shifted  : std_ulogic_vector(31 downto 0);
	signal r_EX_MEM_AluResult				   : std_ulogic_vector(31 downto 0);
	signal r_EX_MEM_zero					: std_ulogic;
	signal r_EX_MEM_reg_data1			      : std_ulogic_vector(31 downto 0);
	signal r_EX_MEM_reg_data2			      : std_ulogic_vector(31 downto 0);
	signal r_EX_MEM_RegisterRd	: std_ulogic_vector(4 downto 0);
	
	-- Registres étage MEM
	-- WB stage endpoint
	signal r_MEM_WB_jump_link	 	: std_ulogic;
	signal r_MEM_WB_RegWrite    	: std_ulogic;
	signal r_MEM_WB_MemtoReg    	: std_ulogic;
    signal r_MEM_WB_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
	signal r_MEM_WB_AluResult			      : std_ulogic_vector(31 downto 0);
	signal r_MEM_WB_MemoryReadData			      : std_ulogic_vector(31 downto 0);
	signal r_MEM_WB_RegisterRd	: std_ulogic_vector(4 downto 0);
	
	-- forwarding unit
	signal s_forwardA : std_ulogic_vector(1 downto 0);
	signal s_forwardB : std_ulogic_vector(1 downto 0);
	
	
	
begin

o_PC	<= r_PC; -- permet au synthétiseur de sortir de la logique. Sinon, il enlève tout...

------------------------------------------------------------------------
-- simplification des noms de signaux et transformation des types
------------------------------------------------------------------------
r_IF_ID_opcode        <= r_IF_ID_Instruction(31 downto 26);
r_IF_ID_RS            <= r_IF_ID_Instruction(25 downto 21);
r_IF_ID_RT            <= r_IF_ID_Instruction(20 downto 16);
r_IF_ID_RD            <= r_IF_ID_Instruction(15 downto 11);
r_IF_ID_shamt         <= r_IF_ID_Instruction(10 downto  6);
r_IF_ID_instr_funct   <= r_IF_ID_Instruction( 5 downto  0);
r_IF_ID_imm16         <= r_IF_ID_Instruction(15 downto  0);
r_IF_ID_jump_field	  <= r_IF_ID_Instruction(25 downto  0);
------------------------------------------------------------------------


------------------------------------------------------------------------
-- Compteur de programme et mise à jour de valeur
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
s_adresse_jump					<= r_EX_MEM_adresse_PC_plus_4(31 downto 28) & r_EX_MEM_jump_field & "00";
s_EX_MEM_imm_extended_shifted	<= r_EX_MEM_imm_extended(29 downto 0) & "00";
s_adresse_branche				<= std_ulogic_vector(unsigned(s_EX_MEM_imm_extended_shifted) + unsigned(r_EX_MEM_adresse_PC_plus_4));

-- note, "i_jump_register" n'est pas dans les figures de COD5
s_PC_Suivant		<= s_adresse_jump when r_EX_MEM_jump = '1' else
                       r_EX_MEM_reg_data1 when r_EX_MEM_jump_register = '1' else 
					   s_adresse_branche when (r_EX_MEM_branch = '1' and r_EX_MEM_zero = '1') else
					   -- ??? when s_InsertBubble = '1' else
					   s_adresse_PC_plus_4;

s_Flush				<= '0'; -- optionnel, après le déplacement des branches
s_InsertBubble		<= '0'; -- optionnel, pour le lw après l'ajout de l'unité d'avancement

------------------------------------------------------------------------
-- Mémoire d'instructions
------------------------------------------------------------------------
inst_MemInstr: MemInstructions
Port map ( 
	i_addresse => r_PC,
    o_instruction => s_Instruction
    );

-- branchement vers le décodeur d'instructions
o_instruction <= r_IF_ID_Instruction;
	
------------------------------------------------------------------------
-- Banc de Registres
------------------------------------------------------------------------
-- Multiplexeur pour le registre en écriture, voir COD5 figure 4.56
s_WriteRegDest_muxout <= c_Registre31 when r_ID_EX_jump_link = '1' else 
                         r_ID_EX_rt      when r_ID_EX_RegDst = '0' else 
						 r_ID_EX_rd;
       
inst_Registres: BancRegistres 
port map ( 
	clk          => clk,
	reset        => reset,
	i_RS1        => r_IF_ID_rs,
	i_RS2        => r_IF_ID_rt,
	i_Wr_DAT     => s_Data2Reg_muxout,
	i_WDest      => r_MEM_WB_RegisterRd,
	i_WE         => r_MEM_WB_RegWrite,
	o_RS1_DAT    => s_reg_data1,
	o_RS2_DAT    => s_reg_data2
	);
	

------------------------------------------------------------------------
-- ALU (instance, extension de signe et mux d'entrée pour les immédiats)
------------------------------------------------------------------------
s_forwardA <= "10" when  (r_EX_MEM_RegWrite = '1') and
                         (r_EX_MEM_RegisterRd /= "00000") and
                         (r_EX_MEM_RegisterRd = r_ID_EX_rs) 
                         else
                         "01" when
                         (r_MEM_WB_RegWrite = '1') and
                         (r_MEM_WB_RegisterRd /= "00000") and 
                         --not ((r_EX_MEM_RegWrite = '1') and (r_EX_MEM_RegisterRd /= "00000")) and
                         --(r_EX_MEM_RegisterRd /= r_ID_EX_rs) and
                         (r_MEM_WB_RegisterRd = r_ID_EX_rs)
                         else "00";

s_forwardB <= "10" when (r_EX_MEM_RegWrite = '1') and
                        (r_EX_MEM_RegisterRd /= "00000") and
                        (r_EX_MEM_RegisterRd = r_ID_EX_rt) 
                         else
                         "01" when
                        (r_MEM_WB_RegWrite = '1') and
                        (r_MEM_WB_RegisterRd /= "00000") and
                        --not ((r_EX_MEM_RegWrite = '1') and (r_EX_MEM_RegisterRd /= "00000")) and
                        --(r_EX_MEM_RegisterRd /= r_ID_EX_rt) and
                        (r_MEM_WB_RegisterRd = r_ID_EX_rt) else "00";
                    
                    
                    


-- extension de signe
s_IF_ID_imm_extended <= std_ulogic_vector(resize(  signed(r_IF_ID_imm16),32)) when i_SignExtend = '1' else -- extension de signe à 32 bits
				  std_ulogic_vector(resize(unsigned(r_IF_ID_imm16),32)); 


s_AluA_data <=  s_Data2Reg_muxout  when s_forwardA = "01" else
                r_EX_MEM_AluResult when s_forwardA = "10" else
                r_ID_EX_reg_data1; 

-- Mux pour immédiats
s_AluB_data <=  r_ID_EX_imm_extended when r_ID_EX_ALUSrc = '1' else
                s_Data2Reg_muxout  when s_forwardB = "01"      else
                r_EX_MEM_AluResult when s_forwardB = "10"      else
                r_ID_EX_reg_data2;

inst_Alu: alu 
port map( 
	i_a         => s_AluA_data,
	i_b         => s_AluB_data,
	i_alu_funct => r_ID_EX_alu_funct,
	i_shamt     => r_ID_EX_shamt,
	o_result    => s_AluResult,
	o_zero      => s_zero
	);

------------------------------------------------------------------------
-- Mémoire de données
------------------------------------------------------------------------
inst_MemDonnees : MemDonnees
Port map( 
	clk => clk,
	reset => reset,
	i_MemRead	=> r_EX_MEM_MemRead,
	i_MemWrite	=> r_EX_MEM_MemWrite,
    i_Addresse	=> r_EX_MEM_AluResult,
	i_WriteData => r_EX_MEM_reg_data2,
    o_ReadData 	=> s_MemoryReadData
	);
	

------------------------------------------------------------------------
-- Mux d'écriture vers le banc de registres
------------------------------------------------------------------------

s_Data2Reg_muxout    <= r_MEM_WB_adresse_PC_plus_4 when r_MEM_WB_jump_link = '1' else
					    r_MEM_WB_AluResult         when r_MEM_WB_MemtoReg = '0' else 
						r_MEM_WB_MemoryReadData;
						
						
						
						
------------------------------------------------------------------------
-- Registres de pipeline
------------------------------------------------------------------------

IF_ID_Instruction : process ( clk )
begin
    if(clk'event and clk = '1') then
		r_IF_ID_adresse_PC_plus_4     <= s_adresse_PC_plus_4;
		
		if(reset = '1') then
			r_IF_ID_Instruction <= c_Mips32_Nop;
		-- modifications optionelles au labo 3
		--elsif(s_Flush = '1') then
		--	r_IF_ID_Instruction <= c_Mips32_Flush; -- idem à nop, variante pour faciliter l'affichage
		--elsif(s_InsertBubble = '1') then
		--	r_IF_ID_Instruction <= r_IF_ID_Instruction; -- bulle dans l'étage suivant, il faut conserver l'opération entretemps.
														-- la bulle sera ajoutée "par magie" dans le monitor
		else
			r_IF_ID_Instruction <= s_Instruction;
		end if;
		
    end if;
end process IF_ID_Instruction;						

ID_EX_Controles : process ( clk )
begin
    if(clk'event and clk = '1') then
		-- Optionnel: décommenter ce code si vous ajoutez l'insertion de bulle (pour l'aléa du lw)
		--if(s_InsertBubble = '1') then
			-- r_ID_EX_alu_funct   	<= (others => '0');
			-- r_ID_EX_ALUSrc      	<= '0';
			-- r_ID_EX_RegDst      	<= '0';
			-- r_ID_EX_branch      	<= '0';
			-- r_ID_EX_MemRead	  	<= '0';
			-- r_ID_EX_MemWrite	  	<= '0';
			-- r_ID_EX_jump   	  	<= '0';
			-- r_ID_EX_jump_register 	<= '0';
			-- r_ID_EX_jump_link   	<= '0';
			-- r_ID_EX_RegWrite    	<= '0';
			-- r_ID_EX_MemtoReg    	<= '0';
			
			-- r_ID_EX_adresse_PC_plus_4  <= (others => '0');
			-- r_ID_EX_jump_field			<= (others => '0');
			-- r_ID_EX_imm_extended		<= (others => '0');
			-- r_ID_EX_reg_data1			<= (others => '0');
			-- r_ID_EX_reg_data2			<= (others => '0');
			
			-- r_ID_EX_rs				<= (others => '0');
			-- r_ID_EX_rt				<= (others => '0');
			-- r_ID_EX_rd				<= (others => '0');
			-- r_ID_EX_shamt			<= (others => '0');
		--else
			r_ID_EX_alu_funct   	<= i_alu_funct;
			r_ID_EX_ALUSrc      	<= i_ALUSrc;
			r_ID_EX_RegDst      	<= i_RegDst;
			r_ID_EX_branch      	<= i_branch;
			r_ID_EX_MemRead	  		<= i_MemRead;
			r_ID_EX_MemWrite	  	<= i_MemWrite;
			r_ID_EX_jump   	  		<= i_jump;
			r_ID_EX_jump_register 	<= i_jump_register;
			r_ID_EX_jump_link   	<= i_jump_link;
			r_ID_EX_RegWrite    	<= i_RegWrite;
			r_ID_EX_MemtoReg    	<= i_MemtoReg;
			
			r_ID_EX_adresse_PC_plus_4  <= r_IF_ID_adresse_PC_plus_4;
			r_ID_EX_jump_field			<= r_IF_ID_jump_field;
			r_ID_EX_imm_extended		<= s_IF_ID_imm_extended;
			r_ID_EX_reg_data1			<= s_reg_data1;
			r_ID_EX_reg_data2			<= s_reg_data2;
			
			r_ID_EX_rs				<= r_IF_ID_rs;
			r_ID_EX_rt				<= r_IF_ID_rt;
			r_ID_EX_rd				<= r_IF_ID_rd;
			r_ID_EX_shamt			<= r_IF_ID_shamt;
		-- end if;
    end if;
end process ID_EX_Controles;	

EX_MEM_Controles : process ( clk )
begin
    if(clk'event and clk = '1') then
		r_EX_MEM_branch      	<= r_ID_EX_branch      	;
		r_EX_MEM_MemRead	  	<= r_ID_EX_MemRead	  	;
		r_EX_MEM_MemWrite	  	<= r_ID_EX_MemWrite	  	;
		r_EX_MEM_jump   	  	<= r_ID_EX_jump   	  	;
		r_EX_MEM_jump_register <= r_ID_EX_jump_register ;
		r_EX_MEM_jump_link   	<= r_ID_EX_jump_link;
		r_EX_MEM_RegWrite    	<= r_ID_EX_RegWrite    	;
		r_EX_MEM_MemtoReg    	<= r_ID_EX_MemtoReg    	;
		r_EX_MEM_adresse_PC_plus_4	<= r_ID_EX_adresse_PC_plus_4;
		r_EX_MEM_jump_field	<= r_ID_EX_jump_field;
		
		r_EX_MEM_reg_data1				<= r_ID_EX_reg_data1; -- for JR
		r_EX_MEM_reg_data2				<= r_ID_EX_reg_data2; -- for MEM Write
		r_EX_MEM_AluResult				<= s_AluResult;
		r_EX_MEM_zero					<= s_zero;
		r_EX_MEM_RegisterRd             <= s_WriteRegDest_muxout;
		r_EX_MEM_imm_extended			<= r_ID_EX_imm_extended;
    end if;
end process EX_MEM_Controles;

MEM_WB_Controles : process ( clk )
begin
    if(clk'event and clk = '1') then
		r_MEM_WB_jump_link	 	 <= r_EX_MEM_jump_link;
		r_MEM_WB_RegWrite    	 <= r_EX_MEM_RegWrite    	;
		r_MEM_WB_MemtoReg    	 <= r_EX_MEM_MemtoReg    	;
		r_MEM_WB_adresse_PC_plus_4	<= r_EX_MEM_adresse_PC_plus_4;
		r_MEM_WB_MemoryReadData	 <= s_MemoryReadData;
		r_MEM_WB_AluResult		 <= r_EX_MEM_AluResult;
		r_MEM_WB_RegisterRd      <= r_EX_MEM_RegisterRd;
    end if;
end process MEM_WB_Controles;


end Behavioral;
