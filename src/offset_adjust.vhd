library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity offset_adjust is
	port(
		ramp_in: in std_logic_vector(11 downto 0);
		ramp_out: out std_logic_vector(11 downto 0);
		adjust: in std_logic_vector(5 downto 0)
	);
end offset_adjust;

architecture Behavioral of offset_adjust is

begin
	ramp_out <= std_logic_vector(unsigned(ramp_out) + unsigned(adjust))

end Behavioral;

