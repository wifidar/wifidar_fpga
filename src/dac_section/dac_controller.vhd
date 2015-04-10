library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dac_controller is
	generic(
					 sine_length_bits: integer := 10;
					 num_channels: integer := 1
		);
	port(
				-- sine wave control related
				freq_mult: out std_logic_vector((num_channels * 10) - 1 downto 0) := (others => '0');
				offset_adjust: out std_logic_vector((num_channels * 12) - 1 downto 0);
				amplitude_adjust: out std_logic_vector((num_channels * 6) - 1 downto 0);

				-- control related
				current_mode: in std_logic_vector (1 downto 0); -- 00 = freq, 01 = phase, 10 = amplitude
				current_channel: in std_logic_vector(1 downto 0);
				adjust: in std_logic_vector(1 downto 0); -- pulses for adjustment of values, 0 up, 1 down
				clk: in std_logic
		);
end dac_controller;

architecture Behavioral of dac_controller is
	type freq_array_t is array (0 to num_channels - 1) of std_logic_vector(9 downto 0);
	type offset_array_t is array (0 to num_channels - 1) of std_logic_vector(11 downto 0);
	type amplitude_array_t is array (0 to num_channels - 1) of std_logic_vector(5 downto 0);

	signal freq_array: freq_array_t := (others => ("0000000100")); -- :- 4
	signal offset_array: offset_array_t := (others => ("101001111000"));
	signal amplitude_array: amplitude_array_t := (others => ("010000")); -- := 16

begin
	mode_handle: process(clk)
	begin
		if(rising_edge(clk)) then
			for I in 0 to num_channels - 1 loop
				if(I = to_integer(unsigned(current_channel))) then
					if(current_mode = "00") then -- freq adjust
						if(adjust(0) = '1') then
							freq_array(I) <= std_logic_vector(unsigned(freq_array(I)) + 1);
						elsif(adjust(1) = '1') then
							freq_array(I) <= std_logic_vector(unsigned(freq_array(I)) - 1);
						end if;
					elsif(current_mode = "01") then -- phase adjust
						if(adjust(0) = '1') then
							offset_array(I) <= std_logic_vector(unsigned(offset_array(I)) + 10);
						elsif(adjust(1) = '1') then
							offset_array(I) <= std_logic_vector(unsigned(offset_array(I)) - 10);
						end if;
					elsif(current_mode= "10") then -- amplitude adjust
						if(adjust(0) = '1') then
							amplitude_array(I) <= std_logic_vector(unsigned(amplitude_array(I)) + 1);
						elsif(adjust(1) = '1') then
							amplitude_array(I) <= std_logic_vector(unsigned(amplitude_array(I)) - 1);
						end if;
					end if;
				end if;
			end loop;
		end if;
	end process;

	process(clk)
	begin
		if(rising_edge(clk)) then
			for I in 0 to num_channels - 1 loop
				freq_mult((10 + (I * 10)) - 1 downto (I * 10)) <= freq_array(I);
				offset_adjust((12 + (I * 8)) - 1 downto (I * 8)) <= offset_array(I);
				amplitude_adjust((6 + (I * 6)) - 1 downto (I * 6)) <= amplitude_array(I);
			end loop;
		end if;
	end process;
end Behavioral;

