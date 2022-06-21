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

package MIPS32_package is
    -- codes d'opération internes de l'ALU
    -- Nous définissons ces codes et on aurait pu adopter un autre encodage
    constant ALU_AND  :  std_ulogic_vector( 3 downto 0 ) := "0000";
    constant ALU_OR   :  std_ulogic_vector( 3 downto 0 ) := "0001";
    constant ALU_ADD  :  std_ulogic_vector( 3 downto 0 ) := "0010";
    constant ALU_SLTU :  std_ulogic_vector( 3 downto 0 ) := "0011";
    constant ALU_SUB  :  std_ulogic_vector( 3 downto 0 ) := "0110";
    constant ALU_SLT  :  std_ulogic_vector( 3 downto 0 ) := "0111";
    
    constant ALU_XOR   : std_ulogic_vector( 3 downto 0 ) := "1000";
    constant ALU_NOR   : std_ulogic_vector( 3 downto 0 ) := "1001";
    constant ALU_SLL   : std_ulogic_vector( 3 downto 0 ) := "1010";
    constant ALU_SRL   : std_ulogic_vector( 3 downto 0 ) := "1011";
    constant ALU_SRA   : std_ulogic_vector( 3 downto 0 ) := "1100";
    constant ALU_MULTU: std_ulogic_vector( 3 downto 0 ) := "1101";
    constant ALU_SLL16: std_ulogic_vector( 3 downto 0 ) := "1110";
    constant ALU_NULL  : std_ulogic_vector( 3 downto 0 ) := "1111";
    
    -- codes du champ function des instructions de type R
    -- Ces codes sont définis par l'encodage des instructions MIPS
    -- voir entre autres p. 301 COD édition 5
    constant ALUF_SLL : std_ulogic_vector( 5 downto 0 ) := "000000";
    constant ALUF_SRL : std_ulogic_vector( 5 downto 0 ) := "000010";
    constant ALUF_SRA : std_ulogic_vector( 5 downto 0 ) := "000110";
    constant ALUF_ADD  : std_ulogic_vector( 5 downto 0 ) := "100000";
    constant ALUF_ADDU: std_ulogic_vector( 5 downto 0 ) := "100001";
    constant ALUF_SUB  : std_ulogic_vector( 5 downto 0 ) := "100010";
    constant ALUF_AND  : std_ulogic_vector( 5 downto 0 ) := "100100";
    constant ALUF_OR  : std_ulogic_vector( 5 downto 0 ) := "100101";
    constant ALUF_XOR  : std_ulogic_vector( 5 downto 0 ) := "100110";
    constant ALUF_NOR  : std_ulogic_vector( 5 downto 0 ) := "100111";
    constant ALUF_SLT : std_ulogic_vector( 5 downto 0 ) := "101010";
    constant ALUF_SLTU: std_ulogic_vector( 5 downto 0 ) := "101011";
    constant ALUF_SYSCALL	: std_ulogic_vector( 5 downto 0 ) := "001100";
    
    -- opcodes dans le décodage d'instructions
    -- codes disponible dans COD ou dans les cartes de résumé
    constant OP_Rtype:      std_ulogic_vector( 5 downto 0 ) := "000000";
    --constant OP_ADDI:        std_ulogic_vector( 5 downto 0 ) := ""; -- à compléter pour ADDI
    --constant OP_ORI :        std_ulogic_vector( 5 downto 0 ) := ""; -- à compléter pour ORI
    --constant OP_immarith:   std_ulogic_vector( 5 downto 0 ) := "001---";
    
    type RAM is array (natural range <>) of std_ulogic_vector (31 downto 0);
						
	
    type op_type is (
		sim_OP_NOP,
        sim_OP_AND,
        sim_OP_OR,
		sim_OP_NOR,
        sim_OP_ADD,
		sim_OP_ADDU,
        sim_OP_SUB,
        sim_OP_SLL,
        sim_OP_SRL,
        sim_OP_SLT,
        sim_OP_SLTU,
        sim_OP_ADDI,
		sim_OP_SYSCALL,
        sim_OP_not_in_sim_list
    );
    function f_DisplayOp(InstructionDebug : std_ulogic_vector( 31 downto 0 )
                        ) return op_type;
						
						
	type alu_action_types is (
        sim_alu_AND,
        sim_alu_OR,
        sim_alu_NOR,
        sim_alu_ADD,
        sim_alu_SUB,
        sim_alu_SLL,
        sim_alu_SRL,
        sim_alu_SLL16,
        sim_alu_SLT,
        sim_alu_SLTU,
        sim_alu_not_in_sim_list
    );
	function f_DisplayAluAction(alu_funct : std_ulogic_vector( 3 downto 0 )
                        ) return alu_action_types;			


end package MIPS32_package;

package body MIPS32_package is
	

function f_DisplayOp(InstructionDebug : std_ulogic_vector( 31 downto 0 )
                        ) return op_type is 
	variable CurrentOp : op_type;
	variable OperatorField  : std_ulogic_vector( 5 downto 0 );
	variable FunctField  : std_ulogic_vector( 5 downto 0 );
	variable NopField  : std_ulogic;
	
begin
	
	OperatorField	:= InstructionDebug(31 downto 26);
	FunctField := InstructionDebug(5 downto 0);
	

	
	case OperatorField is
        when OP_Rtype =>
			case FunctField is 
				when ALUF_AND =>
					CurrentOp := sim_OP_AND;
				when ALUF_OR =>
					CurrentOp := sim_OP_OR;
				when ALUF_NOR =>
					CurrentOp := sim_OP_NOR;
				when ALUF_ADD =>
					CurrentOp := sim_OP_ADD;
				when ALUF_ADDU =>
					CurrentOp := sim_OP_ADDU;
				when ALUF_SUB =>
					CurrentOp := sim_OP_SUB;
				when ALUF_SLL =>
					CurrentOp := sim_OP_SLL;
				when ALUF_SRL =>
					CurrentOp := sim_OP_SRL;
				when ALUF_SLT =>
					CurrentOp := sim_OP_SLT;
				when ALUF_SLTU =>
					CurrentOp := sim_OP_SLTU;
				when ALUF_SYSCALL =>
					CurrentOp := sim_OP_SYSCALL;
				when others =>
					CurrentOp := sim_OP_not_in_sim_list;
			end case;
        --when OP_ADDI =>
		--	CurrentOp := sim_OP_ADDI;
		when others =>
			CurrentOp := sim_OP_not_in_sim_list;
	end case;
	
	return CurrentOp;
end function;


function f_DisplayAluAction(alu_funct : std_ulogic_vector( 3 downto 0 )
                        ) return alu_action_types is 
	variable CurrentAction : alu_action_types;	
begin

        
	case alu_funct is
		when ALU_AND =>
			CurrentAction := sim_alu_AND;
		when ALU_OR =>
			CurrentAction := sim_alu_OR;
		when ALU_NOR =>
			CurrentAction := sim_alu_NOR;
		when ALU_ADD =>
			CurrentAction := sim_alu_ADD;
		when ALU_SUB =>
			CurrentAction := sim_alu_SUB;
		when ALU_SLL =>
			CurrentAction := sim_alu_SLL;
		when ALU_SRL =>
			CurrentAction := sim_alu_SRL;
		when ALU_SLL16 =>
			CurrentAction := sim_alu_SLL16;
		when ALU_SLT =>
			CurrentAction := sim_alu_SLT;
		when ALU_SLTU =>
			CurrentAction := sim_alu_SLTU;
		when others =>
			CurrentAction := sim_alu_not_in_sim_list;
	end case;
	
	return CurrentAction;
end function;

end package body MIPS32_package;