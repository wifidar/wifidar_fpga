library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL;

entity amplitude_adjust is
	port(
		sine_in: in std_logic_vector(11 downto 0);
		sine_out: out std_logic_vector(11 downto 0);
		adjust: in std_logic_vector(5 downto 0);
		clk: in std_logic
	);
end amplitude_adjust;

architecture Behavioral of amplitude_adjust is

	signal one_shift: unsigned(10 downto 0);
	signal two_shift: unsigned(9 downto 0);
	signal three_shift: unsigned(8 downto 0);
	signal four_shift: unsigned(7 downto 0);
	signal five_shift: unsigned(6 downto 0);
	signal six_shift: unsigned(6 downto 0);
	
	signal one_shift_temp: unsigned(11 downto 0);
	signal two_shift_temp: unsigned(11 downto 0);
	signal three_shift_temp: unsigned(11 downto 0);
	signal four_shift_temp: unsigned(11 downto 0);
	signal five_shift_temp: unsigned(11 downto 0);
	signal six_shift_temp: unsigned(11 downto 0);
	
begin

	-- Placed into a process to improve timing
	process(clk)
	begin
		if(rising_edge(clk)) then
			if adjust(5) = '1' then
				one_shift <= (unsigned(sine_in) srl 1);
			else 
				one_shift <= (others => '0');
			end if;
			if adjust(4) = '1' then
				two_shift <= unsigned(sine_in) srl 2;
			else 
				two_shift <= (others => '0');
			end if;
			if adjust(3) = '1' then
				three_shift <= unsigned(sine_in) srl 3;
			else 
				three_shift <= (others => '0');
			end if;
			if adjust(2) = '1' then
				four_shift <= unsigned(sine_in) srl 4;
			else 
				four_shift <= (others => '0');
			end if;
			if adjust(1) = '1' then
				five_shift <= unsigned(sine_in) srl 5;
			else 
				five_shift <= (others => '0');
			end if;
			if adjust(0) = '1' then
				six_shift <= unsigned(sine_in) srl 5;
			else 
				six_shift <= (others => '0');
			end if;
--			
--				four_shift <= unsigned(sine_in) srl 4 if adjust(2) = '1' else (others => '0');
--				five_shift <= unsigned(sine_in) srl 5 if adjust(1) = '1' else (others => '0');
--				six_shift <= unsigned(sine_in) srl 5 if adjust(0) = '1' else (others => '0');
			
			if(adjust = "111111") then
				sine_out <= sine_in;
			else
				sine_out <= std_logic_vector(one_shift_temp + two_shift_temp + three_shift_temp + four_shift_temp + five_shift_temp + six_shift_temp);
			end if;
						
		end if;
	end process;
	
	one_shift_temp <= '0' & one_shift;
	two_shift_temp <= "00" & two_shift;
	three_shift_temp <= "000" & three_shift;
	four_shift_temp <= "0000" & four_shift;
	five_shift_temp <= "00000" & five_shift;
	six_shift_temp <= "00000" & six_shift;
	
end Behavioral;

