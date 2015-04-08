library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart is
	generic(
		sample_length_bits: integer range 0 to 32 := 12;
	);
	port(
		uart_tx: out std_logic;
		
		data_in: std_logic_vector(sample_length_bits - 1 downto 0);
		curr_sample_out: std_logic_vector(9 downto 0);
		request_new_sample: std_logic;

		run: in std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end uart;

-- split data into 4 nibbles + add a command in front
-- |_|_|_|_| |_|_|_|_| |_|_|_|_| |_|_|_|_| |_|_|_|_|
--
-- send data as ascii hex

architecture structural of uart is

	type uart_state is (reset,waiting,sending);
	signal curr_state: uart_state;

	signal clock_divide: integer range 0 to 5208 := 0;

begin

end structural;
