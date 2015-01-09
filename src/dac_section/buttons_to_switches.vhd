library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity buttons_to_switches is
		port(
					adjust: out std_logic_vector(1 downto 0);
				  rotary_pulse: in std_logic;
				  rotary_direction: in std_logic;
					buttons_in: in std_logic_vector(3 downto 0);
					current_mode: out std_logic_vector(1 downto 0);
					current_channel: out std_logic_vector(1 downto 0);
					clk: in std_logic
				);
end buttons_to_switches;

architecture behavioral of buttons_to_switches is

	signal current_mode_sig: unsigned(1 downto 0);
	signal current_channel_sig: unsigned(1 downto 0);

begin
	rotary_handle: process(clk)
	begin
		if(rising_edge(clk)) then
			adjust <= "00";
			if(rotary_pulse = '1' and rotary_direction = '1') then
				adjust <= "01";
			elsif (rotary_pulse = '1') then
				adjust <= "10";
			end if;
		end if;
	end process;

	button_handle: process(clk)
	begin
		if(rising_edge(clk)) then
			if(buttons_in = "0001") then
				current_mode_sig <= current_mode_sig + 1;
			elsif(buttons_in = "0010") then
				current_mode_sig <= current_mode_sig - 1;
			elsif(buttons_in = "0100") then
				current_channel_sig <= current_channel_sig + 1;
			elsif(buttons_in = "1000") then
				current_channel_sig <= current_channel_sig - 1;
			end if;
		end if;
	end process;

	current_channel <= std_logic_vector(current_channel_sig);
	current_mode <= std_logic_vector(current_mode_sig);

end behavioral;
