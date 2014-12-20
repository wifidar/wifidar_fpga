library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity buttonStructural is

	port(
				rot_a: in std_logic;
				rot_b: in std_logic;
				button_in: in std_logic_vector(3 downto 0);
				current_mode: out std_logic_vector(1 downto 0);
				current_channel: out std_logic_vector(1 downto 0);
				adjust: out std_logic_vector(1 downto 0);
				clk: in std_logic
			);

end buttonStructural;

architecture Structural of buttonStructural is

	component rotary_control
		port(
					rotary_a: in std_logic;
					rotary_b: in std_logic;
					out_pulse: out std_logic;
					direction: out std_logic;
					clk: in std_logic
				);
	end component;

	component pulse_sync
		port(
					A: in std_logic;
					output: out std_logic;
					clk: in std_logic
				);
	end component;

	component buttons_to_switches
		port(
					adjust: out std_logic_vector(1 downto 0);
				  rotary_pulse: in std_logic;
				  rotary_direction: in std_logic;
					buttons_in: in std_logic_vector(3 downto 0);
					current_mode: out std_logic_vector(1 downto 0);
					current_channel: out std_logic_vector(1 downto 0);
					clk: in std_logic
				);
	end component;

	signal button_out: std_logic_vector(3 downto 0);
	signal pulse: std_logic;
	signal direction: std_logic;

begin

	button_mapper: buttons_to_switches port map (adjust,pulse,direction,button_out,current_mode,current_channel,clk);
	rotary: rotary_control port map (rot_a,rot_b,pulse,direction,clk);
	buttonw: pulse_sync port map (button_in(3),button_out(3),clk);
	buttonn: pulse_sync port map (button_in(1),button_out(1),clk);
	buttone: pulse_sync port map (button_in(2),button_out(2),clk);
	buttons: pulse_sync port map (button_in(0),button_out(0),clk);
end Structural;
