----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:36:59 04/04/2014 
-- Design Name: 
-- Module Name:    phase_acc - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity phase_acc is
	generic(
		sine_length_bits: integer := 10
	);
	port(
		x_out: out std_logic_vector(sine_length_bits - 1 downto 0);
		freq_mult: in std_logic_vector(9 downto 0);
		phase_in: in std_logic_vector(7 downto 0);
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
		end if;
	end process;
	
	x_out <= std_logic_vector(big_ol_counter(20 downto 11) + unsigned(phase_in & "00"));

end Behavioral;

