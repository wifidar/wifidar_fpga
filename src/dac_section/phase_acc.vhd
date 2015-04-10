library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity phase_acc is
	generic(
		sine_length_bits: integer := 10
	);
	port(
		x_out: out std_logic_vector(sine_length_bits - 1 downto 0);
		freq_mult: in std_logic_vector(9 downto 0);
		phase_in: in std_logic_vector(7 downto 0);
		new_signal: out std_logic;
		clk: in std_logic
	);
end phase_acc;

architecture Behavioral of phase_acc is

	signal big_ol_counter: unsigned(20 downto 0) := (others => '0');

begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			big_ol_counter <= big_ol_counter + unsigned(freq_mult);
			if(big_ol_counter = to_unsigned(0,21)) then
				new_signal <= '1';
			else
				new_signal <= '0';
			end if;
		end if;
	end process;
	
	x_out <= std_logic_vector(big_ol_counter(20 downto 11) + unsigned(phase_in & "00"));

end Behavioral;

