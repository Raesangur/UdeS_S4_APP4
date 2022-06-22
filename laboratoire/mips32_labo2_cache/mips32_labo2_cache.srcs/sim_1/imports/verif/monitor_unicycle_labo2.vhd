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

library std;
use std.env.stop;


entity monitor_unicycle is
end monitor_unicycle;

architecture Behavioral of monitor_unicycle is


	signal show_alu_action			: alu_action_types;
	signal show_SeenInstruction		: op_type;
	signal show_EffectiveInstruction		: op_type;
	signal show_alu_unsupported	: std_ulogic;
	signal flag_syscall				: std_ulogic;
	signal end_program				: std_ulogic;
    signal s_InstructionStall       : std_ulogic;
    signal s_DataStall              : std_ulogic;
	signal s_Instruction		: std_ulogic_vector (31 downto 0);


begin

	show_alu_unsupported	<= <<signal .mips_unicycle_tb.dut.inst_Datapath.inst_alu.s_unsupported : std_ulogic>>;
	show_alu_action 		<= f_DisplayAluAction(<<signal .mips_unicycle_tb.dut.inst_Datapath.inst_alu.i_alu_funct : std_ulogic_vector>>);
    s_InstructionStall      <= <<signal .mips_unicycle_tb.dut.inst_Controleur.i_InstrStall : std_ulogic>>;
    s_DataStall             <= <<signal .mips_unicycle_tb.dut.inst_Datapath.s_DataStall : std_ulogic>>;
	s_Instruction		<= <<signal .mips_unicycle_tb.dut.inst_Datapath.s_Instruction : std_ulogic_vector>>;


EncapsulerExtraction: block
    constant c_Registre_V0  : integer := 2;
    constant c_EndProgramCode : integer := 10;
    signal regs                     : RAM(0 to 31);
begin
	regs                    <= <<signal .mips_unicycle_tb.dut.inst_Datapath.inst_Registres.regs : RAM>>;

	show_SeenInstruction	<= f_DisplayOp(s_Instruction);

	show_EffectiveInstruction <= f_DisplayOp(s_Instruction) when s_InstructionStall = '0' else sim_OP_STALL ; 
    flag_syscall <= '1' when show_EffectiveInstruction = sim_OP_SYSCALL else '0';
    end_program  <= '1' when flag_syscall = '1' and unsigned(regs(c_Registre_V0)) = c_EndProgramCode else '0';
end block;
	

process
begin
    wait until end_program'event;
    if(end_program = '1') then
        wait for 20 ns;
        stop;
    end if;
end process;


-- Cas d'exception. 
-- Plus simple de refuser ce cas de figure. L'impl�mentation telle que fournie exige 
-- une modification subtile de l'�criture 
-- au banc de registres, ce qui n'est pas l'apprentissage vis� ici.
-- L'approche intuitive et similaire au stall d'instruction cause en fait ici
-- un cas de boucle infinie sur les process, tr�s difficile � rep�rer. 
-- Le code ci-bas avec son message est bien plus informatif dans le cas improbable 
-- que la situation arrive.
process(show_SeenInstruction, s_DataStall)
    alias s_RegT : std_ulogic_vector(4 downto 0) is  s_Instruction(20 downto 16);
    alias s_RegS : std_ulogic_vector(4 downto 0) is  s_Instruction(25 downto 21);
begin
    if(show_SeenInstruction = sim_OP_LW and s_DataStall = '1') then
        assert s_RegS /= s_RegT report "lw avec RegT == RegS non support� pour le code du laboratoire 2 sur les caches. Svp modifier votre assembleur" severity failure; 
    end if;
end process;

end Behavioral;


