library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rotary_control is
	port(
				rotary_a: in std_logic;
				rotary_b: in std_logic;
				out_pulse: out std_logic;
				direction: out std_logic;
				clk: in std_logic
			);
end rotary_control;

architecture Behavioral of rotary_control is

	type rotary_state is (ablow,abhigh,left,right);
	signal state: rotary_state;

	signal rotary_input: std_logic_vector(1 downto 0);

	signal direction_sig: std_logic;

begin
	process(clk)
	begin
	if(rising_edge(clk)) then
		out_pulse <= '0';
		direction_sig <= direction_sig;
		case state is
			when ablow =>
				if(rotary_input = "10") then
					state <= left;
				elsif(rotary_input = "01") then
					state <= right; -- maybe left, untested
				else
					state <= ablow;
				end if;
			when abhigh =>
				if(rotary_input = "00") then
					state <= ablow;
				else
					state <= abhigh;
				end if;
			when left =>
				if(rotary_input = "11") then
					out_pulse <= '1';
					direction_sig <= '0';
					state <= abhigh;
				elsif(rotary_input = "00") then
					state <= ablow;
				else
					state <= left;
				end if;
			when right =>
				if(rotary_input = "11") then
					out_pulse <= '1';
					direction_sig <= '1';
					state <= abhigh;
				elsif(rotary_input = "00") then
					state <= ablow;
				else
					state <= right;
				end if;
			when others => -- hopefully never happens
				state <= ablow;
				out_pulse <= '0';
				direction_sig <= direction_sig;
		end case;
	end if;
	end process;

	rotary_input <= rotary_a & rotary_b;

	direction <= direction_sig;

end Behavioral;
