---------------------------------------------------------------------------------------------
--
--	Universit� de Sherbrooke 
--  D�partement de g�nie �lectrique et g�nie informatique
--
--	S4i - APP4 
--	
--
--	Auteur: 		Marc-Andr� T�trault
--					Daniel Dalle
--					S�bastien Roy
-- 
---------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS32_package.all;

entity BancRegistres is
    Port ( clk       : in  std_ulogic;
           reset     : in  std_ulogic;
           i_RS1     : in  std_ulogic_vector (4 downto 0);
           i_RS2     : in  std_ulogic_vector (4 downto 0);
           i_Wr_DAT  : in  std_ulogic_vector (127 downto 0);
           i_WDest   : in  std_ulogic_vector (4 downto 0);
           i_WE 	 : in  std_ulogic;
           o_RS1_DAT : out std_ulogic_vector (127 downto 0);
           o_RS2_DAT : out std_ulogic_vector (127 downto 0));
end BancRegistres;


architecture comport of BancRegistres is
    signal regs : RAM(0 to 23)   := (21 => X"100103FC", -- registre $SP
                                     others => (others => '0'));
    signal regsv: RAM128(0 to 7) := (others => (others => '0'));

    signal int_i_RS1 : integer range 0 to 31 := 0;
    signal int_i_RS2 : integer range 0 to 31 := 0;
    signal int_i_WD  : integer range 0 to 31 := 0;
begin

    int_i_RS1 <= to_integer(unsigned(i_RS1));
    int_i_RS2 <= to_integer(unsigned(i_RS2));
    int_i_WD  <= to_integer(unsigned(i_WDest));

    process(clk)
    begin
        if clk='1' and clk'event then
            if i_WE = '1' and reset = '0' and i_WDest /= "00000" then
                 if (int_i_WD < 16) then
                    regs(int_i_WD)       <= i_Wr_DAT(31 downto 0);
                elsif (int_i_WD > 23) then
                    regs(int_i_WD - 8)   <= i_Wr_DAT(31 downto 0);
                else
                    regsv(int_i_WD - 16) <= i_Wr_DAT;
                end if;                
                -- regs( to_integer( unsigned(i_WDest))) <= i_Wr_DAT;
            end if;
        end if;
    end process;

    process(i_RS1)
    begin
        if (int_i_RS1 < 16) then
            o_RS1_DAT(31 downto 0)   <= regs(int_i_RS1);
            o_RS1_DAT(127 downto 32) <= (others => '0');
        elsif (int_i_RS1 > 23) then
            o_RS1_DAT(31 downto 0)   <= regs(int_i_RS1 - 8);
            o_RS1_DAT(127 downto 32) <= (others => '0');
        else
            o_RS1_DAT <= regsv(int_i_RS1 - 16);
        end if;
    end process;

    process(i_RS2)
    begin
        if (int_i_RS2 < 16) then
            o_RS2_DAT(31 downto 0)   <= regs(int_i_RS2);
            o_RS2_DAT(127 downto 32) <= (others => '0');
        elsif (int_i_RS2 > 23) then
            o_RS2_DAT(31 downto 0)   <= regs(int_i_RS2 - 8);
            o_RS2_DAT(127 downto 32) <= (others => '0');
        else
            o_RS2_DAT <= regsv(int_i_RS2 - 16);
        end if;
    end process;
    
    -- o_RS1_DAT <= regs( to_integer(unsigned(i_RS1)));
    -- o_RS2_DAT <= regs( to_integer(unsigned(i_RS2)));
    
end comport;

