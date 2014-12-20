library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ramp_gen is
	generic(
		ramp_length_bits: integer := 10
	);
	port(
		x_in: in std_logic_vector(ramp_length_bits - 1 downto 0);
		ramp_out: out std_logic_vector(11 downto 0) -- 12 bit output for DAC
	);
end ramp_gen;

architecture Behavioral of ramp_gen is

begin
	ramp_out <= x_in & "00";


end Behavioral;

