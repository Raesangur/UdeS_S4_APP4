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

library std;
use std.env.stop;

entity monitor_pipeline is
end monitor_pipeline;

architecture Behavioral of monitor_pipeline is

	signal show_IF_Instruction		: op_type;
	signal show_ID_Instruction		: op_type;
	signal show_EX_Instruction		: op_type;
	signal show_MEM_Instruction		: op_type;
	signal show_WB_Instruction		: op_type;
    
	signal show_EX_alu_action		: alu_action_types;
	signal show_EX_alu_unsupported	: std_ulogic;
	
	signal flag_branch				: std_ulogic;
	signal flag_jump				: std_ulogic;
	signal flag_flush				: std_ulogic;
	signal flag_bubble				: std_ulogic;
	signal flag_syscall				: std_ulogic;
	signal end_program				: std_ulogic;
	
	
begin

	show_EX_alu_unsupported	<= <<signal .mips_pipeline_tb.dut.inst_Datapath.inst_alu.d_unsupported : std_ulogic>>;
	show_EX_alu_action 		<= f_DisplayAluAction(<<signal .mips_pipeline_tb.dut.inst_Datapath.inst_alu.i_alu_funct : std_ulogic_vector>>);


IF_EncapsulerExtraction: block
	signal s_Instruction		: std_ulogic_vector (31 downto 0);
begin
	s_Instruction		<= <<signal .mips_pipeline_tb.dut.inst_Datapath.s_Instruction : std_ulogic_vector>>;
	show_IF_Instruction	<= f_DisplayOp(s_Instruction);
end block;

ID_EncapsulerExtraction: block
	signal s_Instruction		: std_ulogic_vector (31 downto 0);
begin
	s_Instruction		<= <<signal .mips_pipeline_tb.dut.inst_Datapath.r_IF_ID_Instruction : std_ulogic_vector>>;
	show_ID_Instruction	<= f_DisplayOp(s_Instruction);
end block;


EXMEMWB_EncapsulerExtraction: block
-- présume une insertion correctement faite  dans le VHDL. 
	signal clk					: std_ulogic;
	signal s_bubble				: std_ulogic;
    signal regs                     : RAM(0 to 31);
    
    constant c_Registre_V0  : integer := 2;
    constant c_EndProgramCode : integer := 10;
begin
	
	clk			<= <<signal .mips_pipeline_tb.dut.inst_Datapath.clk : std_ulogic>>;
	s_bubble	<= <<signal .mips_pipeline_tb.dut.inst_Datapath.s_InsertBubble : std_ulogic>>;
    regs        <= <<signal .mips_pipeline_tb.dut.inst_Datapath.inst_Registres.regs : RAM>>;
    end_program  <= '1' when flag_syscall = '1' and unsigned(regs(c_Registre_V0)) = c_EndProgramCode else '0';
    
    
	process(clk)
	begin
		if(clk'event and clk = '1') then
            -- Requis pour l'affichage des bulles, car registre IF/ID conserve l'instruction originale pendant l'insertion.
            -- c_Mips32_Flush écrase plutôt l'ancienne instruction dans IF/ID, et donc visible par les lignes ci-bas.
			if(s_bubble = '1') then
				show_EX_Instruction		<= sim_OP_BULLE;
			else
				show_EX_Instruction		<= show_ID_Instruction;
			end if;
			show_MEM_Instruction	<= show_EX_Instruction;
			show_WB_Instruction		<= show_MEM_Instruction;
		end if;
	end process;
end block;

-- signaux d'aide à la visualisation
flag_syscall <= '1' when show_WB_Instruction = sim_OP_SYSCALL else '0'; -- fin du programme l'étage WB, donc après 4 flush
flag_branch  <= '1' when show_ID_Instruction = sim_OP_BEQ     else '0';
flag_jump    <= '1' when show_ID_Instruction = sim_OP_J       else '0';
flag_flush	 <= '1' when show_ID_Instruction = sim_OP_FLUSH   else '0';
flag_bubble	 <= '1' when show_EX_Instruction = sim_OP_BULLE   else '0';




process
begin
    wait until end_program'event;
    if(end_program = '1') then
        wait for 20 ns;
        stop;
    end if;
end process;


end Behavioral;


