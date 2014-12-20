library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity simple_control is
	generic(
					 sine_length_bits: integer := 10;
					 num_channels: integer := 4
				 );
	port(
				-- spi control related
				spi_ready: in std_logic;
				spi_send_data: out std_logic;
				spi_channel: out std_logic_vector(1 downto 0);

				-- sine wave control related
				freq_mult: out std_logic_vector((num_channels * 10) - 1 downto 0);
				phase_adjust: out std_logic_vector((num_channels * 8) - 1 downto 0);
				amplitude_adjust: out std_logic_vector((num_channels * 6) - 1 downto 0);
				pwm_adjust: out std_logic_vector((num_channels * 10) - 1 downto 0);

				-- control related
				current_mode: in std_logic_vector (1 downto 0); -- 00 = freq, 01 = phase, 10 = amplitude
				current_channel: in std_logic_vector(1 downto 0);
				adjust: in std_logic_vector(1 downto 0); -- pulses for adjustment of values, 0 up, 1 down
				clk: in std_logic
			);
end simple_control;

architecture Behavioral of simple_control is
	signal ready: std_logic;
	signal spi_send_sig: std_logic;
	signal spi_channel_sig: std_logic_vector(1 downto 0) := "00";
	signal spi_channel_incremented: std_logic;

	type freq_array_t is array (0 to num_channels - 1) of std_logic_vector(9 downto 0);
	type phase_array_t is array (0 to num_channels - 1) of std_logic_vector(7 downto 0);
	type amplitude_array_t is array (0 to num_channels - 1) of std_logic_vector(5 downto 0);
	type pwm_array_t is array (0 to num_channels - 1) of std_logic_vector(9 downto 0);

	signal freq_array: freq_array_t;
	signal phase_array: phase_array_t;
	signal amplitude_array: amplitude_array_t;
	signal pwm_array: pwm_array_t;

begin
	spi: process(clk)
	begin
		if(rising_edge(clk)) then
			if(spi_send_sig = '1') then
				spi_send_sig <= '0';
			end if;
			if(spi_ready = '1') then
				if(ready = '1') then
					if(spi_channel_incremented = '0') then
						spi_channel_incremented <= '1';
						spi_channel_sig <= std_logic_vector(unsigned(spi_channel_sig) + 1);
					end if;
					spi_send_sig <= '1';
					ready <= '0';
				else
					ready <= '1';
				end if;
			else
				spi_channel_incremented <= '0';
			end if;
		end if;
	end process;

	spi_channel <= spi_channel_sig;
	spi_send_data <= spi_send_sig;

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
							phase_array(I) <= std_logic_vector(unsigned(phase_array(I)) + 1);
						elsif(adjust(1) = '1') then
							phase_array(I) <= std_logic_vector(unsigned(phase_array(I)) - 1);
						end if;
					elsif(current_mode= "10") then -- amplitude adjust
						if(adjust(0) = '1') then
							amplitude_array(I) <= std_logic_vector(unsigned(amplitude_array(I)) + 1);
						elsif(adjust(1) = '1') then
							amplitude_array(I) <= std_logic_vector(unsigned(amplitude_array(I)) - 1);
						end if;
					elsif(current_mode= "11") then -- pwm adjust (for square wave)
						if(adjust(0) = '1') then
							pwm_array(I) <= std_logic_vector(unsigned(pwm_array(I)) + 1);
						elsif(adjust(1) = '1') then
							pwm_array(I) <= std_logic_vector(unsigned(pwm_array(I)) - 1);
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
				phase_adjust((8 + (I * 8)) - 1 downto (I * 8)) <= phase_array(I);
				amplitude_adjust((6 + (I * 6)) - 1 downto (I * 6)) <= amplitude_array(I);
				pwm_adjust((10 + (I * 10)) - 1 downto (I * 10)) <= pwm_array(I);
			end loop;
		end if;
	end process;


end Behavioral;

