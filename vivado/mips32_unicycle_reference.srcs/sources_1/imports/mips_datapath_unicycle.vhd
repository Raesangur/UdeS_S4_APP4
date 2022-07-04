---------------------------------------------------------------------------------------------
--
--	Universit� de Sherbrooke 
--  D�partement de g�nie �lectrique et g�nie informatique
--
--	S4i - APP4 
--	
--
--	Auteurs: 		Marc-Andr� T�trault
--					Daniel Dalle
--					S�bastien Roy
-- 
---------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS32_package.all;


entity mips_datapath_unicycle is
Port ( 
	clk 			: in std_ulogic;
	reset 			: in std_ulogic;

	i_alu_funct   	: in std_ulogic_vector(4 downto 0);
	i_RegWrite    	: in std_ulogic;
	i_RegDst      	: in std_ulogic;
	i_MemtoReg    	: in std_ulogic;
	i_branch      	: in std_ulogic;
	i_ALUSrc      	: in std_ulogic;
	i_MemRead 		: in std_ulogic;
	i_MemWrite	  	: in std_ulogic;
	i_vect          : in std_ulogic;
	i_CmpWrite      : in std_ulogic;

	i_jump   	  	: in std_ulogic;
	i_jump_register : in std_ulogic;
	i_jump_link   	: in std_ulogic;
	i_alu_mult      : in std_ulogic;
	i_mflo          : in std_ulogic;
	i_mfhi          : in std_ulogic;
	i_SignExtend 	: in std_ulogic;

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
        clk         : in  std_ulogic;
        reset       : in  std_ulogic;
        i_MemRead 	: in  std_ulogic;
        i_MemWrite  : in  std_ulogic;
        i_vect      : in  std_ulogic;
        i_Addresse  : in  std_ulogic_vector (31  downto 0);
        i_WriteData : in  std_ulogic_vector (127 downto 0);
        o_ReadData  : out std_ulogic_vector (127 downto 0)
    );
    end component;

	component BancRegistres is
	Port ( 
		clk       : in std_ulogic;
		reset     : in std_ulogic;
		i_RS1     : in std_ulogic_vector (4 downto 0);
		i_RS2     : in std_ulogic_vector (4 downto 0);
		i_Wr_DAT  : in std_ulogic_vector (127 downto 0);
		i_WDest   : in std_ulogic_vector (4 downto 0);
		i_WE      : in std_ulogic;
		o_RS1_DAT : out std_ulogic_vector (127 downto 0);
		o_RS2_DAT : out std_ulogic_vector (127 downto 0);
		o_DES_DAT : out std_ulogic_vector (127 downto 0)
		);
	end component;

	component alu is
	Port ( 
		i_a			: in std_ulogic_vector (31 downto 0);
		i_b			: in std_ulogic_vector (31 downto 0);
		i_alu_funct : in std_ulogic_vector (4 downto 0);
		i_shamt		: in std_ulogic_vector (4 downto 0);
		o_result	: out std_ulogic_vector (31 downto 0);
	    o_multRes   : out std_ulogic_vector (63 downto 0);
		o_zero		: out std_ulogic
		);
	end component;

	constant c_Registre31		 : std_ulogic_vector(4 downto 0) := "11111";
	signal s_zero                : std_ulogic_vector(3 downto 0);
	
    signal s_WriteRegDest_muxout   : std_ulogic_vector(4 downto 0);
	
    signal r_PC                    : std_ulogic_vector(31 downto 0);
    signal s_PC_Suivant            : std_ulogic_vector(31 downto 0);
    signal s_adresse_PC_plus_4     : std_ulogic_vector(31 downto 0);
    signal s_adresse_jump          : std_ulogic_vector(31 downto 0);
    signal s_adresse_branche       : std_ulogic_vector(31 downto 0);
    
    signal s_Instruction           : std_ulogic_vector(31 downto 0);

    signal s_opcode                : std_ulogic_vector( 5 downto 0);
    signal s_RS                    : std_ulogic_vector( 4 downto 0);
    signal s_RT                    : std_ulogic_vector( 4 downto 0);
    signal s_RD                    : std_ulogic_vector( 4 downto 0);
    signal s_shamt                 : std_ulogic_vector( 4 downto 0);
    signal s_instr_funct           : std_ulogic_vector( 5 downto 0);
    signal s_imm16                 : std_ulogic_vector(15 downto 0);
    signal s_jump_field            : std_ulogic_vector(25 downto 0);
    signal s_reg_data1             : std_ulogic_vector(127 downto 0);
    signal s_reg_data2             : std_ulogic_vector(127 downto 0);
    signal s_reg_desti             : std_ulogic_vector(127 downto 0);
    signal s_AluResult             : std_ulogic_vector(127 downto 0);
    signal s_AluResult_MOVNV       : std_ulogic_vector(127 downto 0);
    signal s_AluMultResult         : std_ulogic_vector(63 downto 0);
    
    signal s_Data2Reg_muxout       : std_ulogic_vector(127 downto 0);
    
    signal s_imm_extended          : std_ulogic_vector(31 downto 0);
    signal s_imm_extended_shifted  : std_ulogic_vector(31 downto 0);
	
    signal s_Reg_Wr_Data           : std_ulogic_vector(31 downto 0);
    signal s_MemoryReadData        : std_ulogic_vector(127 downto 0);
    signal s_AluB_data             : std_ulogic_vector(31 downto 0);
    
    -- registres sp�ciaux pour la multiplication
    signal r_HI             : std_ulogic_vector(31 downto 0);
    signal r_LO             : std_ulogic_vector(31 downto 0);
    
