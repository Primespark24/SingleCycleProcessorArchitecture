library IEEE;
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;

entity display_hex is
	port (
		CLKM : in STD_LOGIC;
		x : in STD_LOGIC_VECTOR(15 downto 0);
		seg : out STD_LOGIC_VECTOR(6 downto 0);
		an : out STD_LOGIC_VECTOR(3 downto 0);
		dp : out STD_LOGIC;
		LED : out  STD_LOGIC_VECTOR(3 downto 0);
        clk_div: out STD_LOGIC_VECTOR(28 downto 0)		
	 );
end	 display_hex;

architecture display_hex of display_hex is


	signal s: STD_LOGIC_VECTOR(3 downto 0);
	signal digit: STD_LOGIC_VECTOR(3 downto 0);
	signal clkdiv: STD_LOGIC_VECTOR(28 downto 0);	
	signal clk : STD_LOGIC;

begin

    clk <= CLKM; 
    clk_div <= clkdiv;           -- output the clkdiv counter
    s <= clkdiv(18 downto 15);	 -- cycle through 7-seg displays
    		
	dp <= '1';			   -- turn off dp
	LED <= digit;		   -- see the code
	
	-- Quad 8-to-1 MUX to select binary code to display
	process(s)
	begin
		case s is
			when "0000" => digit <= x(3 downto 0);
			when "0001" => digit <= x(7 downto 4);
			when "0010" => digit <= x(11 downto 8);
			when others => digit <= x(15 downto 12);					
		end case;
	end process;
	
	-- Select a 7-seg display based on s
	process(s)
		variable aen : std_logic_vector(3 downto 0) := "1111";
	begin
		aen := "1111";
		aen(conv_integer(s)) := '0'; 
		an <= aen;
	end process;
	
    -- Clock divider
    process(clk)
    begin
        if rising_edge(clk) then
            clkdiv <= clkdiv +1;
        end if;
    end process;

	-- Mux to select cathode signals (activates led segments)
	process(digit)
	begin
	   case digit is
		   when X"0" => seg <=  "1000000";	 --0
		   when X"1" => seg <=  "1111001";	 --1
		   when X"2" => seg <=  "0100100";	 --2
		   when X"3" => seg <=  "0110000";	 --3
		   when X"4" => seg <=  "0011001";	 --4
		   when X"5" => seg <=  "0010010";	 --5
		   when X"6" => seg <=  "0000010";	 --6
		   when X"7" => seg <=  "1011000";	 --7
		   when X"8" => seg <=  "0000000";	 --8
		   when X"9" => seg <=  "0010000";	 --9
		   when X"A" => seg <=  "0001000";	 --A
		   when X"B" => seg <=  "0000011";	 --b
		   when X"C" => seg <=  "1000110";	 --C
		   when X"D" => seg <=  "0100001";	 --d
		   when X"E" => seg <=  "0000110";	 --E
		   when others => seg <=  "0001110";	 --F
	   end case;
	end process;

	
end display_hex;