
library IEEE; 
use IEEE.STD_LOGIC_1164.all;

entity maindec is -- main control decoder
  port(op:                 in  STD_LOGIC_VECTOR(5 downto 0);
       memtoreg, memwrite: out STD_LOGIC;
       branch, alusrc:     out STD_LOGIC;
       regdst, regwrite:   out STD_LOGIC;
       jump:               out STD_LOGIC;
       aluop:              out  STD_LOGIC_VECTOR(2 downto 0));
end;

architecture behave of maindec is
  signal controls: STD_LOGIC_VECTOR(9 downto 0);
begin
  process(op) begin
    case op is
      when "000000" => controls <= "1100000100"; -- Rtype
      when "100011" => controls <= "1010010000"; -- LW
      when "101011" => controls <= "0X101X0001"; -- SW
      when "000100" => controls <= "0X010X0010"; -- BEQ
      when "001000" => controls <= "1010000101"; -- ADDI
      when "000010" => controls <= "0XXX0X1111"; -- J
      when "001110" => controls <= "1010000110"; -- XORI
      when "000111" => controls <= "0XXX110011"; -- BGTZ
      -- when "001101" => controls <= "1010000100"; -- ORI
      when others   => controls <= "----------"; -- illegal op
    end case;
  end process;

  regwrite <= controls(9);
  regdst   <= controls(8);
  alusrc   <= controls(7);
  branch   <= controls(6);
  memwrite <= controls(5);
  memtoreg <= controls(4);
  jump     <= controls(3);
  aluop    <= controls(2 downto 0);
end;