begin

o_PC	<= r_PC; -- permet au synth�tiseur de sortir de la logique. Sinon, il enl�ve tout...

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
-- Compteur de programme et mise � jour de valeur
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
s_PC_Suivant		<= s_adresse_jump when i_jump = '1' else
                       s_reg_data1(31 downto 0) when i_jump_register = '1' else
					   s_adresse_branche when (i_branch = '1' and s_zero(0) = '1') else
					   s_adresse_PC_plus_4;
					   

------------------------------------------------------------------------
-- M�moire d'instructions
------------------------------------------------------------------------
inst_MemInstr: MemInstructions
Port map ( 
	i_addresse => r_PC,
    o_instruction => s_Instruction
    );

-- branchement vers le d�codeur d'instructions
o_instruction <= s_Instruction;
	
------------------------------------------------------------------------
-- Banc de Registres
------------------------------------------------------------------------
-- Multiplexeur pour le registre en �criture
s_WriteRegDest_muxout <= c_Registre31 when i_jump_link = '1' else 
                         s_rt         when i_RegDst = '0' else 
						 s_rd;
       
inst_Registres: BancRegistres 
port map ( 
	clk                      => clk,
	reset                    => reset,
	i_RS1                    => s_rs,
	i_RS2                    => s_rt,
	i_Wr_DAT                 => s_Data2Reg_muxout,
	--i_Wr_DAT(127 downto 32)  => (others => '0'),
	i_WDest                  => s_WriteRegDest_muxout,
	i_WE                     => i_RegWrite,
	--o_RS1_DAT(127 downto 32) => unused_rs,
	o_RS1_DAT                => s_reg_data1,
	--o_RS2_DAT(127 downto 32) => unused_rt,
	o_RS2_DAT                => s_reg_data2,
	o_DES_DAT                => s_reg_desti
	);
	

------------------------------------------------------------------------
-- ALU (instance, extension de signe et mux d'entr�e pour les imm�diats)
------------------------------------------------------------------------
-- extension de signe
s_imm_extended <= std_ulogic_vector(resize(  signed(s_imm16),32)) when i_SignExtend = '1' else -- extension de signe � 32 bits
				  std_ulogic_vector(resize(unsigned(s_imm16),32)); 

-- Mux pour immidiats
s_AluB_data <= s_reg_data2(31 downto 0) when i_ALUSrc = '0' else s_imm_extended;

inst_Alu: alu 
port map( 
	i_a         => s_reg_data1(31 downto 0),
	i_b         => s_AluB_data,
	i_alu_funct => i_alu_funct,
	i_shamt     => s_shamt,
	o_result    => s_AluResult_MOVNV(31 downto 0),
	o_multRes   => s_AluMultResult,
	o_zero      => s_zero(0)
	);
	
inst_Alu2: alu 
port map( 
	i_a         => s_reg_data1(63 downto 32),
	i_b         => s_reg_data2(63 downto 32),
	i_alu_funct => i_alu_funct,
	i_shamt     => s_shamt,
	o_result    => s_AluResult_MOVNV(63 downto 32),
	o_multRes   => open,
	o_zero      => s_zero(1)
	);
	
inst_Alu3: alu 
port map( 
	i_a         => s_reg_data1(95 downto 64),
	i_b         => s_reg_data2(95 downto 64),
	i_alu_funct => i_alu_funct,
	i_shamt     => s_shamt,
	o_result    => s_AluResult_MOVNV(95 downto 64),
	o_multRes   => open,
	o_zero      => s_zero(2)
	);
	
inst_Alu4: alu 
port map( 
	i_a         => s_reg_data1(127 downto 96),
	i_b         => s_reg_data2(127 downto 96),
	i_alu_funct => i_alu_funct,
	i_shamt     => s_shamt,
	o_result    => s_AluResult_MOVNV(127 downto 96),
	o_multRes   => open,
	o_zero      => s_zero(3)
	);
	


------------------------------------------------------------------------
-- M�moire de donn�es
------------------------------------------------------------------------
inst_MemDonnees : MemDonnees
Port map( 
	clk 		               => clk,
	reset 		               => reset,
	i_MemRead	               => i_MemRead,
	i_MemWrite	               => i_MemWrite,
	i_vect                     => i_vect,
    i_Addresse	               => s_AluResult(31 downto 0),
	i_WriteData                => s_reg_data2,
	--i_WriteData(127 downto 32) => (others => '0'),
    o_ReadData                 => s_MemoryReadData
    --o_ReadData(127 downto 32)  => unused_mem
	);

------------------------------------------------------------------------
-- Mux s_AluResult si movnv est fait dans la distination ou non
------------------------------------------------------------------------	

process(s_AluResult_MOVNV, i_alu_funct)
begin
    if (i_alu_funct = ALU_MOVNV) then
        if(s_AluResult_MOVNV(31 downto 0)  = x"00000000"  and
                s_reg_data1 (31 downto 0) /= x"00000000") then
            s_AluResult(31 downto 0) <= s_reg_desti(31 downto 0);
        else
            s_AluResult(31 downto 0) <= s_AluResult_MOVNV(31 downto 0);
        end if;
        
        if(s_AluResult_MOVNV(63 downto 32)  = x"00000000"  and
                s_reg_data1 (63 downto 32) /= x"00000000") then
            s_AluResult(63 downto 32) <= s_reg_desti(63 downto 32);
        else
            s_AluResult(63 downto 32) <= s_AluResult_MOVNV(63 downto 32);
        end if;
        
        if(s_AluResult_MOVNV(95 downto 64)  = x"00000000"  and
                s_reg_data1 (95 downto 64) /= x"00000000") then
            s_AluResult(95 downto 64) <= s_reg_desti(95 downto 64);
        else
            s_AluResult(95 downto 64) <= s_AluResult_MOVNV(95 downto 64);
        end if;
        
        if(s_AluResult_MOVNV(127 downto 96)  = x"00000000"  and
                s_reg_data1 (127 downto 96) /= x"00000000") then
            s_AluResult(127 downto 96) <= s_reg_desti(127 downto 96);
        else
            s_AluResult(127 downto 96) <= s_AluResult_MOVNV(127 downto 96);
        end if;
    else        
        s_AluResult <= s_AluResult_MOVNV;
    end if;
end process;	


------------------------------------------------------------------------
-- Mux d'�criture vers le banc de registres
------------------------------------------------------------------------


process(s_adresse_PC_plus_4, i_jump_link, r_HI, r_LO, i_mfhi, i_mflo, s_AluResult, i_MemtoReg, s_MemoryReadData, s_opcode)
begin
    if (i_jump_link = '1') then
        s_Data2Reg_muxout(31 downto 0)   <= s_adresse_PC_plus_4;
        s_Data2Reg_muxout(127 downto 32) <= (others => '0');
        
    elsif(i_mfhi = '1') then
        s_Data2Reg_muxout(31 downto 0)   <= r_HI;
        s_Data2Reg_muxout(127 downto 32) <= (others => '0');
        
    elsif(i_mflo = '1') then
        s_Data2Reg_muxout(31 downto 0)   <= r_LO;
        s_Data2Reg_muxout(127 downto 32) <= (others => '0');
        
    elsif(s_opcode = OP_SML) then
        s_Data2Reg_muxout(127 downto 32) <= (others => '0');
        s_Data2Reg_muxout(31 downto 0) <= s_reg_data1(31 downto 0) when (
                                                      s_reg_data1(31 downto 0) < s_reg_data1(63 downto 32) and
                                                      s_reg_data1(31 downto 0) < s_reg_data1(95 downto 64) and
                                                      s_reg_data1(31 downto 0) < s_reg_data1(127 downto 96))
                                                      else
                                          s_reg_data1(63 downto 32) when (
                                                      s_reg_data1(63 downto 32) < s_reg_data1(31 downto 0)  and
                                                      s_reg_data1(63 downto 32) < s_reg_data1(95 downto 64) and
                                                      s_reg_data1(63 downto 32) < s_reg_data1(127 downto 96))
                                                      else
                                          s_reg_data1(95 downto 64) when (
                                                      s_reg_data1(95 downto 64) < s_reg_data1(31 downto 0)  and 
                                                      s_reg_data1(95 downto 64) < s_reg_data1(63 downto 32) and 
                                                      s_reg_data1(95 downto 64) < s_reg_data1(127 downto 96))
                                                      else
                                          s_reg_data1(127 downto 96) when (
                                                      s_reg_data1(127 downto 96) < s_reg_data1(31 downto 0)  and
                                                      s_reg_data1(127 downto 96) < s_reg_data1(63 downto 32) and
                                                      s_reg_data1(127 downto 96) < s_reg_data1(95 downto 64))
                                                      else s_reg_data1(31 downto 0);                                                      
                              
       
    elsif(i_MemtoReg = '0') then
        s_Data2Reg_muxout <= s_AluResult;
                                 
    else
        s_Data2Reg_muxout <= s_MemoryReadData;
    end if;
end process;


		
------------------------------------------------------------------------
-- Registres sp�ciaux pour la multiplication
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
